# Module 4 — AWS Core Services (4 Weeks)

> **Objective:** Master the foundational AWS services that every DevOps engineer uses daily. Build a scalable 3-tier web application.

---

## 🌍 Real-World Analogy: AWS is Like a Shopping Mall

Think of AWS as a **giant shopping mall** where you rent exactly what you need:

```
🏬 AWS = THE MEGA MALL
│
├── 🏠 EC2 = Renting an office/shop space
│   You rent a room (server), furnish it (install software), run your business.
│   Need more space? Rent a bigger room (scale up). Need 10 rooms? No problem.
│
├── 📦 S3 = Storage lockers (infinite)
│   Like a self-storage facility with unlimited lockers.
│   Store photos, videos, backups — pay only for what you use.
│   Cheap, durable, accessible from anywhere.
│
├── 🔐 IAM = Building security & key cards
│   "Alice can enter floors 1-3 but not floor 4"
│   "Bob can only access the cafeteria during lunch hours"
│   Controls WHO can do WHAT in your AWS account.
│
├── 🌐 VPC = Your private floor in the mall
│   Walls, doors, corridors that only YOU control.
│   You decide who enters (security groups) and how rooms connect.
│
├── ⚖️ ELB = Mall information desk
│   100 customers arrive → Receptionist sends 50 to Shop A, 50 to Shop B
│   If Shop A is full, ALL customers go to Shop B (health checks!)
│
├── 📊 ASG = Automatic room management
│   "If more than 100 customers waiting, open another shop automatically"
│   "If it's midnight and shops are empty, close the extra ones"
│   Saves money by scaling up AND down.
│
├── 🗄️ RDS = Professional file cabinet service
│   Instead of managing your own filing system, hire a professional.
│   They handle organization, backups, copies, and disaster recovery.
│   You just say "store this" and "find that".
│
├── 🗺️ Route53 = The mall directory sign
│   "Looking for Pizza Hut? → Floor 3, Shop 302"
│   Translates "www.myapp.com" into the actual server address.
│
├── ⚡ Lambda = Vending machine
│   No employee needed! Customer presses button → gets snack → pays per use.
│   No customers? Machine uses ZERO electricity (you pay nothing).
│
├── 👁️ CloudWatch = Security cameras + alarms
│   Watches everything. "If the fire alarm triggers, call 911."
│   "If CPU > 80%, send a text to the engineer."
│
└── 📢 SNS = Mall PA system (announcement speaker)
    "Attention: Server is down!" → Sends to Slack, Email, SMS simultaneously.
```

### How They Work Together (Real Architecture)
```
User types www.myapp.com
        │
    Route53 (DNS) ─── "That's server 54.23.1.100"
        │
    CloudFront (CDN) ─── Serves cached images/CSS (fast!)
        │
    ELB (Load Balancer) ─── Distributes to healthy servers
        │
   ┌────┴────┐
   EC2    EC2    ← ASG adds more servers during peak
   │       │
   └───┬───┘
       │
   RDS (Database) ← Multi-AZ: automatic backup in another building
       │
   S3 (Storage) ← Photos, uploads, static files
       │
   CloudWatch ← Monitoring everything, alerts via SNS
```

---

## Structure

### Week 1: Compute, Storage & Identity
| Service | Folder | Key Topics |
|---------|--------|------------|
| [IAM](IAM/) | Identity & Access Management | Users, roles, policies, OIDC, SSO |
| [S3](S3/) | Simple Storage Service | Storage classes, lifecycle, replication |
| [EC2](EC2/) | Elastic Compute Cloud | Instance types, AMIs, user data |
| [EBS](EBS/) | Elastic Block Store | Volume types, snapshots, encryption |
| [EFS](EFS/) | Elastic File System | Shared NFS storage |
| [AWS-Backup](AWS-Backup/) | Centralized Backup | Backup plans, vaults, cross-region |

### Week 2: Networking, Load Balancing & Auto Scaling
| Service | Folder | Key Topics |
|---------|--------|------------|
| [VPC](VPC/) | Virtual Private Cloud | Subnets, NAT, endpoints, flow logs |
| [ELB](ELB/) | Elastic Load Balancing | ALB, NLB, GLB, health checks |
| [ASG](ASG/) | Auto Scaling Groups | Launch templates, scaling policies |

### Week 3: Database, DNS, Serverless & Monitoring
| Service | Folder | Key Topics |
|---------|--------|------------|
| [RDS](RDS/) | Relational Database Service | Multi-AZ, read replicas, Aurora |
| [DynamoDB](DynamoDB/) | NoSQL Database | Partition keys, GSI, Streams, TTL |
| [ElastiCache](ElastiCache/) | In-Memory Cache | Redis vs Memcached, session store |
| [Route53](Route53/) | DNS & Domain Management | Routing policies, health checks |
| [Lambda](Lambda/) | Serverless Compute | Triggers, layers, concurrency |
| [API-Gateway](API-Gateway/) | API Management | REST, HTTP, WebSocket APIs |
| [SQS](SQS/) | Simple Queue Service | Standard vs FIFO, DLQ, scaling |
| [SNS](SNS/) | Simple Notification Service | Topics, subscriptions, fan-out |
| [EventBridge](EventBridge/) | Event Bus | Rules, scheduling, cross-account |
| [CloudWatch](CloudWatch/) | Monitoring & Logging | Metrics, alarms, dashboards |
| [CloudFront](CloudFront/) | CDN | Distributions, caching, invalidation |
| [CloudTrail](CloudTrail/) | API Audit Logging | Event history, S3 storage |

### Week 4: Security, Compliance & Operations
| Service | Folder | Key Topics |
|---------|--------|------------|
| [KMS](KMS/) | Key Management Service | CMK, envelope encryption |
| [Secrets-Manager](Secrets-Manager/) | Secrets Management | Auto-rotation, cross-account |
| [WAF](WAF/) | Web Application Firewall | Rules, rate limiting, Shield |
| [AWS-Config](AWS-Config/) | Compliance & Audit | Config rules, auto-remediation |
| [STS](STS/) | Security Token Service | AssumeRole, federation, temp creds |
| [ECR](ECR/) | Container Registry | Image scanning, lifecycle policies |
| [Systems-Manager](Systems-Manager/) | Operations Hub | Session Manager, patching, Parameter Store |

### Additional Services
| Service | Folder | Key Topics |
|---------|--------|------------|
| [CloudFormation](CloudFormation/) | AWS-Native IaC | Stacks, nested stacks, change sets, drift detection |
| [CodePipeline](CodePipeline/) | AWS CI/CD Suite | CodeCommit, CodeBuild, CodeDeploy, CodePipeline |
| [Elastic-Beanstalk](Elastic-Beanstalk/) | PaaS Deployment | Platforms, .ebextensions, deployment policies |
| [OpsWorks](OpsWorks/) | Config Management | Chef Automate, Puppet Enterprise, Stacks |
| [Redshift](Redshift/) | Data Warehousing | Columnar storage, Spectrum, Serverless |
| [SES](SES/) | Email Service | SMTP/API, DKIM/SPF/DMARC, templates |
| [Snowball](Snowball/) | Physical Data Transfer | Snow Family, edge computing, OpsHub |
| [Storage-Gateway](Storage-Gateway/) | Hybrid Storage | S3 File Gateway, Volume Gateway, Tape Gateway |
| [AWS-Migration](AWS-Migration/) | Cloud Migration | DMS, MGN, SCT, DataSync, 6 Rs, Migration Hub |

---

## 21 Practical AWS Scenarios

**[📁 Scenarios Folder →](scenarios/)**

| # | Scenario | Services |
|---|----------|----------|
| 1 | Automated cross-region backup | AWS Backup, S3, RDS Snapshots |
| 2 | AWS cost optimization | Cost Explorer, Trusted Advisor |
| 3 | Bastion Host setup | EC2, VPC, Security Groups |
| 4 | Cross-account EC2 to RDS | VPC Peering, IAM Role Switching |
| 5 | Scalable NLB with Route53 & SSL | NLB, ASG, ACM, Route 53 |
| 6 | VPN Gateway vs Direct Connect | VPN, comparison |
| 7 | EBS vs EFS shared storage | EBS, EFS, EC2 |
| 8 | ECR + ECS container deploy | ECR, ECS Fargate, ALB |
| 9 | Serverless banking app | API Gateway, Lambda, DynamoDB |
| 10 | Private vs public IP demo | VPC, EC2 |
| 11 | IAM policy design | IAM, S3, policy simulator |
| 12 | IAM role switching | IAM, STS, Organizations |
| 13 | KMS encryption demo | KMS, S3, EBS |
| 14 | Multi-Region Transit Gateway | Transit Gateway, VPC |
| 15 | NAT Gateway setup | VPC, NAT-GW, private subnets |
| 16 | VPC Flow Logs analysis | VPC, CloudWatch, Athena |
| 17 | VPC Endpoints for S3 | VPC, Gateway Endpoint |
| 18 | Static website S3+CloudFront | S3, CloudFront, Route 53, ACM |
| 19 | IP ranges & CIDR design | VPC, subnets |
| 20 | S3 bucket policy access control | IAM, S3 Bucket Policy |
| 21 | ASG with SNS notifications | ASG, SNS, CloudWatch |

---

## Real-Time Project: Scalable 3-Tier Web Application on AWS

**[📁 Project Folder →](project-3tier-web-app/)**

### Architecture
```
Route 53 → CloudFront → ALB → ASG (EC2) → RDS Multi-AZ
                                 ↕
              S3 (static assets) + EFS (shared files)

VPC: Public/Private subnets, NAT Gateway, Bastion Host
Security: IAM roles, KMS encryption, Security Groups
Monitoring: CloudWatch Alarms + SNS Notifications
Backup: AWS Backup automated schedules
```

### Deliverables
- Fully deployed, auto-scaling, monitored web application
- Documented architecture diagram
- Security audit passed
