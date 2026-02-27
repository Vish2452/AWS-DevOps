# Module 14 — Capstone Projects (2–3 Weeks)

> **Objective:** Apply ALL skills from the bootcamp to build a production-grade end-to-end project. Choose one of four options below.

---

## 🏆 Real-World Analogy: Capstone = Your Final Driving Test

You've spent months learning:

```
  🏫 THE BOOTCAMP JOURNEY:

  📖 Linux         = Learned how a car engine works
  📝 Shell Scripts  = Practiced basic driving in a parking lot
  🔀 Git            = Learned traffic rules
  ☁️ AWS Services   = Understood road types (highway, local, toll)
  📦 Docker         = Packed your car efficiently
  🏭 CI/CD          = Automated car washing & maintenance
  📐 Terraform      = Built the roads themselves
  ⚓ Kubernetes     = Managed a fleet of 100 cars
  📊 Monitoring     = Installed dashcam & GPS tracking
  🛡️ Security       = Added locks, alarms & insurance

  🏆 CAPSTONE = Now drive cross-country on a real road trip!
     Combine EVERYTHING into one real production system.
     This is what you show employers.
```

### What Employers See
```
  Resume WITHOUT Capstone:
    "• Learned Kubernetes"  →  Employer: "So did 10,000 others" 😴

  Resume WITH Capstone:
    "• Built a banking microservices platform on EKS
       - 5 microservices with Helm charts
       - Jenkins pipeline: build → scan → deploy
       - HashiCorp Vault for secrets rotation
       - Prometheus/Grafana monitoring with SLO dashboards
       - Zero-downtime deployments with canary releases
       - Terraform modules for 3 environments
       - GitHub: github.com/me/banking-platform"
    
    Employer: "When can you start?" 🤩
```

---

## Choose Your Capstone

| Option | Domain | Key Services | Difficulty |
|--------|--------|-------------|-----------|
| **A** | Content Delivery Platform | EKS, Terraform, GitHub Actions, Prometheus | ★★★★☆ |
| **B** | Banking / FinTech | EKS, Vault, Liquibase, Jenkins | ★★★★★ |
| **C** | E-Commerce on EKS | EKS, ArgoCD, Helm, Karpenter | ★★★★☆ |
| **D** | IoT Analytics Pipeline | Lambda, Glue, Step Functions, Kinesis | ★★★★☆ |

---

## Option A — Content Delivery Platform (CDP)

### Architecture
```
Users → Route53 → CloudFront → ALB → EKS Cluster
                      │                     │
                   S3 (static)    ┌─────────┼──────────┐
                                  │         │          │
                             Frontend    API Server   Workers
                             (React)    (Node.js)   (FFmpeg)
                                  │         │          │
                                  └────┬────┘          │
                                       │               │
                                  RDS PostgreSQL   S3 (media)
                                  (Multi-AZ)       + CloudFront
                                       │
                                  ElastiCache
                                  (Redis)
```

### Components to Build
- [ ] **Infrastructure (Terraform)**
  - VPC (3-tier: public, private, database subnets)
  - EKS cluster with managed node groups
  - RDS PostgreSQL Multi-AZ
  - ElastiCache Redis cluster
  - S3 buckets (media + static assets)
  - CloudFront distributions
  - Route53 hosted zone + DNS records
  - ACM certificates

- [ ] **Application (Docker + Kubernetes)**
  - React frontend (Nginx container)
  - Node.js API server with health checks
  - FFmpeg worker for video transcoding
  - Helm chart for all services
  - HPA for auto-scaling
  - Network policies

- [ ] **CI/CD (GitHub Actions)**
  - OIDC authentication to AWS
  - Build → Test → Scan → Push → Deploy
  - Terraform plan on PR, apply on merge
  - SonarQube quality gate
  - Trivy image scanning
  - Slack notifications

- [ ] **Monitoring & Security**
  - Prometheus + Grafana dashboards
  - EFK centralized logging
  - Vault for secrets management
  - RBAC for namespace isolation
  - Network policies
  - WAF on CloudFront

### Deliverables
- Full Terraform codebase (modules + environments)
- Dockerfiles for all services
- Helm chart with values per environment
- GitHub Actions workflows (CI + CD + Terraform)
- Grafana dashboards (cluster + application)
- Architecture diagram
- Cost estimate
- Runbook documentation

---

## Option B — Banking / FinTech Application

### Architecture
```
Mobile/Web → API Gateway → NLB → EKS Cluster (Private)
                 │                       │
              WAF + Shield    ┌──────────┼──────────┐
                              │          │          │
                          Auth Svc   Account Svc  Payment Svc
                          (OAuth2)   (CRUD)       (Async)
                              │          │          │
                              └─────┬────┘          │
                                    │               │
                              RDS PostgreSQL    SQS + Lambda
                              (Encrypted,       (Payment
                               Multi-AZ)        processing)
                                    │
                              Liquibase
                              (Schema Mgmt)
```

### Security Requirements (Banking-Grade)
- All data encrypted at rest (KMS CMK)
- All traffic encrypted in transit (TLS 1.3)
- VPC with no public subnets (private EKS)
- WAF + Shield Advanced on API Gateway
- Vault for all secrets (dynamic DB credentials)
- Pod security standards (restricted)
- Network policies (zero-trust)
- CloudTrail + GuardDuty enabled
- Compliance logging to S3 (immutable)

### Components to Build
- [ ] **Infrastructure** — Private EKS, RDS encrypted, VPN access
- [ ] **Database** — Liquibase changelogs, IAM auth, audit tables
- [ ] **Application** — Microservices with circuit breakers
- [ ] **CI/CD** — Jenkins pipeline with approval gates
- [ ] **Security** — Vault, KMS, WAF, network policies
- [ ] **Compliance** — CloudTrail, Config rules, audit logging
- [ ] **DR** — Cross-region RDS replica, S3 cross-region replication

---

## Option C — E-Commerce Platform on EKS

### Architecture
```
Internet → CloudFront → ALB → EKS Cluster
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
               Storefront      Catalog API     Order Service
               (Next.js)       (Go)            (Java Spring)
                    │               │               │
                    │          DynamoDB          SQS Queue
                    │          (products)            │
                    │               │           Lambda
                    └───────┬───────┘           (fulfillment)
                            │
                      RDS (orders)
                      Redis (sessions + cart)
```

### Components to Build
- [ ] **Infrastructure** — Terraform modules, Karpenter for node scaling
- [ ] **GitOps** — ArgoCD for deployment, Helm charts
- [ ] **Application** — 3 microservices (different languages)
- [ ] **Data** — DynamoDB, RDS, ElastiCache
- [ ] **CI/CD** — GitHub Actions → ECR → ArgoCD sync
- [ ] **Observability** — Prometheus, Grafana, distributed tracing
- [ ] **Performance** — Load testing with k6, HPA tuning

### ArgoCD Setup
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-storefront
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/ecommerce-platform.git
    targetRevision: main
    path: helm/storefront
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Option D — IoT Analytics Pipeline

### Architecture
```
IoT Devices → Kinesis Data Stream → Lambda (transform)
                                         │
                                    Kinesis Firehose
                                         │
                                    S3 (raw data)
                                         │
                              ┌──────────┼──────────┐
                              │          │          │
                         Glue Crawler  Glue ETL   Step Functions
                              │          │          (orchestrate)
                              │     S3 (processed)      │
                              │          │              │
                         Data Catalog    │         SNS Alerts
                              │          │         (anomalies)
                              │          │
                         Athena Queries  │
                              │          │
                         QuickSight Dashboards
```

### Components to Build
- [ ] **Ingestion** — Kinesis Data Streams, Firehose delivery
- [ ] **Processing** — Lambda transforms, Glue ETL jobs
- [ ] **Storage** — S3 data lake (raw/processed/curated layers)
- [ ] **Catalog** — Glue crawlers, Data Catalog, partitioning
- [ ] **Query** — Athena with workgroups, saved queries
- [ ] **Visualization** — QuickSight dashboards
- [ ] **Orchestration** — Step Functions state machine
- [ ] **Alerting** — CloudWatch + Lambda anomaly detection
- [ ] **IaC** — Everything in Terraform
- [ ] **CI/CD** — GitHub Actions for Lambda + Glue deployments

---

## Evaluation Criteria

| Category | Weight | What's Assessed |
|----------|--------|----------------|
| **Infrastructure as Code** | 25% | Terraform quality, modules, state management |
| **CI/CD Pipeline** | 20% | Automation, security gates, environments |
| **Security** | 20% | Encryption, IAM, secrets, scanning |
| **Monitoring** | 15% | Dashboards, alerts, logging |
| **Documentation** | 10% | Architecture diagrams, runbooks, README |
| **Code Quality** | 10% | Clean code, tests, linting |

### Submission Checklist
- [ ] GitHub repository with clean commit history
- [ ] Architecture diagram (draw.io or Lucidchart)
- [ ] Working CI/CD pipeline (green builds)
- [ ] Infrastructure provisioned and verified
- [ ] Monitoring dashboards with real data
- [ ] Security scan reports (SonarQube, Trivy, Checkov)
- [ ] Cost estimate (AWS Pricing Calculator)
- [ ] 5-minute demo video (optional but recommended)
- [ ] README with setup instructions (clone → deploy in < 30 min)
