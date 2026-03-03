# EKS — Elastic Kubernetes Service

> Managed Kubernetes on AWS. AWS runs the control plane; you run your workloads. The industry standard for container orchestration at scale.

---

## Real-World Analogy

EKS is like **renting a professionally managed shipping port**:
- **Control Plane (AWS manages)** = Port management office, dispatch center, record keeping
- **Worker Nodes (you manage)** = The actual docks, cranes, and workers
- **Pods** = Individual shipping containers being processed
- **Deployments** = "We need 5 copies of this container running at all times"
- **Services** = The port's customer window — one address that routes to any available container
- **Ingress** = Main gate with a directory sign: `/api` → Dock A, `/web` → Dock B
- **HPA** = "If workload > 80%, hire more workers automatically"

---

## EKS Architecture

```
┌──────── AWS Managed (Control Plane) ──────────────────┐
│                                                        │
│  ┌───────────┐  ┌───────────┐  ┌────────────────┐    │
│  │ API Server│  │ Scheduler │  │ Controller Mgr │    │
│  └─────┬─────┘  └─────┬─────┘  └────────────────┘    │
│        │               │                               │
│  ┌─────┴───────────────┴──────────────────────────┐   │
│  │               etcd (cluster state)              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                        │
│  • Multi-AZ (3 AZs) for high availability             │
│  • AWS patches and upgrades automatically              │
│  • Cost: $0.10/hour per cluster (~$72/month)          │
└────────────────────────┬───────────────────────────────┘
                         │ HTTPS (443)
                         │
┌──────── You Manage (Data Plane) ──────────────────────┐
│                                                        │
│  Node Group Options:                                   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Managed Node │ │  Self-Managed│ │   Fargate    │  │
│  │   Groups     │ │  Node Groups │ │  (Serverless)│  │
│  │              │ │              │ │              │  │
│  │ AWS manages  │ │ You manage   │ │ No nodes!    │  │
│  │ EC2 scaling  │ │ everything   │ │ Per-pod infra│  │
│  │ & patching   │ │              │ │              │  │
│  └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                        │
│  Worker Nodes run:                                     │
│  • kubelet (talks to API server)                      │
│  • kube-proxy (networking)                             │
│  • Container runtime (containerd)                     │
│  • Your application Pods                              │
└────────────────────────────────────────────────────────┘
```

---

## Key Concepts

| Concept | Description | AWS Component |
|---------|-------------|---------------|
| **Cluster** | K8s control plane + worker nodes | EKS Cluster |
| **Node Group** | Pool of EC2 instances (workers) | Managed Node Group |
| **Pod** | Smallest deployable unit (1+ containers) | Runs on Node or Fargate |
| **Deployment** | Manages replicas of a Pod | `kubectl apply -f deploy.yaml` |
| **Service** | Stable networking for Pods | ClusterIP, NodePort, LoadBalancer |
| **Ingress** | HTTP/HTTPS routing rules | AWS ALB Ingress Controller |
| **Namespace** | Logical resource isolation | dev, staging, production |
| **ConfigMap** | Non-sensitive configuration | Environment variables, config files |
| **Secret** | Sensitive data (base64 encoded) | DB passwords, API keys |
| **HPA** | Auto-scale Pods by CPU/memory/custom metrics | Horizontal Pod Autoscaler |
| **RBAC** | Access control (who can do what) | Roles, ClusterRoles, Bindings |

### Node Group Types

| Type | Managed Node Groups | Self-Managed | Fargate |
|------|-------------------|--------------|---------|
| **Infra management** | AWS manages EC2 | You manage everything | No nodes at all |
| **Patching** | AWS applies patches | You apply patches | AWS manages |
| **Scaling** | AWS Auto Scaling | You configure ASG | Per-pod auto-scaling |
| **Cost** | EC2 pricing | EC2 pricing | Per vCPU + memory/second |
| **GPU support** | Yes | Yes | No |
| **Best for** | Most workloads | Custom AMI, GPU | Batch jobs, burst traffic |

---

## Setting Up EKS

### Using eksctl (Recommended)

```yaml
# cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: production
  region: us-east-1
  version: "1.29"

iam:
  withOIDC: true    # Required for IAM roles for service accounts

managedNodeGroups:
  - name: general
    instanceType: t3.large
    desiredCapacity: 3
    minSize: 2
    maxSize: 10
    volumeSize: 50
    labels:
      role: general
    iam:
      withAddonPolicies:
        albIngress: true
        ebs: true
        cloudWatch: true

  - name: spot-workers
    instanceTypes: ["t3.large", "t3.xlarge", "m5.large"]
    spot: true
    desiredCapacity: 2
    minSize: 0
    maxSize: 20
    labels:
      role: worker
      lifecycle: spot
    taints:
      - key: spot
        value: "true"
        effect: PreferNoSchedule

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver
```

```bash
# Create cluster (takes ~15-20 min)
eksctl create cluster -f cluster.yaml

# Verify
kubectl get nodes
kubectl get pods -A
aws eks describe-cluster --name production
```

### Using AWS CLI
```bash
# Create cluster
aws eks create-cluster \
    --name production \
    --role-arn arn:aws:iam::123456:role/eks-cluster-role \
    --resources-vpc-config subnetIds=subnet-a,subnet-b,subnet-c,securityGroupIds=sg-abc

# Create managed node group
aws eks create-nodegroup \
    --cluster-name production \
    --nodegroup-name general \
    --node-role arn:aws:iam::123456:role/eks-node-role \
    --subnets subnet-a subnet-b subnet-c \
    --instance-types t3.large \
    --scaling-config minSize=2,maxSize=10,desiredSize=3

# Update kubeconfig
aws eks update-kubeconfig --name production --region us-east-1
```

---

## Core Kubernetes Objects on EKS

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-api
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: my-api
    spec:
      serviceAccountName: my-api-sa    # IAM role for pods
      containers:
      - name: api
        image: 123456.dkr.ecr.us-east-1.amazonaws.com/my-api:v1.0.0
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
        env:
        - name: NODE_ENV
          value: "production"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

### Service + Ingress (ALB)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-api
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: my-api
  ports:
  - port: 80
    targetPort: 3000

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456:certificate/xxx
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/healthcheck-path: /health
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: my-api
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### HPA (Auto Scaling)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-api
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
```

---

## IAM Roles for Service Accounts (IRSA)

```
┌───── Pod ──────┐     ┌──── IAM ────┐     ┌──── AWS ────┐
│                │     │              │     │              │
│ ServiceAccount │────▶│  IAM Role    │────▶│ S3, DynamoDB │
│ (annotated     │     │  (scoped to  │     │ RDS, SQS    │
│  with role)    │     │   namespace) │     │              │
└────────────────┘     └──────────────┘     └──────────────┘

Fine-grained: Each microservice gets ONLY the permissions it needs.
No shared EC2 instance role for all pods!
```

```bash
# Create IAM role for service account
eksctl create iamserviceaccount \
    --cluster production \
    --name my-api-sa \
    --namespace production \
    --attach-policy-arn arn:aws:iam::123456:policy/my-api-policy \
    --approve
```

```yaml
# Service Account with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-api-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456:role/my-api-role
```

---

## RBAC (Role-Based Access Control)

```yaml
# Developer can view/create in dev namespace only
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: developer
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/log", "pods/exec"]
  verbs: ["get", "create"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: dev
  name: developer-binding
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

---

## EKS vs ECS Comparison

| Factor | EKS (Kubernetes) | ECS |
|--------|------------------|-----|
| **Complexity** | Higher (K8s learning curve) | Lower (AWS-native) |
| **Ecosystem** | Huge (CNCF: Helm, ArgoCD, Istio) | AWS tools only |
| **Multi-cloud** | Yes (K8s runs everywhere) | No (AWS only) |
| **Control plane cost** | $72/month per cluster | Free |
| **Networking** | VPC CNI, Calico, Cilium | awsvpc only |
| **Service mesh** | Istio, Linkerd, App Mesh | App Mesh, Cloud Map |
| **Package manager** | Helm charts | Task definitions |
| **GitOps** | ArgoCD, Flux | Custom CI/CD |
| **Best for** | Large-scale, multi-cloud, K8s teams | AWS-first, simpler setups |

---

## Real-Time Example 1: Production EKS Cluster Setup

**Scenario:** Set up a production EKS cluster with managed node groups, ALB Ingress, and auto scaling.

```bash
# 1. Create cluster
eksctl create cluster -f cluster.yaml

# 2. Install AWS ALB Ingress Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=production \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

# 3. Install EBS CSI Driver (for persistent volumes)
eksctl create addon --name aws-ebs-csi-driver --cluster production

# 4. Install metrics server (required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 5. Create namespaces
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace monitoring

# 6. Deploy application
kubectl apply -f deployment.yaml -n production
kubectl apply -f service.yaml -n production
kubectl apply -f ingress.yaml -n production
kubectl apply -f hpa.yaml -n production

# 7. Verify
kubectl get all -n production
kubectl get ingress -n production
```

---

## Real-Time Example 2: Deploy Microservices with Helm

**Scenario:** Deploy 3 microservices using Helm charts.

```bash
# Helm chart structure
my-app/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
├── values-staging.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    └── configmap.yaml
```

```yaml
# values.yaml (defaults)
replicaCount: 2
image:
  repository: 123456.dkr.ecr.us-east-1.amazonaws.com/my-api
  tag: latest
service:
  port: 80
  targetPort: 3000
ingress:
  enabled: true
  host: api.example.com
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

# values-production.yaml (overrides)
replicaCount: 5
image:
  tag: v2.1.0
resources:
  requests:
    cpu: 500m
    memory: 512Mi
```

```bash
# Deploy with Helm
helm install my-api ./my-app -f values-production.yaml -n production

# Upgrade
helm upgrade my-api ./my-app -f values-production.yaml -n production

# Rollback
helm rollback my-api 1 -n production

# List releases
helm list -n production
```

---

## Real-Time Example 3: CI/CD with GitHub Actions → EKS

**Scenario:** Automated deployment pipeline.

```yaml
# .github/workflows/deploy-eks.yml
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456:role/github-actions
          aws-region: us-east-1

      - uses: aws-actions/amazon-ecr-login@v2
        id: ecr

      - name: Build & Push
        run: |
          IMAGE=${{ steps.ecr.outputs.registry }}/my-api:${{ github.sha }}
          docker build -t $IMAGE .
          docker push $IMAGE

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name production --region us-east-1

      - name: Deploy to EKS
        run: |
          kubectl set image deployment/my-api \
            api=${{ steps.ecr.outputs.registry }}/my-api:${{ github.sha }} \
            -n production
          kubectl rollout status deployment/my-api -n production --timeout=300s
```

---

## kubectl Essentials

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Workloads
kubectl get pods -n production -o wide
kubectl describe pod <name> -n production
kubectl logs <pod> -c <container> --tail=100 -f
kubectl exec -it <pod> -n production -- /bin/sh

# Deployments
kubectl rollout status deployment/my-api -n production
kubectl rollout history deployment/my-api -n production
kubectl rollout undo deployment/my-api -n production
kubectl scale deployment/my-api --replicas=5 -n production

# Debugging
kubectl get events --sort-by=.lastTimestamp -n production
kubectl top pods -n production
kubectl port-forward svc/my-api 8080:80 -n production

# Context management
kubectl config get-contexts
kubectl config use-context arn:aws:eks:us-east-1:123456:cluster/production
```

---

## Labs

### Lab 1: Create an EKS Cluster
```bash
# Create cluster with eksctl (2 managed node groups)
# Verify nodes with kubectl get nodes
# Deploy nginx deployment (3 replicas)
# Expose via LoadBalancer service
# Access application via ELB URL
```

### Lab 2: Deploy with ALB Ingress + SSL
```bash
# Install AWS ALB Ingress Controller (Helm)
# Create Ingress with path-based routing
# Configure ACM certificate for HTTPS
# Deploy 2 services: frontend (/) and api (/api)
# Verify routing works correctly
```

### Lab 3: Auto Scaling (HPA + Cluster Autoscaler)
```bash
# Install metrics server
# Create HPA (CPU target: 70%)
# Run load test with k6
# Watch pods scale out: kubectl get hpa --watch
# Install Cluster Autoscaler
# Verify new nodes added when pods can't be scheduled
```

### Lab 4: RBAC + Namespaces
```bash
# Create dev and prod namespaces
# Create Role for developers (can view/create in dev only)
# Create RoleBinding
# Test: developer can deploy to dev but NOT production
# Create ClusterRole for read-only cluster-wide access
```

### Lab 5: Helm + CI/CD Pipeline
```bash
# Create Helm chart for your application
# Deploy to staging namespace
# Verify, then deploy to production
# Set up GitHub Actions pipeline:
#   Build → Push ECR → Deploy to EKS (kubectl set image)
# Verify rolling update completes
```

---

## Interview Questions

1. **What is EKS?**
   → Managed Kubernetes service on AWS. AWS runs the control plane (API server, etcd, scheduler) across 3 AZs. You manage worker nodes and deploy workloads using standard Kubernetes APIs.

2. **EKS vs self-managed Kubernetes?**
   → EKS: AWS manages control plane (HA, patching, upgrades), integrates with IAM, ALB, EBS, CloudWatch. Self-managed: you handle everything. EKS costs $0.10/hr for control plane but saves significant operational effort.

3. **What are the node group options in EKS?**
   → Managed Node Groups (AWS handles EC2 scaling/patching), Self-Managed (you control everything, custom AMIs, GPU), Fargate (serverless, no nodes to manage). Most use Managed Node Groups.

4. **Explain IRSA (IAM Roles for Service Accounts).**
   → Maps Kubernetes ServiceAccounts to IAM Roles via OIDC. Each pod gets only the AWS permissions it needs (least privilege). No shared instance role. Example: API pod gets S3 access, worker pod gets SQS access.

5. **How does Ingress work on EKS?**
   → AWS ALB Ingress Controller watches Ingress resources and creates/configures ALBs automatically. Supports path-based routing, host-based routing, SSL termination (ACM), and target-type IP (Fargate compatible).

6. **How do you handle deployments and rollbacks?**
   → Rolling updates (default): replace pods in batches. Rollback: `kubectl rollout undo`. For advanced strategies: use Argo Rollouts for canary/blue-green. Helm: `helm rollback` to previous release.

7. **How does auto scaling work on EKS?**
   → Two levels: HPA scales pods based on CPU/memory/custom metrics. Cluster Autoscaler scales nodes when pods can't be scheduled (pending). Karpenter is a newer alternative to Cluster Autoscaler (faster, more flexible).

8. **EKS vs ECS — how do you decide?**
   → ECS: simpler, AWS-native, no control plane cost, less to learn. EKS: Kubernetes standard, huge ecosystem (Helm, ArgoCD, Istio), multi-cloud portability. Choose EKS when team has K8s experience or needs CNCF tooling.

---

> **Deep Dive:** For full Kubernetes fundamentals, RBAC, network policies, and StatefulSets, see [10-Kubernetes-EKS](../../10-Kubernetes-EKS/README.md).
