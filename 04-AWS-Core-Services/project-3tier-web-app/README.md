# Real-Time Project: Scalable 3-Tier Web Application on AWS

> **Industry Context:** This is the most common AWS architecture pattern. Every DevOps interview will ask you to design or deploy a 3-tier application.

## Architecture

```
                        ┌────────────────┐
                        │   Route 53     │
                        │  (DNS)         │
                        └───────┬────────┘
                                │
                        ┌───────▼────────┐
                        │  CloudFront    │
                        │  (CDN + SSL)   │
                        └───────┬────────┘
                                │
┌───────────────────────────────▼────────────────────────────────┐
│                     VPC: 10.0.0.0/16                           │
│                                                                │
│  ┌─────────────────┐           ┌─────────────────┐            │
│  │ Public Subnet    │           │ Public Subnet    │            │
│  │ 10.0.1.0/24     │           │ 10.0.2.0/24     │            │
│  │   ┌──────────┐  │           │   ┌──────────┐  │            │
│  │   │ Bastion  │  │           │   │ NAT GW   │  │            │
│  │   └──────────┘  │           │   └──────────┘  │            │
│  └─────────────────┘           └─────────────────┘            │
│              ┌─────────────────────────────────┐               │
│              │     Application Load Balancer    │               │
│              └─────────────────┬───────────────┘               │
│                                │                               │
│  ┌─────────────────┐           │           ┌─────────────────┐│
│  │ Private Subnet   │           │           │ Private Subnet   ││
│  │ 10.0.10.0/24    │           │           │ 10.0.20.0/24    ││
│  │  ┌──────────┐   │           │           │  ┌──────────┐   ││
│  │  │ EC2 (ASG)│   │◄──────────┘ ──────────►│ EC2 (ASG)│   ││
│  │  └──────────┘   │                        │  └──────────┘   ││
│  │       │ EFS     │                        │       │ EFS     ││
│  └───────┼─────────┘                        └───────┼─────────┘│
│          │                                          │          │
│  ┌───────▼──────────┐           ┌───────────▼──────────┐      │
│  │ DB Subnet         │           │ DB Subnet            │      │
│  │ 10.0.100.0/24    │           │ 10.0.200.0/24        │      │
│  │  ┌──────────┐    │           │  ┌──────────┐        │      │
│  │  │ RDS      │    │◄─────────►│  │ RDS      │        │      │
│  │  │ Primary  │    │  Multi-AZ │  │ Standby  │        │      │
│  │  └──────────┘    │           │  └──────────┘        │      │
│  └──────────────────┘           └──────────────────────┘      │
│                                                                │
│  S3: Static assets          KMS: Encryption                   │
│  CloudWatch: Monitoring     SNS: Alerts                       │
│  AWS Backup: Automated      IAM: Least privilege              │
└────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
project-3tier-web-app/
├── README.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── modules/
│   │   ├── vpc/
│   │   ├── alb/
│   │   ├── asg/
│   │   ├── rds/
│   │   ├── s3/
│   │   ├── cloudfront/
│   │   └── monitoring/
│   └── environments/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
├── app/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── index.html
│   └── api/
└── docs/
    └── architecture-diagram.md
```

## Implementation Steps

### Step 1: VPC & Networking
```hcl
# terraform/modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "${var.project}-private-${count.index + 1}" }
}
```

### Step 2: ALB + ASG
```hcl
resource "aws_lb" "app" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-asg"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

### Step 3: RDS Multi-AZ
```hcl
resource "aws_db_instance" "main" {
  identifier           = "${var.project}-db"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.medium"
  allocated_storage    = 100
  storage_type         = "gp3"
  multi_az             = true
  storage_encrypted    = true
  kms_key_id          = aws_kms_key.rds.arn
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
}
```

### Step 4: Monitoring & Alerts
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = 80
  alarm_actions      = [aws_sns_topic.alerts.arn]
}
```

## Deliverables
- [ ] VPC with public/private/DB subnets across 2 AZs
- [ ] ALB with HTTPS (ACM certificate)
- [ ] ASG with target tracking scaling (CPU 50%)
- [ ] RDS PostgreSQL Multi-AZ with encryption
- [ ] S3 for static assets + CloudFront CDN
- [ ] EFS for shared application files
- [ ] CloudWatch alarms + SNS email notifications
- [ ] AWS Backup daily schedule
- [ ] Bastion host or Session Manager access
- [ ] IAM roles with least privilege
- [ ] Full Terraform code with modules
