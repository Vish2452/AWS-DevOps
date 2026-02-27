# Module 10 — Kubernetes & EKS (3 Weeks)

> **Objective:** Master Kubernetes fundamentals, deploy production-grade workloads on AWS EKS, and implement networking, storage, security, and scheduling best practices.

---

## ⚓ Real-World Analogy: Kubernetes is Like Running a Shipping Port

Imagine you're managing a **massive container shipping port** (like the Port of Singapore):

```
🚢 YOUR SHIPPING PORT (Kubernetes Cluster)
│
├── 📦 Containers (Pods)
│   Each container = a Box with your app inside
│   Pod = the smallest unit (1 or more containers on one truck)
│
├── 🚚 Trucks (Worker Nodes)
│   Physical/virtual machines that carry the containers
│   Each truck has a driver (kubelet) who follows instructions
│
├── 📋 Port Manager (Control Plane)
│   ├── API Server = Reception desk (all requests go here)
│   ├── Scheduler = "Which truck has space for this container?"
│   ├── Controller = "We need 3 copies of this container running. Only 2? Start 1 more!"
│   └── etcd = The port's record book (stores ALL state)
│
├── 📜 Deployment = Shipping Order
│   "I need 5 copies of my web app running at all times"
│   If one container crashes → Kubernetes auto-creates a replacement!
│
├── 🌐 Service = Port's customer window
│   Customers don't need to know WHICH container handles their request.
│   The Service gives a single address that routes to healthy containers.
│
├── 📨 Ingress = Main gate with directions
│   "/api" traffic → goes to API containers
│   "/web" traffic → goes to Frontend containers
│   Like a mall directory sign at the entrance.
│
└── 📈 HPA (Horizontal Pod Autoscaler) = Hiring temp workers
    "If workload > 80%, hire more workers (pods).
     If workload < 20%, send some home (scale down)."
    Black Friday? Auto-scale from 5 to 50 pods!
```

### Self-Healing: The Magic of Kubernetes
```
  💥 SCENARIO: One of your app containers crashes!

  WITHOUT Kubernetes:
    Engineer gets paged at 3 AM → SSH into server → restart app → 30 min downtime

  WITH Kubernetes:
    Container crashes at 3:00:00 AM
    Kubernetes detects it at 3:00:01 AM
    New container starts at 3:00:03 AM
    Engineer sleeps peacefully 😴
    (Finds out next morning from the logs)
```

### EKS = Kubernetes Where AWS Manages the Hard Parts
```
  Regular Kubernetes (self-managed):  
    YOU manage: Control Plane + Worker Nodes + Upgrades + HA
    Like running your OWN shipping port from scratch.

  EKS (AWS managed):  
    AWS manages: Control Plane (HA, upgrades, patches)
    YOU manage: Worker Nodes + your apps
    Like renting a port facility where the building & management is provided.
```

---

## Week 1 — Kubernetes Fundamentals

### Architecture
```
┌──────────────────── Control Plane ────────────────────┐
│  ┌───────────┐  ┌───────────┐  ┌──────────────────┐  │
│  │ API Server│  │ Scheduler │  │ Controller Mgr   │  │
│  └─────┬─────┘  └─────┬─────┘  └──────────────────┘  │
│        │               │                               │
│  ┌─────┴───────────────┴──────────────────────────┐   │
│  │               etcd (cluster state)              │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────┘
                          │
┌─────────── Worker Nodes ──────────────────────────────┐
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   kubelet   │  │ kube-proxy  │  │  Container   │   │
│  │             │  │             │  │  Runtime     │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                 │           │
│  ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐   │
│  │    Pod      │  │    Pod      │  │    Pod      │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
└───────────────────────────────────────────────────────┘
```

### Core Objects
| Object | Purpose | Key Fields |
|--------|---------|-----------|
| **Pod** | Smallest deployable unit | `containers`, `volumes` |
| **Deployment** | Declarative pod management | `replicas`, `strategy`, `template` |
| **Service** | Stable networking endpoint | `ClusterIP`, `NodePort`, `LoadBalancer` |
| **ConfigMap** | External configuration | `data` key-value pairs |
| **Secret** | Sensitive data (base64) | `data`, `stringData` |
| **Namespace** | Resource isolation | Logical cluster partition |
| **ReplicaSet** | Ensures N pod replicas | Managed by Deployment |
| **DaemonSet** | One pod per node | Logging, monitoring agents |
| **StatefulSet** | Stateful workloads | Stable identity, ordered deploy |
| **Job / CronJob** | Batch / scheduled tasks | `completions`, `schedule` |

### Hands-On: Deployment Manifest
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

---

## Week 2 — Networking, Storage & Ingress

### Service Types
```yaml
# ClusterIP (internal only)
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080

---
# LoadBalancer (AWS ALB/NLB via controller)
apiVersion: v1
kind: Service
metadata:
  name: frontend
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
```

### Ingress with AWS ALB Controller
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456:certificate/abc
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 3000
```

### Persistent Volumes (EBS / EFS)
```yaml
# StorageClass for EBS gp3
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain

---
# PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 20Gi
```

---

## Week 3 — Security, Scheduling & Production

### RBAC
```yaml
# Role — namespace-scoped
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: developer-role
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]

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
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

### Pod Security & Scheduling
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
  # Scheduling
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: webapp
        topologyKey: kubernetes.io/hostname
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
```

### HPA (Horizontal Pod Autoscaler)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
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

## Real-Time Project: Production EKS Cluster

### Architecture
```
Internet → Route53 → WAF → ALB (Ingress) → EKS Cluster
                                                  │
                                    ┌─────────────┼─────────────┐
                                    │             │             │
                               Frontend      Backend       Workers
                              (React SPA)   (Node API)   (Background)
                                    │             │             │
                                    └──────┬──────┘             │
                                           │                    │
                                     RDS PostgreSQL    ElastiCache Redis
                                     (Multi-AZ)       (Cluster Mode)
```

### EKS Setup with eksctl
```yaml
# cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: production-cluster
  region: us-east-1
  version: "1.29"

iam:
  withOIDC: true

managedNodeGroups:
  - name: general
    instanceType: t3.large
    desiredCapacity: 3
    minSize: 2
    maxSize: 10
    volumeSize: 50
    ssh:
      allow: false
    labels:
      role: general
    iam:
      withAddonPolicies:
        albIngress: true
        ebs: true
        efs: true
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

### Deliverables
- [ ] EKS cluster with managed node groups (on-demand + spot)
- [ ] AWS ALB Ingress Controller with TLS termination
- [ ] EBS CSI driver for persistent storage
- [ ] RBAC for dev/staging/prod namespaces
- [ ] Network policies restricting pod-to-pod traffic
- [ ] HPA configured for auto-scaling
- [ ] Pod security contexts (non-root, read-only FS)
- [ ] Helm charts for application deployment
- [ ] ConfigMaps and Secrets for environment config
- [ ] Resource requests/limits on every container

---

## kubectl Cheat Sheet
```bash
kubectl get pods -A                          # All pods, all namespaces
kubectl get pods -o wide                     # Pod IPs and node placement
kubectl describe pod <name>                  # Detailed pod info
kubectl logs <pod> -c <container> --tail=50  # Container logs
kubectl exec -it <pod> -- /bin/sh            # Shell into container
kubectl apply -f manifest.yaml               # Apply configuration
kubectl delete -f manifest.yaml              # Delete resources
kubectl rollout status deploy/<name>         # Watch rollout
kubectl rollout undo deploy/<name>           # Rollback
kubectl top pods                             # Resource usage
kubectl get events --sort-by=.lastTimestamp  # Recent events
kubectl port-forward svc/<name> 8080:80      # Local port forward
kubectl scale deploy/<name> --replicas=5     # Manual scale
kubectl config get-contexts                  # List kubeconfig contexts
kubectl config use-context <name>            # Switch context
```
