# Module 9 — Terraform (IaC) (2 Weeks)

> **Objective:** Master Infrastructure as Code with Terraform. Build reusable modules and deploy multi-environment infrastructure.

---

## 🏗️ Real-World Analogy: Terraform is Like an Architect's Blueprint

Imagine building a house **without blueprints** vs. **with blueprints**:

```
🙅 WITHOUT TERRAFORM (Clicking in AWS Console = No Blueprint!):

  Engineer: "I'll click through the AWS Console to create:
    - 1 VPC... click, click, click
    - 3 subnets... click, click, click
    - 2 EC2 servers... click, click, click
    - 1 database... click, click, click"

  Problems:
    ❌ Forgot what I clicked 3 months ago
    ❌ Can't recreate the same setup for staging/prod
    ❌ New team member: "How was this built?" 🤷
    ❌ Disaster recovery: rebuild from memory? 😱


📐 WITH TERRAFORM (Blueprint = Code!):

  ┌──────────────────────────────────────────┐
  │  main.tf (Your Blueprint)              │
  │                                          │
  │  "I want:                                │
  │    - 1 VPC (10.0.0.0/16)                 │
  │    - 3 subnets (public + private)         │
  │    - 2 EC2 servers (t3.medium)            │
  │    - 1 RDS database (PostgreSQL)"         │
  └────────────────────┬─────────────────────┘
                       │
       terraform apply ▼
  ┌──────────────────────────────────────────┐
  │  AWS builds EVERYTHING automatically!    │
  │  Same blueprint → Same result every time  │
  │  Dev, Staging, Prod = identical!          │
  └──────────────────────────────────────────┘
```

### Terraform Workflow = Ordering Furniture Online
```
  terraform init     = Open the IKEA website (install plugins)
  terraform validate = Check if your order makes sense
  terraform plan     = See the invoice BEFORE paying
                       "You'll get: 1 table, 4 chairs, 1 lamp
                        Total: $50/month"
  terraform apply    = Confirm and place the order → items delivered!
  terraform destroy  = Return everything → cancel subscription
```

### Terraform State = Inventory Checklist
```
  State File (terraform.tfstate) = Warehouse inventory list

  "Current inventory:
    ✅ VPC vpc-abc123 — exists in AWS
    ✅ EC2 i-def456  — exists in AWS
    ❌ EC2 i-ghi789  — someone deleted it manually!"

  terraform plan detects the difference:
  "1 resource needs to be RECREATED"
```

### Terraform Modules = IKEA Instruction Booklets
```
  Instead of building a kitchen from scratch every time,
  use a pre-made module:

  module "vpc" {
    source = "./modules/vpc"    ← Reusable VPC blueprint
    cidr   = "10.0.0.0/16"
  }

  module "vpc" for dev    → 10.0.0.0/16
  module "vpc" for staging → 10.1.0.0/16
  module "vpc" for prod    → 10.2.0.0/16

  Same blueprint, different parameters = 3 environments!
```

### Real-World Impact
| Metric | Manual (Console) | Terraform (IaC) |
|--------|------------------|------------------|
| Build 3-tier app | 4 hours clicking | 10 minutes |
| Recreate exact copy for staging | "Um... let me remember" | `terraform apply -var env=staging` |
| Disaster recovery | Days/weeks | 15 minutes |
| Audit: "What changed?" | No record | Full Git history |
| Onboard new engineer | 2-week shadow | Read the .tf files |

---

## Topics

### Terraform Workflow
```
terraform init → validate → plan → apply → destroy
```

### File Structure
```
terraform/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── versions.tf          # Required providers & versions
├── terraform.tfvars     # Variable values (don't commit secrets!)
├── locals.tf            # Computed local values
├── data.tf              # Data sources
├── backend.tf           # Remote state configuration
└── .terraform.lock.hcl  # Dependency lock file
```

### State Management
- **State file** — tracks real-world resources → Terraform mapping
- **Remote state** — S3 + DynamoDB locking (team collaboration)
- **State commands:** `show`, `list`, `mv`, `rm`, `pull`, `push`, `import`
- **Never commit state files!** Contains secrets.

### Key Concepts
| Concept | Description |
|---------|------------|
| **Resources** | Create infrastructure (`aws_instance`, `aws_vpc`) |
| **Data Sources** | Read existing infrastructure (`data.aws_ami`) |
| **Variables** | Parameterize configurations |
| **Outputs** | Export values for other modules |
| **Locals** | Computed values (DRY) |
| **Modules** | Reusable infrastructure packages |
| **Workspaces** | Environment isolation (dev/staging/prod) |

### Meta-Arguments
```hcl
# count — create N identical resources
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = "t3.micro"
  tags = { Name = "web-${count.index + 1}" }
}

# for_each — create resources from a map/set
resource "aws_iam_user" "users" {
  for_each = toset(["alice", "bob", "charlie"])
  name     = each.value
}

# depends_on — explicit dependency
resource "aws_instance" "app" {
  depends_on = [aws_db_instance.main]
}

# lifecycle — control resource behavior
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes       = [tags]
  }
}
```

---

## Real-Time Project: Multi-Environment AWS Infrastructure with Modules

### Architecture
```
terraform/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT, IGW
│   ├── ec2/              # Launch template, instances
│   ├── rds/              # RDS PostgreSQL, subnet group
│   ├── alb/              # ALB, target group, listeners
│   ├── asg/              # Auto Scaling Group, policies
│   └── s3/               # S3 bucket, policies, lifecycle
├── environments/
│   ├── dev/
│   │   ├── main.tf       # Module calls with dev params
│   │   ├── terraform.tfvars
│   │   └── backend.tf    # S3 backend: dev state
│   ├── staging/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── global/
    ├── s3-state/         # S3 bucket for Terraform state
    └── iam/              # IAM roles and policies
```

### VPC Module Example
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  })
}
```

### Remote State Backend
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### GitHub Actions Pipeline
```yaml
name: Terraform
on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/dev

      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color
        working-directory: terraform/environments/dev

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: terraform/environments/dev
```

### Deliverables
- [ ] Reusable Terraform modules (VPC, EC2, RDS, ALB, ASG, S3)
- [ ] 3 environments (dev/staging/prod) with separate state files
- [ ] Remote state in S3 with DynamoDB locking
- [ ] GitHub Actions pipeline: plan on PR → apply on merge
- [ ] Import existing resources into Terraform
- [ ] Drift detection and remediation demonstrated
- [ ] Variables, outputs, locals properly structured

---

## Commands Cheat Sheet
```bash
terraform init            # Initialize providers and backend
terraform validate        # Validate syntax
terraform plan            # Preview changes
terraform apply           # Apply changes
terraform destroy         # Tear down infrastructure
terraform fmt             # Format code
terraform console         # Interactive expression testing
terraform graph           # Generate dependency graph
terraform output          # Show output values
terraform state list      # List resources in state
terraform state show      # Show resource details
terraform import          # Import existing resource
terraform taint           # Mark resource for recreation (deprecated)
terraform workspace list  # List workspaces
```

## Interview Questions
1. What is Terraform state and why is it important?
2. How to handle state file conflicts in a team?
3. `count` vs `for_each` — when to use which?
4. How to import existing resources into Terraform?
5. What are Terraform modules and why use them?
6. How to manage secrets in Terraform?
7. Explain Terraform lifecycle rules
8. What happens when you delete a resource from code but not from state?
