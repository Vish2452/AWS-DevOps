# DevOps by Doing — AWS DevOps Bootcamp (2026 Edition)

> *Real pipelines. Real infrastructure. Real projects.*

> **Goal:** End-to-end hands-on training with **real-time projects per topic**.
> **Duration:** ~18–22 weeks (adjustable).
> **Approach:** Each module ends with a deployable project; projects build on each other so that by the end the trainee has a **production-grade portfolio**.
> **Philosophy:** Learn by building — no passive lectures, every concept is practiced on live AWS infrastructure.

---

## Repository Structure

```
AWS-DevOps/
├── 01-Linux-Fundamentals/          # Linux basics + 200 commands + EC2 hardening project
├── 02-Shell-Scripting/             # Bash scripting + 15 production scripts + cost optimization project
├── 03-Git-GitHub/                  # Git internals, GitFlow, SemVer + team simulation project
├── 04-AWS-Core-Services/           # IAM, S3, EC2, VPC, RDS, Route53, Lambda, CloudWatch...
│   ├── IAM/                        #   Identity & Access Management
│   ├── S3/                         #   Simple Storage Service
│   ├── EC2/                        #   Elastic Compute Cloud
│   ├── EBS/                        #   Elastic Block Store
│   ├── EFS/                        #   Elastic File System
│   ├── VPC/                        #   Virtual Private Cloud
│   ├── ELB/                        #   Elastic Load Balancing (ALB, NLB, GLB)
│   ├── ASG/                        #   Auto Scaling Groups
│   ├── RDS/                        #   Relational Database Service
│   ├── Route53/                    #   DNS & Domain Management
│   ├── Lambda/                     #   Serverless Compute
│   ├── CloudWatch/                 #   Monitoring & Logging
│   ├── SNS/                        #   Simple Notification Service
│   ├── CloudFront/                 #   CDN
│   ├── CloudTrail/                 #   API Audit Logging
│   ├── KMS/                        #   Key Management Service
│   ├── AWS-Backup/                 #   Centralized Backup
│   ├── AWS-Migration/              #   DMS, MGN, DataSync, Migration Hub, 6 Rs
│   ├── CloudFormation/             #   AWS-native IaC (stacks, change sets, drift)
│   ├── CodePipeline/               #   AWS CI/CD: CodeCommit, CodeBuild, CodeDeploy
│   ├── Elastic-Beanstalk/          #   PaaS deployment (platforms, .ebextensions)
│   ├── OpsWorks/                   #   Config management as a service (Chef, Puppet)
│   ├── Redshift/                   #   Data Warehousing (columnar, Spectrum, Serverless)
│   ├── SES/                        #   Simple Email Service (SMTP, DKIM, templates)
│   ├── Snowball/                   #   Snow Family physical data transfer & edge
│   ├── Storage-Gateway/            #   Hybrid cloud storage (File, Volume, Tape)
│   ├── scenarios/                  #   21 practical AWS scenarios
│   └── project-3tier-web-app/      #   Real-time: Scalable 3-Tier Web App
├── 05-AWS-Advanced-Networking/     # Transit Gateway, VPC Peering, VPN + multi-region project
├── 06-Docker/                      # Containers, Compose, multi-stage builds + voting app project
├── 07-Jenkins-CICD/                # Pipelines, plugins, agents + Java microservice project
│   └── continuous-testing/         #   Maven, Selenium, headless browser testing
├── 08-GitHub-Actions-CICD/         # Workflows, OIDC, runners + full CI/CD project
├── 09-Terraform/                   # IaC, modules, state, workspaces + multi-env project
├── 09A-Liquibase/                  # DB migrations, changelogs, rollback + RDS pipeline project
├── 10-Kubernetes/                  # EKS, deployments, services, RBAC + production cluster project
├── 11-Monitoring-Observability/    # Prometheus, Grafana, EFK + full observability project
│   └── nagios/                     #   Nagios monitoring, NRPE plugins, service checks
├── 12-Security-DevSecOps/          # SonarQube, Trivy, Checkov, Vault + DevSecOps pipeline project
├── 13-Lambda-Glue-Data-Infra/     # Serverless ETL, Step Functions + data pipeline project
├── 14-Capstone-Projects/          # CDP, Banking, E-Commerce, IoT — pick one
│   ├── option-a-cdp/
│   ├── option-b-banking/
│   ├── option-c-ecommerce-eks/
│   └── option-d-iot-analytics/
├── 15-AWS-ECS/                    # ECS Fargate, microservices, service discovery + 2-tier app
├── 16-Python-for-DevOps/          # boto3, Lambda, FinOps, ClamAV + automation projects
├── 17-Ansible-Packer/             # Ansible roles, Vault, Packer golden AMI + CI/CD pipeline
│   └── puppet-basics/             #   Puppet master-agent, manifests, modules, file server
├── 18-AIOps/                      # AI tools, anomaly detection, self-healing + ChatOps
├── 19-SRE-Incident-Management/    # SLI/SLO, error budgets, war rooms, postmortems, chaos engineering
├── 20-AWS-Best-Practices/         # Well-Architected, FinOps, DR, security hardening, production project
└── AWS-DevSecOps/                 # GuardDuty, Security Hub, SCPs, Landing Zone, Config, Inspector
```

---

## Training Roadmap — Module Overview

| # | Module | Duration | Real-Time Project |
|---|--------|----------|-------------------|
| 1 | [Linux Fundamentals](01-Linux-Fundamentals/) | 1 week | Server hardening & automation on EC2 |
| 2 | [Shell Scripting](02-Shell-Scripting/) | 1 week | 15 production scripts (backup, monitoring, deploy) |
| 3 | [Git & GitHub](03-Git-GitHub/) | 1 week | Team GitFlow simulation with PR reviews |
| 4 | [AWS Core Services](04-AWS-Core-Services/) | 3 weeks | Scalable 3-tier web app on AWS |
| 5 | [AWS Advanced Networking](05-AWS-Advanced-Networking/) | 2 weeks | Multi-Region VPC with Transit Gateway |
| 6 | [Docker](06-Docker/) | 1.5 weeks | Microservices voting app with Trivy scanning |
| 7 | [Jenkins CI/CD](07-Jenkins-CICD/) | 1.5 weeks | Full pipeline: build → test → scan → deploy |
| 8 | [GitHub Actions CI/CD](08-GitHub-Actions-CICD/) | 1 week | OIDC-based Terraform + app deployment |
| 9 | [Terraform (IaC)](09-Terraform/) | 2 weeks | Multi-env infra with modules & remote state |
| 9A | [Liquibase (DB Migrations)](09A-Liquibase/) | 1 week | RDS schema CI/CD with GitHub Actions |
| 10 | [Kubernetes](10-Kubernetes/) | 3 weeks | Production EKS cluster with monitoring |
| 11 | [Monitoring & Observability](11-Monitoring-Observability/) | 2 weeks | Full PLG stack + CloudWatch + E-Commerce monitoring |
| 12 | [Security & Compliance](12-Security-DevSecOps/) | 0.5 week | DevSecOps pipeline with SonarQube + Trivy |
| 13 | [Lambda + Glue + Data Infra](13-Lambda-Glue-Data-Infra/) | 1.5 weeks | Serverless ETL pipeline + Data Lake |
| 14 | [Capstone Projects](14-Capstone-Projects/) | 1.5 weeks | CDP / E-Commerce / Banking / IoT (pick one) |
| 15 | [AWS ECS](15-AWS-ECS/) | 2 weeks | Production ECS with Terraform + microservices |
| 16 | [Python for DevOps](16-Python-for-DevOps/) | 3 weeks | Lambda automations + FinOps + ClamAV scanning |
| 17 | [Ansible & Packer](17-Ansible-Packer/) | 1 week | Golden AMI pipeline with GitHub Actions |
| 18 | [AIOps](18-AIOps/) | 2 weeks | AI anomaly detection + self-healing infra |
| 19 | [SRE & Incidents](19-SRE-Incident-Management/) | 2 weeks | SLI/SLO dashboards + war room + chaos engineering |
| 20 | [AWS Best Practices](20-AWS-Best-Practices/) | 2 weeks | Production SaaS platform + FinOps + DR strategy |
| — | [AWS DevSecOps](AWS-DevSecOps/) | Reference | GuardDuty, Security Hub, SCPs, Landing Zone |

---

## Real-Time Project Portfolio Summary

| # | Project | Key Services | Interview Value |
|---|---------|-------------|----------------|
| 1 | Server Hardening Script | Linux, SSH, iptables | Shows Linux depth |
| 2 | AWS Cost Optimization Script | Shell, AWS CLI, SNS | FinOps is hot |
| 3 | GitFlow Team Simulation | Git, GitHub, PRs, SemVer | Collaboration proof |
| 4 | Scalable 3-Tier Web App | VPC, ALB, ASG, RDS, S3 | Core AWS competency |
| 5 | Multi-Region VPC Network | Transit GW, VPC, VPN | Networking expertise |
| 6 | Docker Voting App + Trivy | Docker, Compose, ECR | Container skills |
| 7 | Jenkins Java Pipeline | Jenkins, SonarQube, ECR | CI/CD pipeline design |
| 8 | GitHub Actions CI/CD | GH Actions, OIDC, Terraform | Modern CI/CD |
| 9 | Terraform Multi-Env Infra | Terraform, S3, modules | IaC mastery |
| 9A | Liquibase RDS Pipeline | Liquibase, RDS, GH Actions | DB-as-Code (unique skill!) |
| 10 | Production EKS Cluster | EKS, Helm, Ingress, HPA | K8s production readiness |
| 11 | Observability Stack | Prometheus, Grafana, Loki, Tempo | Full PLG monitoring |
| 12 | DevSecOps Pipeline | Trivy, SonarQube, Checkov | Security-first mindset |
| 13 | Serverless Data Pipeline | Lambda, Glue, Step Functions | DataOps + Serverless |
| 14 | CDP / Banking / E-Commerce / IoT | Full stack (15+ services) | Capstone portfolio piece |
| 15 | Production ECS + Microservices | ECS, Fargate, Terraform, ALB | Container orchestration |
| 16 | Python AWS Automations | Lambda, boto3, SES, ClamAV | Automation engineering |
| 17 | Golden AMI Pipeline | Ansible, Packer, GitHub Actions | Config management |
| 18 | AIOps Platform | Bedrock, CloudWatch ML, Lambda | AI-powered operations |
| 19 | War Room Simulation | Prometheus, Grafana, SLO | SRE credibility |
| 20 | Production SaaS Platform | EKS, RDS, CloudFront, WAF | AWS best practices |
| — | AWS Security Automation | GuardDuty, Security Hub, SCPs | Enterprise security |

---

## Weekly Schedule Template

| Day | Activity | Hours |
|-----|----------|-------|
| Mon-Fri | Theory + Hands-on Labs | 2-3 hrs/day |
| Sat | Real-Time Project Work | 4-5 hrs |
| Sun | Review + Interview Q&A Practice | 2-3 hrs |

---

## Tools Setup Checklist

- [ ] AWS Free Tier account (or training account)
- [ ] GitHub account with Actions enabled
- [ ] VS Code + extensions (Docker, Terraform, YAML, K8s, Liquibase)
- [ ] Docker Desktop (or Rancher Desktop)
- [ ] Terraform CLI installed
- [ ] kubectl + eksctl installed
- [ ] AWS CLI v2 configured
- [ ] Minikube or kind for local K8s
- [ ] Jenkins (Docker container for lab use)
- [ ] Helm CLI installed
- [ ] Liquibase CLI installed
- [ ] PostgreSQL client (`psql`) installed
- [ ] Python 3.10+ (for Glue scripts, Lambda functions)
- [ ] SAM CLI (for local Lambda testing)
- [ ] AWS Glue local development container (Docker)
- [ ] Ansible CLI (`pip install ansible`)
- [ ] Packer CLI installed
- [ ] SonarQube (Docker container for lab use)
- [ ] Trivy CLI installed

---

## Recommended Certifications

- **AWS Solutions Architect Associate (SAA-C03)** — foundational
- **AWS Developer Associate (DVA-C02)** — CI/CD focus
- **AWS DevOps Engineer Professional (DOP-C02)** — ultimate goal
- **CKA (Certified Kubernetes Administrator)** — K8s credibility
- **Terraform Associate (003)** — IaC validation
- **GitHub Actions Certification** — newest, high value

---

*Generated: February 2026 | AWS DevOps Bootcamp with real-time industry projects*