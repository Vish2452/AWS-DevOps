# AWS Best Practices — Production-Grade Resource Management & Architecture

> **Objective:** Master AWS Well-Architected best practices for cost optimization, security, reliability, performance, and operational excellence. Build real-world projects with production-grade architecture diagrams.

---

## 🏗️ Real-World Analogy: AWS Best Practices = Building Code Compliance

Think of AWS like constructing a **skyscraper**. You CAN build it any way you want, but without following building codes, it'll collapse:

```
🏗️ BUILDING A SKYSCRAPER (Your AWS Infrastructure)
│
├── 🔒 SECURITY (Fire Safety Code)
│   "Every floor must have fire exits and sprinklers"
│   = Every resource must have encryption, least privilege, logging
│
├── 💰 COST (Budget Management)
│   "Don't build 50 floors if you only need 10"
│   = Don't run m5.4xlarge when t3.medium is enough
│   = Turn off development servers at night
│
├── 🔄 RELIABILITY (Earthquake Resistance)
│   "Building must withstand 7.0 quake"
│   = Infrastructure must survive AZ failure (Multi-AZ everything!)
│   = Backups must exist and be TESTED
│
├── ⚡ PERFORMANCE (Elevator Speed)
│   "Elevator must reach any floor in < 30 seconds"
│   = API must respond in < 200ms
│   = Use caching (ElastiCache), CDN (CloudFront)
│
└── 🔧 OPERATIONS (Building Maintenance)
    "Monthly inspections, emergency procedures documented"
    = IaC for everything, runbooks for incidents
    = Automated patching, monitoring, alerting
```

---

## AWS Well-Architected Framework (6 Pillars)

```
┌─────────────────── AWS WELL-ARCHITECTED FRAMEWORK ──────────────────┐
│                                                                      │
│  ┌─── 1. Operational Excellence ────────────────────────────────┐   │
│  │  • Infrastructure as Code (Terraform, CloudFormation)         │   │
│  │  • Automated deployments with rollback capability             │   │
│  │  • Runbooks and playbooks for every operational task          │   │
│  │  • Regular operational reviews and improvements               │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── 2. Security ──────────────────────────────────────────────┐   │
│  │  • Least privilege for all IAM policies                       │   │
│  │  • Encryption at rest and in transit (always)                 │   │
│  │  • Multi-layer security (WAF + SG + NACL + IAM)              │   │
│  │  • Centralized logging (CloudTrail, VPC Flow Logs)            │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── 3. Reliability ───────────────────────────────────────────┐   │
│  │  • Multi-AZ deployments for all stateful resources            │   │
│  │  • Auto-healing (ASG, ECS, EKS self-healing)                  │   │
│  │  • Automated backups with tested restore procedures           │   │
│  │  • Disaster recovery plan with defined RTO/RPO                │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── 4. Performance Efficiency ────────────────────────────────┐   │
│  │  • Right-sizing instances (use Compute Optimizer)             │   │
│  │  • Caching strategy (ElastiCache, CloudFront, DAX)            │   │
│  │  • Database optimization (read replicas, connection pooling)   │   │
│  │  • Async processing (SQS, EventBridge) for non-critical paths │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── 5. Cost Optimization ─────────────────────────────────────┐   │
│  │  • Reserved Instances / Savings Plans for predictable load    │   │
│  │  • Spot Instances for fault-tolerant workloads                │   │
│  │  • S3 lifecycle policies (Glacier for archives)               │   │
│  │  • Tag everything for cost allocation                         │   │
│  │  • Auto-shutdown dev/staging environments at night            │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── 6. Sustainability ────────────────────────────────────────┐   │
│  │  • Right-size to minimize waste                               │   │
│  │  • Use managed services (less overhead)                       │   │
│  │  • Graviton instances (ARM) = 40% better price-performance    │   │
│  │  • Data lifecycle management (delete what you don't need)     │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Service-by-Service Best Practices

### EC2 Best Practices
```
✅ DO:
  • Use latest generation instances (m7g, c7g, r7g — Graviton)
  • Enable detailed monitoring ($3.50/instance/mo — worth it!)
  • Use Launch Templates (not Launch Configurations)
  • Enable EBS encryption by default (account-level setting)
  • Use IMDSv2 (Instance Metadata Service v2) — block v1
  • Use SSM Session Manager instead of SSH (no port 22 needed!)
  • Tag EVERY instance: Name, Environment, Team, CostCenter
  • Use Spot Instances for dev/test/CI workloads (save 60-90%)
  • Install CloudWatch agent for memory & disk metrics
  • Schedule start/stop for non-production instances

❌ DON'T:
  • Don't use t2 instances (t3/t3a are cheaper AND faster)
  • Don't open port 22 to 0.0.0.0/0 (use SSM!)
  • Don't run without Auto Scaling Groups
  • Don't hardcode credentials in user-data scripts
  • Don't use gp2 volumes (gp3 is 20% cheaper, 3x more IOPS free)
  • Don't skip patching — use SSM Patch Manager
```

### S3 Best Practices
```
✅ DO:
  • Enable versioning on ALL buckets
  • Enable server-side encryption (SSE-S3 or SSE-KMS)
  • Block public access (bucket-level + account-level)
  • Use lifecycle policies:
      Standard → IA (30 days) → Glacier (90 days) → Deep Archive (365 days)
  • Enable access logging to a separate bucket
  • Use S3 Intelligent-Tiering for unpredictable access patterns
  • Use VPC Endpoints for private access (saves NAT Gateway costs!)
  • Enable Object Lock for compliance/backup buckets
  • Use prefixes strategically for performance (> 5500 GET/s per prefix)

❌ DON'T:
  • Don't make buckets public unless absolutely necessary
  • Don't store secrets in S3 (use Secrets Manager)
  • Don't skip lifecycle policies (data grows forever!)
  • Don't use bucket names with sensitive info
  • Don't forget to enable versioning BEFORE uploading
```

| S3 Storage Class | Use Case | Cost (us-east-1) | Retrieval |
|-----------------|----------|-------------------|-----------|
| Standard | Frequently accessed | $0.023/GB | Instant |
| Intelligent-Tiering | Unpredictable access | $0.023/GB + $0.0025/1K | Auto-tier |
| Standard-IA | Monthly access | $0.0125/GB | Instant, $0.01/GB retrieval |
| One Zone-IA | Reproducible data | $0.01/GB | Instant |
| Glacier Instant | Quarterly access | $0.004/GB | Milliseconds |
| Glacier Flexible | Annual archives | $0.0036/GB | 1-12 hours |
| Glacier Deep Archive | Compliance/backup | $0.00099/GB | 12-48 hours |

### RDS Best Practices
```
✅ DO:
  • Enable Multi-AZ for production (automatic failover!)
  • Enable automated backups (35 days retention)
  • Use Read Replicas for read-heavy workloads
  • Enable Performance Insights (free for 7 days retention)
  • Use parameter groups for tuning (don't modify default)
  • Enable encryption at rest (can't enable after creation!)
  • Use IAM authentication for application access
  • Set up Enhanced Monitoring (1-second granularity)
  • Use Connection Pooling (RDS Proxy or PgBouncer)
  • Plan maintenance windows during low-traffic hours

❌ DON'T:
  • Don't use db.t3.micro for production (use db.r6g.large minimum)
  • Don't skip Multi-AZ for prod (single-AZ = single point of failure)
  • Don't keep default security group (create specific SG)
  • Don't store DB password in code (use Secrets Manager with rotation!)
  • Don't allow public access unless absolutely necessary
  • Don't skip parameter tuning for PostgreSQL/MySQL
```

### VPC & Networking Best Practices
```
✅ DO:
  • Use /16 CIDR (65K IPs) for production VPCs
  • Spread across 3 AZs minimum
  • Separate public, private, and database subnets:
      Public:   10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
      Private:  10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
      Database: 10.0.21.0/24, 10.0.22.0/24, 10.0.23.0/24
  • Use NAT Gateway in each AZ for HA (not just one!)
  • Enable VPC Flow Logs (send to S3 for cost, CloudWatch for real-time)
  • Use Security Groups (stateful) as primary firewall
  • Use NACLs (stateless) as secondary defense layer
  • Use VPC Endpoints (Gateway: S3, DynamoDB; Interface: others)
  • Plan CIDR ranges for future VPC Peering / Transit Gateway

❌ DON'T:
  • Don't use default VPC for production
  • Don't put databases in public subnets
  • Don't use a single AZ (AZ failure = total outage)
  • Don't use /24 CIDR (only 256 IPs — will run out!)
  • Don't share security groups between environments
```

### VPC Architecture
```
┌──────────────────── Production VPC (10.0.0.0/16) ───────────────────┐
│                                                                      │
│  ┌─── AZ-a ──────────┐ ┌─── AZ-b ──────────┐ ┌─── AZ-c ─────────┐ │
│  │                    │ │                    │ │                    │ │
│  │ Public  10.0.1.0/24│ │ Public  10.0.2.0/24│ │ Public  10.0.3.0/24│ │
│  │ ┌──────────────┐  │ │ ┌──────────────┐  │ │ ┌──────────────┐  │ │
│  │ │ALB, NAT GW   │  │ │ │ALB, NAT GW   │  │ │ │ALB, NAT GW   │  │ │
│  │ └──────────────┘  │ │ └──────────────┘  │ │ └──────────────┘  │ │
│  │                    │ │                    │ │                    │ │
│  │ Private 10.0.11/24│ │ Private 10.0.12/24│ │ Private 10.0.13/24│ │
│  │ ┌──────────────┐  │ │ ┌──────────────┐  │ │ ┌──────────────┐  │ │
│  │ │EKS Nodes     │  │ │ │EKS Nodes     │  │ │ │EKS Nodes     │  │ │
│  │ │EC2, ECS      │  │ │ │EC2, ECS      │  │ │ │EC2, ECS      │  │ │
│  │ └──────────────┘  │ │ └──────────────┘  │ │ └──────────────┘  │ │
│  │                    │ │                    │ │                    │ │
│  │ Database 10.0.21/24│ │Database 10.0.22/24│ │Database 10.0.23/24│ │
│  │ ┌──────────────┐  │ │ ┌──────────────┐  │ │ ┌──────────────┐  │ │
│  │ │RDS Primary   │  │ │ │RDS Standby   │  │ │ │RDS Read Repl │  │ │
│  │ │ElastiCache   │  │ │ │ElastiCache   │  │ │ │              │  │ │
│  │ └──────────────┘  │ │ └──────────────┘  │ │ └──────────────┘  │ │
│  └────────────────────┘ └────────────────────┘ └────────────────────┘ │
│                                                                      │
│  Internet Gateway                    VPC Endpoints (S3, DynamoDB,    │
│  Route Tables (public + private)     ECR, CloudWatch, STS, SSM)      │
└──────────────────────────────────────────────────────────────────────┘
```

### EKS Best Practices
```
✅ DO:
  • Use managed node groups (or Karpenter for auto-provisioning)
  • Use Graviton instances (c7g, m7g) — 40% better cost/performance
  • Enable cluster logging (API server, audit, authenticator)
  • Use IRSA (IAM Roles for Service Accounts) — not node-level roles
  • Enable Pod Security Standards (Restricted by default)
  • Use Network Policies (Calico / Cilium)
  • Use Cluster Autoscaler or Karpenter (prefer Karpenter)
  • Enable EBS CSI driver for persistent volumes (gp3)
  • Run CoreDNS with at least 2 replicas
  • Use Bottlerocket or Amazon Linux 2023 for node AMIs

❌ DON'T:
  • Don't run as root in containers (use securityContext)
  • Don't skip resource requests/limits
  • Don't use default namespace for workloads
  • Don't expose Kubernetes Dashboard to internet
  • Don't use self-managed node groups unless you have a specific reason
  • Don't ignore Kubernetes version upgrades (support window = 14 months)
```

### IAM Best Practices
```
✅ DO:
  • Enable MFA for ALL users (especially root!)
  • Use IAM roles (not access keys) wherever possible
  • Apply least privilege: start with zero permissions, add as needed
  • Use AWS Organizations with SCPs for guardrails
  • Rotate access keys every 90 days (or use temporary credentials)
  • Use IAM Access Analyzer to find unused permissions
  • Tag IAM roles for cost tracking and auditing
  • Use permission boundaries for delegated admin
  • Separate accounts: dev, staging, prod, security, logging

❌ DON'T:
  • Don't use root account for daily operations
  • Don't share IAM users between people
  • Don't use inline policies (use managed policies)
  • Don't use * in resource ARN unless absolutely needed
  • Don't embed access keys in code (use roles + STS)
```

### Lambda Best Practices
```
✅ DO:
  • Keep functions small and single-purpose
  • Use environment variables for configuration
  • Use Lambda Layers for shared dependencies
  • Set appropriate memory (128MB-10GB affects CPU too!)
  • Use Provisioned Concurrency for latency-sensitive functions
  • Use Lambda Power Tuning to find optimal memory size
  • Set reserved concurrency to prevent runaway costs
  • Use X-Ray tracing for debugging
  • Use Dead Letter Queues (DLQ) for failed invocations
  • Use ARM64 (Graviton) runtime — 34% cheaper, 20% faster

❌ DON'T:
  • Don't store state in /tmp (ephemeral!)
  • Don't put Lambda in a VPC unless it needs private resources
  • Don't use 15-minute timeout without good reason
  • Don't log sensitive data (PII, credentials)
  • Don't forget to set a billing alarm for Lambda costs
```

---

## Cost Optimization Strategies

### The FinOps Framework
```
┌──────────────── FinOps = Financial Operations for Cloud ────────────┐
│                                                                      │
│  PHASE 1: INFORM (See what you're spending)                          │
│  ├── Enable Cost Explorer with daily granularity                     │
│  ├── Tag EVERYTHING: Environment, Team, Project, CostCenter          │
│  ├── Set up AWS Budgets with alerts ($$ thresholds)                  │
│  ├── Use Cost Allocation Tags for chargeback                         │
│  └── Weekly cost review meetings                                     │
│                                                                      │
│  PHASE 2: OPTIMIZE (Reduce waste)                                    │
│  ├── Right-size instances (Compute Optimizer recommendations)        │
│  ├── Spot Instances for dev/CI/batch (60-90% savings!)               │
│  ├── Reserved Instances / Savings Plans (up to 72% savings!)         │
│  ├── S3 lifecycle policies (data tiering)                            │
│  ├── Stop idle resources (dev environments off at night)              │
│  ├── Delete zombie resources (unused EBS, old snapshots, idle EIPs)  │
│  └── Use Graviton instances (40% better price/performance)           │
│                                                                      │
│  PHASE 3: OPERATE (Govern continuously)                              │
│  ├── Lambda auto-tagger for untagged resources                       │
│  ├── Automated shutdown schedules (EventBridge + Lambda)             │
│  ├── Quarterly Reserved Instance review                              │
│  ├── Monthly anomaly review (Cost Anomaly Detection)                 │
│  └── FinOps dashboard (Cost Explorer + custom Grafana)               │
└──────────────────────────────────────────────────────────────────────┘
```

### Cost Savings Quick Reference
| Strategy | Savings | Effort | Best For |
|----------|---------|--------|----------|
| Graviton instances | 20-40% | Low (just change instance type) | ALL workloads |
| Spot Instances | 60-90% | Medium (handle interruptions) | Dev, CI/CD, batch |
| Savings Plans (Compute) | 30-72% | Low (1-year or 3-year commit) | Steady-state prod |
| S3 Intelligent-Tiering | 40-70% | Low (enable on bucket) | Unpredictable access |
| NAT Gateway → VPC Endpoints | 50-80% | Low | S3/DynamoDB heavy traffic |
| Stop dev at night | 65% | Medium (automation) | Dev/staging environments |
| Delete zombie EBS | 100% | Low (script it) | Unused volumes/snapshots |
| RDS Reserved | 40-60% | Low (1-year commit) | Production databases |
| gp2 → gp3 migration | 20% | Low (modify volume type) | ALL EBS volumes |

### Automated Cost Optimization Lambda
```python
# cost-optimization/auto-shutdown.py
"""
Auto-shutdown dev environments at 7 PM, restart at 7 AM.
Schedule: EventBridge rule → Lambda
Saves: ~$18,000/year for 20 dev instances
"""
import boto3
from datetime import datetime

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    action = event.get('action', 'stop')  # 'stop' or 'start'
    
    # Find instances tagged Environment=dev or Environment=staging
    filters = [
        {'Name': 'tag:Environment', 'Values': ['dev', 'staging']},
        {'Name': 'tag:AutoShutdown', 'Values': ['true']},
    ]
    
    if action == 'stop':
        filters.append({'Name': 'instance-state-name', 'Values': ['running']})
        instances = get_instance_ids(filters)
        if instances:
            ec2.stop_instances(InstanceIds=instances)
            print(f"Stopped {len(instances)} instances: {instances}")
    
    elif action == 'start':
        filters.append({'Name': 'instance-state-name', 'Values': ['stopped']})
        instances = get_instance_ids(filters)
        if instances:
            ec2.start_instances(InstanceIds=instances)
            print(f"Started {len(instances)} instances: {instances}")
    
    return {'action': action, 'instances': len(instances) if instances else 0}

def get_instance_ids(filters):
    response = ec2.describe_instances(Filters=filters)
    return [
        i['InstanceId']
        for r in response['Reservations']
        for i in r['Instances']
    ]
```

---

## Tagging Strategy

### Mandatory Tags for All Resources
| Tag Key | Example Value | Purpose |
|---------|--------------|---------|
| `Name` | `prod-api-server-01` | Human-readable identifier |
| `Environment` | `prod` / `staging` / `dev` | Environment separation |
| `Team` | `platform` / `data` / `frontend` | Team ownership |
| `Project` | `ecommerce` / `analytics` | Project association |
| `CostCenter` | `CC-1234` | Finance billing |
| `ManagedBy` | `terraform` / `manual` | How it was created |
| `AutoShutdown` | `true` / `false` | Auto-stop eligibility |
| `BackupSchedule` | `daily` / `weekly` | Backup frequency |

### Auto-Tagging Lambda
```python
# tagging/auto-tagger.py
"""
Auto-tag resources when created (triggered by EventBridge).
Ensures NO resource exists without mandatory tags.
"""
import boto3
import json

def lambda_handler(event, context):
    detail = event['detail']
    user = detail.get('userIdentity', {}).get('arn', 'unknown')
    region = event['region']
    service = detail.get('eventSource', '').split('.')[0]
    
    # Default tags for newly created resources
    default_tags = [
        {'Key': 'CreatedBy', 'Value': user},
        {'Key': 'CreatedDate', 'Value': event['time']},
        {'Key': 'ManagedBy', 'Value': 'auto-tagged'},
        {'Key': 'Environment', 'Value': 'UNTAGGED-REVIEW'},
    ]
    
    # Resource-specific tagging
    if service == 'ec2':
        resource_ids = extract_ec2_resources(detail)
        if resource_ids:
            ec2 = boto3.client('ec2', region_name=region)
            ec2.create_tags(Resources=resource_ids, Tags=default_tags)
            print(f"Tagged EC2 resources: {resource_ids}")
    
    elif service == 's3':
        bucket = detail.get('requestParameters', {}).get('bucketName')
        if bucket:
            s3 = boto3.client('s3')
            existing = s3.get_bucket_tagging(Bucket=bucket).get('TagSet', [])
            s3.put_bucket_tagging(
                Bucket=bucket,
                Tagging={'TagSet': existing + default_tags}
            )

def extract_ec2_resources(detail):
    items = detail.get('responseElements', {})
    if 'instancesSet' in items:
        return [i['instanceId'] for i in items['instancesSet']['items']]
    return []
```

---

## Disaster Recovery Strategies

### DR Architecture Tiers
```
┌──────────── DISASTER RECOVERY STRATEGIES (by RTO/RPO) ──────────────┐
│                                                                       │
│  TIER 1: Backup & Restore (RTO: hours, RPO: hours)                   │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Primary Region (us-east-1)     DR Region (us-west-2)        │   │
│  │  ┌──────────┐                   ┌──────────────┐             │   │
│  │  │ Running  │ ──S3 Cross-Region──→│ Backups only │            │   │
│  │  │ Workload │   Replication     │ (cold storage)│            │   │
│  │  └──────────┘                   └──────────────┘             │   │
│  │  Cost: $ (cheapest — only pay for backup storage)             │   │
│  │  Recovery: Launch infra from backups (2-24 hours)             │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  TIER 2: Pilot Light (RTO: 30min-2hr, RPO: minutes)                  │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Primary Region                 DR Region                     │   │
│  │  ┌──────────┐                   ┌──────────────────┐         │   │
│  │  │ Running  │ ──DB Replication──→│ DB running (min) │         │   │
│  │  │ Workload │                   │ App: AMI ready    │         │   │
│  │  └──────────┘                   │ DNS: pre-config   │         │   │
│  │                                  └──────────────────┘         │   │
│  │  Cost: $$ (DB running, minimal compute)                       │   │
│  │  Recovery: Scale up app servers + flip DNS (30-60 min)        │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  TIER 3: Warm Standby (RTO: 10-30min, RPO: seconds)                  │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Primary Region                 DR Region                     │   │
│  │  ┌──────────┐                   ┌──────────────────┐         │   │
│  │  │ Full     │ ──Continuous Repl──→│ Scaled-down copy │         │   │
│  │  │ Workload │                   │ (25% capacity)    │         │   │
│  │  └──────────┘                   └──────────────────┘         │   │
│  │  Cost: $$$ (running at reduced scale)                         │   │
│  │  Recovery: Scale up DR + flip Route53 (10-30 min)             │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  TIER 4: Multi-Region Active-Active (RTO: ~0, RPO: ~0)               │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Region 1 (us-east-1)          Region 2 (eu-west-1)          │   │
│  │  ┌──────────┐                   ┌──────────────────┐         │   │
│  │  │ Full     │ ◀──Global DB──→   │ Full              │        │   │
│  │  │ Workload │   DynamoDB Global  │ Workload          │        │   │
│  │  │          │   Aurora Global    │                    │        │   │
│  │  └──────────┘                   └──────────────────┘         │   │
│  │  Route53 latency-based routing → Users go to closest region  │   │
│  │  Cost: $$$$ (2x everything, but zero downtime)                │   │
│  └────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
```

### Backup Strategy Matrix
| Resource | Backup Method | Frequency | Retention | Cross-Region |
|----------|-------------|-----------|-----------|-------------|
| RDS | Automated snapshots | Daily | 35 days | Yes (cross-region copy) |
| EBS | AWS Backup | Daily | 30 days | Yes |
| S3 | Cross-region replication | Real-time | Lifecycle policy | Yes |
| DynamoDB | Point-in-time + On-demand | Continuous + daily | 35 days | Global Tables |
| EFS | AWS Backup | Daily | 30 days | Yes |
| EKS (etcd) | Velero backup | Every 6 hours | 7 days | Yes (to S3) |
| Secrets Manager | Replicate to DR region | Real-time | N/A | Yes |

---

## Real-Time Project: Production-Grade SaaS Platform

### Project Overview
Build a SaaS application following ALL AWS best practices with complete infrastructure.

### Architecture Diagram
```
┌───────────────── PRODUCTION SaaS PLATFORM ARCHITECTURE ─────────────┐
│                                                                      │
│  ┌─── Global Layer ─────────────────────────────────────────────┐   │
│  │  Route53 (DNS)                                                │   │
│  │  ├── Latency-based routing (us-east-1 ↔ eu-west-1)          │   │
│  │  ├── Health checks (failover automatic)                       │   │
│  │  └── Alias records for CloudFront, ALB                        │   │
│  │                                                                │   │
│  │  CloudFront (CDN)                                             │   │
│  │  ├── S3 origin (static assets: React app, images)             │   │
│  │  ├── ALB origin (dynamic API requests)                        │   │
│  │  ├── WAF attached (OWASP Top 10 rules)                       │   │
│  │  └── SSL certificate (ACM us-east-1)                          │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── Primary Region (us-east-1) ───────────────────────────────┐   │
│  │                                                                │   │
│  │  VPC (10.0.0.0/16) — 3 AZs                                   │   │
│  │  ┌─── Public Subnets ──────────────────────────────────────┐  │   │
│  │  │  ALB (Application Load Balancer)                         │  │   │
│  │  │  NAT Gateway (one per AZ for HA)                         │  │   │
│  │  │  Bastion Host (or SSM — no bastion needed!)              │  │   │
│  │  └─────────────────────────────┬────────────────────────────┘  │   │
│  │                                │                               │   │
│  │  ┌─── Private Subnets ────────┴────────────────────────────┐  │   │
│  │  │                                                          │  │   │
│  │  │  EKS Cluster (Kubernetes)                                │  │   │
│  │  │  ├── Namespace: production                               │  │   │
│  │  │  │   ├── API Gateway (5 pods, HPA)                      │  │   │
│  │  │  │   ├── Auth Service (3 pods)                           │  │   │
│  │  │  │   ├── User Service (3 pods)                           │  │   │
│  │  │  │   ├── Billing Service (3 pods)                        │  │   │
│  │  │  │   ├── Notification Service (2 pods)                   │  │   │
│  │  │  │   └── Background Workers (Spot instances!)            │  │   │
│  │  │  │                                                       │  │   │
│  │  │  ├── Namespace: monitoring                               │  │   │
│  │  │  │   ├── Prometheus + Grafana + AlertManager             │  │   │
│  │  │  │   ├── Loki + Promtail (logging)                       │  │   │
│  │  │  │   └── Tempo (tracing)                                 │  │   │
│  │  │  │                                                       │  │   │
│  │  │  ├── Karpenter (auto-provision nodes)                    │  │   │
│  │  │  ├── External-DNS (auto Route53)                         │  │   │
│  │  │  ├── cert-manager (auto TLS)                             │  │   │
│  │  │  └── AWS Load Balancer Controller                        │  │   │
│  │  │                                                          │  │   │
│  │  │  SQS Queues (async processing)                           │  │   │
│  │  │  ├── email-queue (send welcome/receipt emails)           │  │   │
│  │  │  ├── billing-queue (process payments async)              │  │   │
│  │  │  └── notification-queue (push notifications)             │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │  ┌─── Database Subnets ────────────────────────────────────┐  │   │
│  │  │  RDS PostgreSQL (Multi-AZ + Read Replica)               │  │   │
│  │  │  ├── Primary: db.r6g.xlarge (writer)                    │  │   │
│  │  │  ├── Standby: auto-failover (different AZ)              │  │   │
│  │  │  └── Read Replica: read-heavy queries                   │  │   │
│  │  │                                                          │  │   │
│  │  │  ElastiCache Redis (Multi-AZ, cluster mode)             │  │   │
│  │  │  ├── Session storage                                     │  │   │
│  │  │  ├── API response caching                                │  │   │
│  │  │  └── Rate limiting                                       │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── Security Layer ───────────────────────────────────────────┐   │
│  │  WAF (OWASP rules + rate limiting + geo-blocking)             │   │
│  │  GuardDuty (threat detection)                                 │   │
│  │  Security Hub (compliance dashboard)                          │   │
│  │  CloudTrail (API audit logging → S3 + CloudWatch)             │   │
│  │  Secrets Manager (DB passwords, API keys — auto-rotation)     │   │
│  │  KMS (encryption keys for RDS, S3, EBS)                       │   │
│  │  IAM (IRSA for pods, least privilege policies)                │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── CI/CD Pipeline ───────────────────────────────────────────┐   │
│  │  GitHub → GitHub Actions (OIDC auth to AWS) →                 │   │
│  │  Build → SonarQube (SAST) → Trivy (container scan) →         │   │
│  │  Push to ECR → Update EKS (kubectl/ArgoCD) →                  │   │
│  │  Canary deployment (10% → 50% → 100%) →                       │   │
│  │  Slack notification                                            │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── Observability ────────────────────────────────────────────┐   │
│  │  Metrics: Prometheus → Grafana (RED dashboards, SLO tracking) │   │
│  │  Logs: Promtail → Loki → Grafana (LogQL queries)              │   │
│  │  Traces: OpenTelemetry → Tempo → Grafana (trace explorer)     │   │
│  │  Alerts: AlertManager → Slack + PagerDuty                     │   │
│  │  AWS: CloudWatch Container Insights + RDS Performance Insights│   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

### Terraform Module Structure
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars    # dev-specific values
│   │   └── backend.tf          # dev state in S3
│   ├── staging/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── vpc/                    # VPC + subnets + NAT + endpoints
│   ├── eks/                    # EKS cluster + node groups
│   ├── rds/                    # RDS PostgreSQL + Multi-AZ
│   ├── elasticache/            # Redis cluster
│   ├── alb/                    # ALB + target groups
│   ├── s3/                     # Buckets with policies
│   ├── cloudfront/             # CDN distribution
│   ├── waf/                    # WAF rules
│   ├── monitoring/             # CloudWatch alarms + dashboards
│   ├── security/               # GuardDuty + Security Hub setup
│   └── iam/                    # Roles + policies
└── global/
    ├── route53.tf              # DNS zones
    ├── acm.tf                  # SSL certificates
    ├── ecr.tf                  # Container registries
    └── s3-state.tf             # Terraform state bucket
```

### Infrastructure Cost Estimation
| Resource | Spec | Monthly Cost |
|----------|------|-------------|
| EKS Cluster | Control plane | $73 |
| EC2 Worker Nodes | 3x m7g.xlarge (Graviton) | $330 |
| EC2 Spot Workers | 2x m7g.xlarge (batch jobs) | $70 |
| RDS PostgreSQL | db.r6g.xlarge Multi-AZ | $540 |
| ElastiCache Redis | cache.r6g.large 2-node | $260 |
| ALB | Application LB + LCUs | $50 |
| NAT Gateway | 3x (one per AZ) | $100 |
| S3 | 500GB + requests | $15 |
| CloudFront | 1TB transfer | $85 |
| Route53 | Hosted zone + queries | $5 |
| CloudWatch | Metrics + Logs + Alarms | $80 |
| Secrets Manager | 20 secrets | $8 |
| ECR | Container images | $10 |
| **TOTAL (On-Demand)** | | **~$1,626/mo** |
| **With Savings Plans** | 1-year, no upfront | **~$1,050/mo** |
| **With Spot + Graviton** | Optimized | **~$850/mo** |

---

## Security Checklist for Production

### Pre-Launch Security Audit
```
ACCOUNT LEVEL:
  □ MFA enabled on root account
  □ Root account alarm (CloudWatch → SNS)
  □ AWS Organizations with SCPs
  □ CloudTrail enabled (all regions, all services)
  □ GuardDuty enabled in all regions
  □ Security Hub enabled with CIS benchmarks
  □ Config rules for compliance monitoring
  □ IAM Access Analyzer enabled

NETWORK LEVEL:
  □ No security groups with 0.0.0.0/0 for SSH/RDP
  □ VPC Flow Logs enabled
  □ NAT Gateway (not NAT instance)
  □ VPC Endpoints for AWS services
  □ WAF on all public-facing ALBs/CloudFront
  □ NACLs as defense-in-depth layer
  □ Private subnets for all workloads

DATA LEVEL:
  □ S3 Block Public Access (account-level)
  □ EBS default encryption enabled (account-level)
  □ RDS encryption at rest enabled
  □ KMS keys with key rotation
  □ Secrets Manager (not SSM Parameter Store for secrets)
  □ Secrets auto-rotation enabled
  □ S3 versioning + Object Lock for backups

APPLICATION LEVEL:
  □ Container images scanned (Trivy/Snyk)
  □ No secrets in code (git-secrets pre-commit hook)
  □ HTTPS everywhere (ACM certificates)
  □ IMDSv2 required on all EC2 instances
  □ Pod Security Standards enforced (EKS)
  □ IRSA for pod-level AWS access (not node roles)
  □ Network Policies between namespaces
```

---

## Deliverables
- [ ] Well-Architected Review checklist completed
- [ ] VPC architecture with 3-AZ, public/private/database subnets
- [ ] Terraform modules for all infrastructure components
- [ ] Cost optimization report with savings recommendations
- [ ] Tagging strategy implemented with auto-tagger Lambda
- [ ] Backup and DR plan document with tested restore
- [ ] Security audit checklist all-green
- [ ] Production SaaS platform deployed and functional
- [ ] Monitoring stack (PLG) with custom dashboards
- [ ] CI/CD pipeline with security scanning gates
- [ ] Cost breakdown vs. optimization estimates
- [ ] FinOps automation (auto-shutdown, zombie cleanup)
- [ ] Architecture diagrams for presentation/portfolio
