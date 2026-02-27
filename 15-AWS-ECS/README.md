# AWS ECS — Elastic Container Service (Production Workloads)

> **Objective:** Run production containers on AWS ECS with Fargate and EC2 launch types. Deploy 2-tier and microservice applications with Terraform, custom domains, SSL, auto-scaling, and monitoring.

---

## 🚢 Real-World Analogy: ECS is Like a Container Ship Dock

If Docker containers are **shipping containers**, then ECS is the **dock where containers are loaded, unloaded, and managed**:

```
🏢 ECS CLUSTER = A Container Ship Terminal
│
├── 📦 Task Definition = Shipping Manifest
│   "This container needs:
│    - 512 MB memory (cargo weight limit)
│    - 256 CPU units (crane speed)
│    - Port 8080 exposed (loading dock number)
│    - Environment: PRODUCTION"
│
├── 📦 Task = One running container (one ship being loaded)
│   The actual work being done right now.
│
├── 🚚 Service = Fleet Manager
│   "Keep exactly 3 copies of this task running at all times.
│    If one crashes, start a replacement.
│    During peak hours, scale to 10."
│
└── Launch Types:
    ┌───────────────────────────────────────────┐
    │ EC2 Launch Type = You OWN the dock             │
    │   Rent physical cranes and workers              │
    │   More control, you maintain the equipment      │
    │   Cheaper at large scale                        │
    ├───────────────────────────────────────────┤
    │ Fargate Launch Type = RENT the dock per hour    │
    │   AWS provides the cranes and workers           │
    │   Zero infrastructure to manage!                │
    │   Just say "run my container" and it runs.      │
    │   Pay per second of actual usage.               │
    └───────────────────────────────────────────┘
```

### ECS vs EKS: When to Use Which
```
  🚢 ECS = Uber for containers
     "Just run my container. I don't care HOW."
     Simple, AWS-native, less to learn.
     Best for: Teams new to containers, small-medium workloads.

  ⚓ EKS = Owning a taxi company
     Full control over fleet operations.
     Kubernetes ecosystem (Helm, ArgoCD, Istio).
     Best for: Large-scale, multi-cloud, complex microservices.

  💡 RULE OF THUMB:
     < 10 services? Start with ECS.
     > 10 services + need Kubernetes ecosystem? Use EKS.
     Not sure? ECS Fargate — simplest path to production.
```

### Real-World Architecture
```
  User → Route53 → ALB (Load Balancer)
                      │
           ┌──────────┼──────────┐
           │                      │
      /api/* path            /web/* path
           │                      │
    ECS Service: API      ECS Service: Web
    (3 Fargate tasks)     (2 Fargate tasks)
           │
        RDS Database
        
  Total cost: ~$80/month for a startup!
  (Fargate Spot can reduce this by 70%)
```

---

## ECS Architecture

```
┌───────────────── ECS Cluster ──────────────────────────┐
│                                                         │
│  ┌─── Service A ────────┐  ┌─── Service B ────────┐   │
│  │ Task Definition      │  │ Task Definition      │   │
│  │ ┌────┐ ┌────┐       │  │ ┌────┐ ┌────┐       │   │
│  │ │Task│ │Task│ (2x)  │  │ │Task│ │Task│ (3x)  │   │
│  │ └────┘ └────┘       │  │ └────┘ └────┘       │   │
│  └──────────┬───────────┘  └──────────┬───────────┘   │
│             │                         │                │
│  ┌──────────┴─────────────────────────┴──────────┐    │
│  │              Application Load Balancer          │    │
│  │              (path-based routing)               │    │
│  └─────────────────────┬───────────────────────────┘    │
└─────────────────────────┼──────────────────────────────┘
                          │
              Route53 → ACM (SSL) → ALB
```

### ECS vs EKS — When to Use Which
| Factor | ECS | EKS |
|--------|-----|-----|
| Complexity | Simpler, AWS-native | More complex, K8s standard |
| Team size | Small → Medium | Medium → Large |
| Ecosystem | AWS-only | Multi-cloud, CNCF tools |
| Cost | Lower (no control plane fee) | $0.10/hr per cluster |
| Service mesh | AWS App Mesh / Cloud Map | Istio, Linkerd |
| Best for | AWS-first teams | K8s expertise, portability |

---

## Core Concepts

### Task Definition
```json
{
  "family": "webapp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::123456:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "123456.dkr.ecr.us-east-1.amazonaws.com/webapp:latest",
      "portMappings": [
        { "containerPort": 3000, "protocol": "tcp" }
      ],
      "environment": [
        { "name": "NODE_ENV", "value": "production" }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456:secret:prod/db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/webapp",
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

### Service Discovery (Cloud Map)
```hcl
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "internal.local"
  description = "Service discovery for ECS microservices"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
```

---

## Terraform: Production ECS Deployment

### VPC + Networking
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  one_nat_gateway_per_az = var.environment == "production"

  tags = local.common_tags
}
```

### ECS Cluster + Service
```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }
}

resource "aws_ecs_service" "webapp" {
  name            = "webapp"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.webapp.arn
  desired_count   = var.environment == "production" ? 3 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.webapp.arn
    container_name   = "app"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  service_registries {
    registry_arn = aws_service_discovery_service.webapp.arn
  }

  lifecycle {
    ignore_changes = [task_definition]  # Managed by CI/CD
  }
}
```

### Auto-Scaling
```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 20
  min_capacity       = var.environment == "production" ? 3 : 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.webapp.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "alb_requests" {
  name               = "alb-request-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.webapp.arn_suffix}"
    }
    target_value       = 1000.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
```

### ALB + SSL + Route53
```hcl
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
```

---

## CI/CD: GitHub Actions → ECS

```yaml
name: Deploy to ECS
on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: webapp
  ECS_SERVICE: webapp
  ECS_CLUSTER: myproject-production

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
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - uses: aws-actions/amazon-ecr-login@v2
        id: login-ecr

      - name: Build, Tag, Push
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
        id: build

      - name: Update Task Definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: app
          image: ${{ steps.build.outputs.image }}

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true

      - name: Verify Deployment
        run: |
          aws ecs describe-services \
            --cluster $ECS_CLUSTER --services $ECS_SERVICE \
            --query 'services[0].deployments' --output table
```

---

## Microservices on ECS

### Multi-Service Architecture
```
Internet → ALB (path-based routing)
              │
    ┌─────────┼──────────┬──────────┐
    │         │          │          │
  /app     /api       /auth     /worker
 Frontend  Backend    Auth Svc   Background
 (React)   (Node.js)  (Go)      (Python)
    │         │          │          │
    │    ┌────┴────┐     │      SQS Queue
    │    │         │     │          │
    │   RDS     Redis    │       Lambda
    │  (orders) (cache)  │     (processing)
    │         │          │
    └─────────┴──────────┘
        Service Discovery
        (Cloud Map: *.internal.local)
```

### Dynamic Terraform (Dev vs Prod)
```hcl
# RDS: Instance for dev, Aurora cluster for prod
resource "aws_db_instance" "dev" {
  count                = var.environment == "production" ? 0 : 1
  identifier           = "${var.project}-${var.environment}"
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  skip_final_snapshot  = true
}

resource "aws_rds_cluster" "prod" {
  count              = var.environment == "production" ? 1 : 0
  cluster_identifier = "${var.project}-${var.environment}"
  engine             = "aurora-postgresql"
  engine_version     = "16.1"
  master_username    = var.db_username
  master_password    = var.db_password
  storage_encrypted  = true
  kms_key_id         = aws_kms_key.rds.arn

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 16
  }
}
```

---

## Monitoring & Alerting

```hcl
# CloudWatch alarms for ECS
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.webapp.name
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_tasks" {
  alarm_name          = "${var.project}-unhealthy-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.environment == "production" ? 2 : 1
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.webapp.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
```

---

## Deliverables
- [ ] ECS cluster with Fargate launch type
- [ ] 2-tier app (frontend + DB) deployed with domain + SSL
- [ ] Microservices architecture with path-based ALB routing
- [ ] Service discovery via Cloud Map
- [ ] Auto-scaling (CPU + ALB request count)
- [ ] GitHub Actions CI/CD (build → scan → push ECR → deploy ECS)
- [ ] OIDC keyless authentication (no static AWS keys)
- [ ] Dynamic Terraform (RDS instance on dev, Aurora on prod)
- [ ] CloudWatch Container Insights + custom alarms
- [ ] Load testing with results (k6 or Artillery)
- [ ] Deployment circuit breaker with automatic rollback
