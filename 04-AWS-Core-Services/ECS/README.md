# ECS — Elastic Container Service

> Fully managed container orchestration. Run Docker containers at scale without managing servers. Deploy, scale, and monitor containerized applications on AWS.

---

## Real-World Analogy

ECS is like a **container shipping dock**:
- **Cluster** = The entire port facility
- **Task Definition** = Shipping manifest (what's in the container, how much space it needs)
- **Task** = One running container being processed at the dock
- **Service** = Fleet manager — "Keep 3 ships running at all times. If one sinks, launch another."
- **Fargate** = You rent dock space per hour — no need to own the port
- **EC2 launch type** = You own the dock — more control, more responsibility

---

## ECS Architecture

```
                        Internet
                           │
                      Route 53 (DNS)
                           │
                    ALB (Load Balancer)
                     ┌─────┴─────┐
                     │ Path-based │
                     │  Routing   │
                     └──┬─────┬──┘
                        │     │
               /api/*   │     │  /web/*
                        │     │
┌──────────────── ECS Cluster ─────────────────────┐
│                                                   │
│  ┌── Service: API ──────┐  ┌── Service: Web ──┐  │
│  │                      │  │                  │  │
│  │  ┌────┐ ┌────┐      │  │  ┌────┐ ┌────┐  │  │
│  │  │Task│ │Task│ (3x) │  │  │Task│ │Task│  │  │
│  │  └────┘ └────┘      │  │  └────┘ └────┘  │  │
│  └──────────────────────┘  └─────────────────┘  │
│                                                   │
│  Launch Types:                                    │
│  • Fargate — serverless (AWS manages infra)      │
│  • EC2 — you manage the instances                │
└───────────────────────────────────────────────────┘
         │                    │
    RDS (Database)      ElastiCache (Redis)
```

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Cluster** | Logical grouping of tasks/services | `production`, `staging` |
| **Task Definition** | Blueprint for running a container | Image, CPU, memory, ports, env vars |
| **Task** | A running instance of a task definition | One or more containers running together |
| **Service** | Maintains desired count of tasks | "Always keep 3 tasks running" |
| **Launch Type** | Where tasks run | Fargate (serverless) or EC2 (self-managed) |
| **Container Insights** | Built-in monitoring | CPU, memory, network metrics per task |
| **Service Discovery** | DNS-based service communication | Cloud Map: `api.internal.local` |
| **Task Role** | IAM role for the application | App code accesses S3, DynamoDB |
| **Execution Role** | IAM role for ECS agent | Pull images from ECR, write logs |

### Fargate vs EC2 Launch Type

| Factor | Fargate | EC2 |
|--------|---------|-----|
| **Infrastructure** | Fully managed (serverless) | You manage EC2 instances |
| **Pricing** | Per vCPU + memory per second | EC2 instance cost (Reserved/Spot) |
| **Scaling** | Instant task scaling | Must scale instances + tasks |
| **Control** | Less (no SSH, no host access) | Full (SSH, custom AMI, GPU) |
| **Maintenance** | Zero (AWS patches host OS) | You patch, update, monitor instances |
| **Networking** | awsvpc only (each task gets ENI) | bridge, host, awsvpc |
| **Best for** | Most workloads, startups | GPU, large-scale, cost optimization |
| **Spot** | Fargate Spot (70% cheaper) | EC2 Spot Instances |

---

## Task Definition

```json
{
  "family": "my-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::123456:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "api",
      "image": "123456.dkr.ecr.us-east-1.amazonaws.com/my-api:v1.0.0",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        { "name": "NODE_ENV", "value": "production" },
        { "name": "PORT", "value": "3000" }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456:secret:prod/db-pass"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### Key Task Definition Fields

| Field | Purpose |
|-------|---------|
| `family` | Name of the task definition (versions are auto-incremented) |
| `cpu` / `memory` | Fargate size: 256-4096 CPU, 512-30720 MB memory |
| `executionRoleArn` | Allows ECS to pull images from ECR and write to CloudWatch Logs |
| `taskRoleArn` | Allows your APPLICATION code to access AWS services (S3, DynamoDB) |
| `essential` | If `true` and this container dies, the whole task stops |
| `secrets` | Pull values from Secrets Manager / Parameter Store at runtime |
| `logConfiguration` | Send container logs to CloudWatch, Splunk, Fluentd, etc. |
| `healthCheck` | Container-level health check (separate from ALB health check) |

---

## ECS Service

```bash
# Create a service with ALB
aws ecs create-service \
    --cluster production \
    --service-name my-api \
    --task-definition my-api:3 \
    --desired-count 3 \
    --launch-type FARGATE \
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-abc", "subnet-def"],
            "securityGroups": ["sg-123"],
            "assignPublicIp": "DISABLED"
        }
    }' \
    --load-balancers '[{
        "targetGroupArn": "arn:aws:elasticloadbalancing:...:targetgroup/my-api/abc",
        "containerName": "api",
        "containerPort": 3000
    }]' \
    --deployment-configuration '{
        "minimumHealthyPercent": 100,
        "maximumPercent": 200,
        "deploymentCircuitBreaker": {
            "enable": true,
            "rollback": true
        }
    }'
```

### Deployment Strategies

| Strategy | How It Works | Use When |
|----------|-------------|----------|
| **Rolling Update** | Replace tasks in batches | Default, zero-downtime deploys |
| **Blue/Green (CodeDeploy)** | New task set → shift traffic → terminate old | Canary or linear traffic shifting |
| **Circuit Breaker** | Auto-rollback if new tasks fail health checks | Safety net for all deployments |

```
Rolling Update (desired = 3, min 100%, max 200%):

Step 1: [v1] [v1] [v1]  ← current
Step 2: [v1] [v1] [v1] [v2]  ← new task starts
Step 3: [v1] [v1] [v2] [v2]  ← old task drains
Step 4: [v1] [v2] [v2] [v2]  ← continues replacing
Step 5: [v2] [v2] [v2]  ← complete, zero downtime
```

---

## Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/production/my-api \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 20

# CPU-based scaling
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/production/my-api \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name cpu-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
        },
        "TargetValue": 70.0,
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
    }'
```

### Scaling Metrics

| Metric | Target | Use When |
|--------|--------|----------|
| `ECSServiceAverageCPUUtilization` | 70% | CPU-bound workloads |
| `ECSServiceAverageMemoryUtilization` | 80% | Memory-bound workloads |
| `ALBRequestCountPerTarget` | 1000 | Web APIs with predictable request patterns |
| **Scheduled Scaling** | Time-based | Known traffic patterns (business hours) |
| **Step Scaling** | Custom CloudWatch alarms | Complex scaling requirements |

---

## Service Discovery (Cloud Map)

```
┌──── ECS Cluster ──────────────────────────────┐
│                                                │
│  Service: frontend     Service: backend        │
│  frontend.app.local    backend.app.local       │
│       │                      │                 │
│       └──────── calls ──────▶│                 │
│                              │                 │
│  Service: auth          Service: cache         │
│  auth.app.local         cache.app.local        │
└────────────────────────────────────────────────┘

No hardcoded IPs! Services find each other by DNS name.
Cloud Map auto-registers/deregisters tasks as they start/stop.
```

```bash
# Create namespace
aws servicediscovery create-private-dns-namespace \
    --name app.local \
    --vpc vpc-abc123

# Create service registry
aws servicediscovery create-service \
    --name backend \
    --namespace-id ns-123 \
    --dns-config '{
        "DnsRecords": [{"Type": "A", "TTL": 10}],
        "RoutingPolicy": "MULTIVALUE"
    }'

# ECS service automatically registers tasks with Cloud Map
```

---

## ECS vs EKS — When to Use Which

| Factor | ECS | EKS |
|--------|-----|-----|
| **Complexity** | Simpler, AWS-native | Complex, Kubernetes ecosystem |
| **Team size** | Small → Medium | Medium → Large |
| **Learning curve** | Lower (task definitions) | Higher (K8s manifests, Helm) |
| **Ecosystem** | AWS tools only | CNCF ecosystem (Istio, ArgoCD, Helm) |
| **Multi-cloud** | No (AWS lock-in) | Yes (K8s runs anywhere) |
| **Control plane cost** | Free | $0.10/hour (~$72/month) per cluster |
| **Service mesh** | AWS App Mesh / Cloud Map | Istio, Linkerd |
| **Best for** | AWS-first teams, < 10 services | K8s expertise, > 10 services, portability |

> **Rule of thumb:** Start with ECS Fargate. Move to EKS when you need the Kubernetes ecosystem.

---

## Real-Time Example 1: Deploy a 2-Tier App (Fargate + RDS)

**Scenario:** Deploy a Node.js API with PostgreSQL database using ECS Fargate.

```bash
# 1. Create ECS cluster
aws ecs create-cluster --cluster-name production \
    --setting name=containerInsights,value=enabled

# 2. Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# 3. Create ALB target group
aws elbv2 create-target-group \
    --name my-api-tg \
    --protocol HTTP \
    --port 3000 \
    --vpc-id vpc-abc \
    --target-type ip \
    --health-check-path /health

# 4. Create ECS service
aws ecs create-service \
    --cluster production \
    --service-name my-api \
    --task-definition my-api:1 \
    --desired-count 3 \
    --launch-type FARGATE \
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-private-a", "subnet-private-b"],
            "securityGroups": ["sg-ecs-tasks"],
            "assignPublicIp": "DISABLED"
        }
    }' \
    --load-balancers '[{
        "targetGroupArn": "arn:...:targetgroup/my-api-tg/abc",
        "containerName": "api",
        "containerPort": 3000
    }]'

# 5. Update service (deploy new version)
aws ecs update-service \
    --cluster production \
    --service my-api \
    --task-definition my-api:2 \
    --force-new-deployment
```

---

## Real-Time Example 2: Microservices with Path-Based Routing

**Scenario:** 3 microservices behind one ALB with path-based routing.

```
ALB:
  /api/*     → Target Group: api-tg     → ECS Service: api     (3 tasks)
  /auth/*    → Target Group: auth-tg    → ECS Service: auth    (2 tasks)
  /*         → Target Group: web-tg     → ECS Service: web     (2 tasks)
```

```bash
# Create listener rules for path-based routing
aws elbv2 create-rule \
    --listener-arn arn:...:listener/app/my-alb/abc/def \
    --priority 10 \
    --conditions '[{"Field":"path-pattern","Values":["/api/*"]}]' \
    --actions '[{"Type":"forward","TargetGroupArn":"arn:...:targetgroup/api-tg/xxx"}]'

aws elbv2 create-rule \
    --listener-arn arn:...:listener/app/my-alb/abc/def \
    --priority 20 \
    --conditions '[{"Field":"path-pattern","Values":["/auth/*"]}]' \
    --actions '[{"Type":"forward","TargetGroupArn":"arn:...:targetgroup/auth-tg/xxx"}]'

# Internal service-to-service via Cloud Map
# api calls auth: http://auth.app.local:8080/verify
# No ALB needed for internal traffic!
```

---

## Real-Time Example 3: CI/CD Pipeline → ECR → ECS

**Scenario:** GitHub Actions builds Docker image, pushes to ECR, deploys to ECS.

```yaml
# .github/workflows/deploy.yml
name: Deploy to ECS
on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: my-api
  ECS_SERVICE: my-api
  ECS_CLUSTER: production

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
          aws-region: ${{ env.AWS_REGION }}

      - uses: aws-actions/amazon-ecr-login@v2
        id: ecr

      - name: Build & Push
        run: |
          IMAGE=${{ steps.ecr.outputs.registry }}/$ECR_REPOSITORY:${{ github.sha }}
          docker build -t $IMAGE .
          docker push $IMAGE
          echo "image=$IMAGE" >> $GITHUB_OUTPUT
        id: build

      - name: Deploy to ECS
        run: |
          # Update task definition with new image
          TASK_DEF=$(aws ecs describe-task-definition --task-definition $ECR_REPOSITORY --query taskDefinition)
          NEW_TASK_DEF=$(echo $TASK_DEF | jq --arg IMAGE "${{ steps.build.outputs.image }}" \
            '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')
          aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEF"
          aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment
```

---

## Monitoring & Troubleshooting

```bash
# View running tasks
aws ecs list-tasks --cluster production --service-name my-api
aws ecs describe-tasks --cluster production --tasks TASK_ARN

# View logs
aws logs get-log-events \
    --log-group-name /ecs/my-api \
    --log-stream-name ecs/api/TASK_ID

# ECS Exec (SSH into running container)
aws ecs execute-command \
    --cluster production \
    --task TASK_ARN \
    --container api \
    --interactive \
    --command "/bin/sh"

# Check deployment status
aws ecs describe-services --cluster production --services my-api \
    --query 'services[0].{desired:desiredCount,running:runningCount,deployments:deployments[*].{status:status,desired:desiredCount,running:runningCount,rolloutState:rolloutState}}'
```

---

## Labs

### Lab 1: Deploy a Container on ECS Fargate
```bash
# Create cluster, register task definition (nginx)
# Create service with 2 tasks
# Create ALB with target group
# Access application via ALB URL
# Update task definition → observe rolling deployment
```

### Lab 2: Multi-Container Task (App + Sidecar)
```bash
# Create task definition with 2 containers:
#   - Main app container (Node.js API)
#   - Sidecar container (CloudWatch agent / envoy proxy)
# Deploy as service
# Verify both containers running in same task
```

### Lab 3: Auto Scaling + Load Testing
```bash
# Configure auto scaling (CPU target tracking, 70%)
# Deploy service with min=2, max=10
# Run load test: k6 run --vus 100 --duration 5m load-test.js
# Watch tasks scale out in ECS console
# Stop load → watch scale in
```

### Lab 4: ECS Exec (Container Debugging)
```bash
# Enable ECS Exec on service
# Use aws ecs execute-command to shell into running task
# Debug network: curl internal endpoints
# Check environment variables
# Verify Secrets Manager values injected correctly
```

---

## Interview Questions

1. **What is ECS and how does it work?**
   → Fully managed container orchestration. You define task definitions (container specs), create services (desired count), and ECS schedules tasks across infrastructure. Supports Fargate (serverless) and EC2 launch types.

2. **Fargate vs EC2 launch type — when to use each?**
   → Fargate: serverless, zero infra management, per-second billing — best for most workloads. EC2: full host control, GPU, large-scale cost optimization with Reserved/Spot — best when you need host access or specific hardware.

3. **What is a Task Definition?**
   → Blueprint for running containers. Specifies image, CPU, memory, ports, environment variables, secrets, IAM roles, log configuration, and health checks. Versioned — each update creates a new revision.

4. **Explain Task Role vs Execution Role.**
   → Task Role: IAM role for your APPLICATION code (access S3, DynamoDB). Execution Role: IAM role for the ECS AGENT (pull images from ECR, write to CloudWatch Logs). Both are required for Fargate.

5. **How does ECS handle deployments?**
   → Rolling update: replaces tasks in batches (min/max healthy percent). Blue/Green via CodeDeploy: canary or linear traffic shifting. Circuit breaker: auto-rollback if new tasks fail health checks repeatedly.

6. **What is Service Discovery in ECS?**
   → AWS Cloud Map integration. Services register DNS names (e.g., `backend.app.local`). Tasks auto-register on start, deregister on stop. Enables service-to-service communication without hardcoded IPs or load balancers.

7. **How do you pass secrets to ECS tasks?**
   → Use `secrets` field in container definition. Reference Secrets Manager or SSM Parameter Store ARNs. Values are injected as environment variables at task start. Execution role needs permission to read the secrets.

8. **ECS vs EKS — how do you choose?**
   → ECS: simpler, AWS-native, no control plane cost, best for AWS-first teams. EKS: Kubernetes standard, CNCF tooling (Helm, ArgoCD, Istio), multi-cloud portability. Start with ECS; move to EKS when you need the K8s ecosystem.

---

> **Deep Dive:** For production Terraform deployments, microservices architecture, and CI/CD pipelines, see [15-AWS-ECS](../../15-AWS-ECS/README.md).
