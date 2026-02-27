# AWS DevSecOps — Security Services & Governance

> **Objective:** Implement enterprise-grade AWS security using native services. Build automated guardrails, threat detection, compliance monitoring, and governance at scale with AWS-native DevSecOps tools.

---

## 🏛️ Real-World Analogy: AWS Security is Like National Security

Imagine your AWS account is a **country** and you need to protect it at every level:

```
🏛️ YOUR AWS ACCOUNT = A COUNTRY
│
├── 🛂 IAM = Immigration & Passport Control
│   "Who are you? What are you allowed to do here?"
│   Users, roles, policies = passports, visas, permits.
│   "Alice has a TOURIST visa (read-only). Bob has a WORK permit (admin)."
│
├── 🕵️ GuardDuty = Intelligence Agency (CIA/FBI)
│   Silently watches for threats 24/7:
│   "Someone from a known hacker IP is trying to brute-force your servers!"
│   "An EC2 instance is communicating with a Bitcoin mining server!"
│   "Data is being exported to an unknown external account!"
│   You don't configure rules — AI/ML detects threats automatically.
│
├── 📋 Security Hub = National Security Dashboard
│   Collects findings from ALL security agencies:
│   GuardDuty + Inspector + Macie + Config + Firewall Manager
│   One dashboard to see your ENTIRE security posture.
│   "Your country's security score: 78/100. Improve these 15 things."
│
├── 🏗️ Control Tower / Landing Zone = City Planning Department
│   "Before you build anything, follow these rules:"
│   - Every new account (neighborhood) gets:
│     • CloudTrail logging (security cameras)
│     • Config rules (building codes)
│     • Guardrails (don't build in flood zones)
│   Sets up your entire multi-account structure properly from day 1.
│
├── 📜 SCP (Service Control Policies) = National Laws
│   "NO ONE in this country is allowed to:"
│   - Delete CloudTrail logs (destroy evidence)
│   - Create resources outside approved regions
│   - Use root account for daily operations
│   Even ADMIN users cannot override SCPs! (Like constitutional laws)
│
├── 🔍 AWS Config = Building Inspector
│   Continuously checks every building (resource) against codes:
│   "This S3 bucket doesn't have encryption — VIOLATION!"
│   "This security group allows SSH from 0.0.0.0/0 — VIOLATION!"
│   Can auto-remediate: "Violation detected → auto-fix applied"
│
├── 🔬 Inspector = Health Inspector
│   Scans EC2 instances and containers for vulnerabilities:
│   "This server has CVE-2024-1234 (critical!) — patch immediately"
│   Like a doctor regularly checking for diseases.
│
├── 🔐 IAM Access Analyzer = Key Audit
│   "Who has access to what? Is any of it excessive?"
│   "This S3 bucket is shared with an EXTERNAL account — intended?"
│   "This IAM role hasn't been used in 90 days — remove it?"
│
└── 🚨 Automated Response = Emergency Services (911)
    EventBridge + Lambda = "If GuardDuty detects crypto mining →
      1. Isolate the EC2 instance immediately
      2. Take a forensic snapshot
      3. Page the security team
      4. Block the attacker's IP"
    Response time: 30 seconds (not 30 minutes!)
```

### Multi-Account Security Architecture
```
  ┌─────────────────── AWS Organization ────────────────────┐
  │                                                          │
  │  Management Account (ROOT)                               │
  │  ├── SCPs enforce rules across ALL accounts              │
  │  ├── CloudTrail: organization-wide logging               │
  │  └── Billing: consolidated                               │
  │                                                          │
  │  ┌── Security Account ─────────────────────────────────┐ │
  │  │   GuardDuty (delegated admin)                        │ │
  │  │   Security Hub (aggregated findings)                 │ │
  │  │   Detective (investigation)                          │ │
  │  └──────────────────────────────────────────────────────┘ │
  │                                                          │
  │  ┌── Log Archive Account ──────────────────────────────┐ │
  │  │   CloudTrail logs (immutable, locked)                │ │
  │  │   Config snapshots                                   │ │
  │  │   VPC Flow Logs                                      │ │
  │  └──────────────────────────────────────────────────────┘ │
  │                                                          │
  │  ┌── Workload Accounts ────────────────────────────────┐ │
  │  │   Dev Account    │ Staging Account │ Prod Account   │ │
  │  │   (relaxed SCPs) │ (moderate)      │ (strict SCPs)  │ │
  │  └──────────────────────────────────────────────────────┘ │
  └──────────────────────────────────────────────────────────┘
```

### Real-World Breaches Prevention Examples
| Real Incident | AWS Service That Prevents It | How |
|---|---|---|
| S3 bucket exposed to public (Capital One) | Config Rule + Auto-Remediation | "Public S3 detected → auto-set to private" |
| Stolen AWS access keys | GuardDuty + IAM Access Analyzer | "Unusual API call from new IP → alert + disable key" |
| Crypto mining on EC2 | GuardDuty + Lambda auto-response | "Mining detected → isolate instance in 30 seconds" |
| Unauthorized region usage | SCP policy | "Block all services outside us-east-1 and eu-west-1" |
| No audit trail | CloudTrail + S3 Object Lock | "Logs cannot be deleted, even by root account" |
| Unpatched servers | Inspector + SSM Patch Manager | "Auto-scan weekly → auto-patch critical CVEs" |

---

## AWS Security Services Map

```
┌───────────────────────── AWS DevSecOps ─────────────────────────┐
│                                                                  │
│  ┌─── Threat Detection ───┐  ┌─── Compliance & Governance ───┐  │
│  │ GuardDuty              │  │ Security Hub                   │  │
│  │ Inspector              │  │ AWS Config + Rules             │  │
│  │ Macie (PII in S3)      │  │ AWS Audit Manager              │  │
│  │ Detective              │  │ CloudTrail                     │  │
│  └────────────────────────┘  └────────────────────────────────┘  │
│                                                                  │
│  ┌─── Access & Identity ──┐  ┌─── Multi-Account Governance ──┐  │
│  │ IAM Access Analyzer    │  │ AWS Organizations              │  │
│  │ IAM Identity Center    │  │ Service Control Policies (SCP) │  │
│  │ STS + Roles            │  │ Control Tower / Landing Zone   │  │
│  │ Secrets Manager        │  │ AWS RAM (Resource Sharing)     │  │
│  └────────────────────────┘  └────────────────────────────────┘  │
│                                                                  │
│  ┌─── Network & Data ─────┐  ┌─── Automated Response ────────┐  │
│  │ WAF + Shield           │  │ EventBridge + Lambda           │  │
│  │ Network Firewall       │  │ Systems Manager (SSM)          │  │
│  │ KMS + CloudHSM         │  │ Security Hub Auto-Remediation  │  │
│  │ Certificate Manager    │  │ GuardDuty → StepFunctions      │  │
│  └────────────────────────┘  └────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 1. Amazon GuardDuty — Threat Detection

### What It Does
Continuously monitors AWS accounts for malicious activity using ML, anomaly detection, and threat intelligence feeds. Analyzes VPC Flow Logs, DNS logs, CloudTrail events, S3 data events, EKS audit logs, and Lambda network activity — **no agents required**.

### Findings Categories
| Category | Examples |
|----------|---------|
| **Reconnaissance** | Port scanning, unusual API calls |
| **Instance Compromise** | Crypto mining, C&C communication, malware |
| **Account Compromise** | Unusual regions, credential exfiltration |
| **S3 Compromise** | Public bucket, unusual data access patterns |
| **EKS Threats** | Privileged container, anonymous access |
| **Lambda Threats** | Suspicious network connections |

### Setup with Terraform
```hcl
# Enable GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Service     = "security"
  }
}

# Auto-publish findings to SNS
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-high-severity"
  description = "GuardDuty findings with severity >= HIGH"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.security_alerts.arn
}

resource "aws_sns_topic" "security_alerts" {
  name = "guardduty-alerts"
}
```

### Auto-Remediation: Block Compromised Instance
```python
# lambda: guardduty_remediation.py
import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    """Auto-isolate EC2 instance flagged by GuardDuty."""
    detail = event['detail']
    finding_type = detail['type']
    severity = detail['severity']
    instance_id = detail['resource']['instanceDetails']['instanceId']

    logger.info(f"Finding: {finding_type}, Severity: {severity}, Instance: {instance_id}")

    if severity >= 7:
        # Create isolation security group (no inbound/outbound)
        vpc_id = detail['resource']['instanceDetails']['networkInterfaces'][0]['vpcId']

        try:
            sg = ec2.create_security_group(
                GroupName=f'quarantine-{instance_id}',
                Description=f'Quarantine SG for {instance_id} - GuardDuty',
                VpcId=vpc_id
            )
            sg_id = sg['GroupId']

            # Remove all egress rules
            ec2.revoke_security_group_egress(
                GroupId=sg_id,
                IpPermissions=[{
                    'IpProtocol': '-1',
                    'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                }]
            )

            # Replace instance security groups with quarantine SG
            ec2.modify_instance_attribute(
                InstanceId=instance_id,
                Groups=[sg_id]
            )

            # Tag instance for investigation
            ec2.create_tags(
                Resources=[instance_id],
                Tags=[
                    {'Key': 'SecurityStatus', 'Value': 'QUARANTINED'},
                    {'Key': 'GuardDutyFinding', 'Value': finding_type},
                    {'Key': 'QuarantinedAt', 'Value': context.invoked_function_arn}
                ]
            )

            logger.info(f"Instance {instance_id} quarantined successfully")
        except Exception as e:
            logger.error(f"Failed to quarantine {instance_id}: {e}")
            raise

    return {'statusCode': 200, 'body': f'Processed: {finding_type}'}
```

---

## 2. AWS Security Hub — Centralized Security Posture

### What It Does
Aggregates findings from GuardDuty, Inspector, Macie, Firewall Manager, IAM Access Analyzer, and third-party tools into a **single pane of glass**. Runs automated compliance checks against frameworks.

### Compliance Standards
| Standard | Checks | Use Case |
|----------|--------|----------|
| **AWS Foundational Security Best Practices** | 200+ | Default for all accounts |
| **CIS AWS Foundations Benchmark** | 50+ | Industry standard |
| **PCI DSS** | 130+ | Payment card data |
| **NIST 800-53** | 200+ | Government/regulated |
| **SOC 2** | Custom | SaaS companies |

### Setup with Terraform
```hcl
resource "aws_securityhub_account" "main" {}

# Enable compliance standards
resource "aws_securityhub_standards_subscription" "aws_best_practices" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"
}

# Auto-remediation for specific findings
resource "aws_securityhub_action_target" "remediate" {
  depends_on  = [aws_securityhub_account.main]
  name        = "AutoRemediate"
  identifier  = "AutoRemediate"
  description = "Auto-remediate critical findings"
}
```

### Auto-Remediation Examples
```python
# Remediation: Enable S3 bucket encryption (triggered by Security Hub finding)
def remediate_s3_encryption(bucket_name):
    s3 = boto3.client('s3')
    s3.put_bucket_encryption(
        Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            'Rules': [{
                'ApplyServerSideEncryptionByDefault': {
                    'SSEAlgorithm': 'aws:kms',
                    'KMSMasterKeyID': 'alias/aws/s3'
                },
                'BucketKeyEnabled': True
            }]
        }
    )

# Remediation: Enable CloudTrail logging
def remediate_cloudtrail(trail_name):
    ct = boto3.client('cloudtrail')
    ct.start_logging(Name=trail_name)

# Remediation: Block public S3 bucket
def remediate_public_s3(bucket_name):
    s3 = boto3.client('s3')
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True,
            'IgnorePublicAcls': True,
            'BlockPublicPolicy': True,
            'RestrictPublicBuckets': True
        }
    )
```

---

## 3. AWS Control Tower & Landing Zone

### What It Does
Sets up and governs a **secure, multi-account AWS environment** following best practices. Automates account provisioning with guardrails.

### Landing Zone Architecture
```
AWS Organizations (Management Account)
├── Security OU
│   ├── Log Archive Account      ← Centralized CloudTrail + Config logs
│   └── Audit Account            ← Security Hub aggregator, GuardDuty admin
├── Infrastructure OU
│   ├── Shared Services Account  ← Transit Gateway, DNS, CI/CD tools
│   └── Networking Account       ← VPCs, Direct Connect, VPN
├── Sandbox OU
│   └── Developer Sandbox        ← Experimentation (SCP limited)
├── Workloads OU
│   ├── Dev Account
│   ├── Staging Account
│   └── Production Account
└── Policy Staging OU
    └── SCP Test Account         ← Test new SCPs before applying broadly
```

### Control Tower Guardrails
| Type | Example | Action |
|------|---------|--------|
| **Preventive (SCP)** | Deny root user access | Block |
| **Detective (Config Rules)** | EBS volumes encrypted | Alert |
| **Proactive (CFN Hooks)** | S3 buckets must have versioning | Block deploy |

### Account Factory (Terraform)
```hcl
# Provision new AWS account via Organizations
resource "aws_organizations_account" "workload" {
  name      = "production-workload"
  email     = "aws-prod@company.com"
  parent_id = aws_organizations_organizational_unit.workloads.id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.main.roots[0].id
}
```

---

## 4. Service Control Policies (SCPs)

### What They Are
JSON policies attached to OUs or accounts in AWS Organizations. They define the **maximum available permissions** — even admin users cannot exceed SCP boundaries.

### SCP: Deny All Outside Approved Regions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "sts:*",
        "support:*",
        "budgets:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-west-2",
            "eu-west-1"
          ]
        }
      }
    }
  ]
}
```

### SCP: Prevent Disabling Security Services
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PreventDisablingGuardDuty",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "guardduty:DisableOrganizationAdminAccount",
        "guardduty:StopMonitoringMembers"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PreventDisablingSecurityHub",
      "Effect": "Deny",
      "Action": [
        "securityhub:DisableSecurityHub",
        "securityhub:DeleteMembers",
        "securityhub:DisassociateMembers"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PreventDisablingCloudTrail",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyRootUser",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

### SCP: Deny Expensive Services (Sandbox OU)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyExpensiveServices",
      "Effect": "Deny",
      "Action": [
        "redshift:*",
        "emr:*",
        "sagemaker:Create*",
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringNotLike": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.small",
            "t3.medium"
          ]
        }
      }
    }
  ]
}
```

### Terraform for SCPs
```hcl
resource "aws_organizations_policy" "deny_regions" {
  name        = "deny-unapproved-regions"
  description = "Deny resource creation outside approved regions"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("policies/deny-regions.json")
}

resource "aws_organizations_policy_attachment" "deny_regions" {
  policy_id = aws_organizations_policy.deny_regions.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy" "security_guardrails" {
  name    = "security-guardrails"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("policies/security-guardrails.json")
}

resource "aws_organizations_policy_attachment" "security_all_ous" {
  for_each  = toset([
    aws_organizations_organizational_unit.workloads.id,
    aws_organizations_organizational_unit.sandbox.id,
    aws_organizations_organizational_unit.infrastructure.id,
  ])
  policy_id = aws_organizations_policy.security_guardrails.id
  target_id = each.value
}
```

---

## 5. AWS Config — Continuous Compliance

### Managed Rules
```hcl
# Ensure all EBS volumes are encrypted
resource "aws_config_config_rule" "ebs_encrypted" {
  name = "ebs-encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}

# Ensure S3 buckets not publicly accessible
resource "aws_config_config_rule" "s3_public" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# Ensure RDS encryption at rest
resource "aws_config_config_rule" "rds_encrypted" {
  name = "rds-storage-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}

# Auto-remediation: enable S3 versioning
resource "aws_config_remediation_configuration" "s3_versioning" {
  config_rule_name = aws_config_config_rule.s3_versioning.name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-ConfigureS3BucketVersioning"

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }
  parameter {
    name         = "VersioningState"
    static_value = "Enabled"
  }

  automatic                = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}
```

---

## 6. Amazon Inspector — Vulnerability Management

```hcl
resource "aws_inspector2_enabler" "main" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}
```

### Integration with CI/CD
```yaml
# GitHub Actions: scan ECR image with Inspector
- name: ECR Image Scan
  run: |
    # Push triggers automatic Inspector scan
    aws ecr describe-image-scan-findings \
      --repository-name myapp \
      --image-id imageTag=${{ github.sha }} \
      --query 'imageScanFindings.findings[?severity==`CRITICAL`]' \
      --output json > scan-results.json

    # Fail if critical vulnerabilities found
    CRITICAL_COUNT=$(jq length scan-results.json)
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
      echo "::error::Found $CRITICAL_COUNT critical vulnerabilities"
      exit 1
    fi
```

---

## 7. IAM Access Analyzer

```hcl
resource "aws_accessanalyzer_analyzer" "org" {
  analyzer_name = "organization-analyzer"
  type          = "ORGANIZATION"

  tags = {
    Environment = "production"
  }
}
```

### Use Cases
- Find resources shared externally (S3, SQS, KMS, Lambda, IAM Roles)
- Validate IAM policies before deployment
- Generate least-privilege policies from CloudTrail activity

```bash
# Generate least-privilege policy from 90 days of CloudTrail
aws accessanalyzer start-policy-generation \
  --policy-generation-details '{
    "principalArn": "arn:aws:iam::123456:role/MyAppRole",
    "cloudTrailDetails": {
      "trailArn": "arn:aws:cloudtrail:us-east-1:123456:trail/main",
      "startTime": "2025-12-01T00:00:00Z",
      "endTime": "2026-02-27T00:00:00Z"
    }
  }'
```

---

## Real-Time Project: Enterprise AWS Security Automation

### Architecture
```
┌────────────── Management Account ──────────────────────┐
│  AWS Organizations                                      │
│  ├── SCPs (region lock, deny root, protect security)    │
│  ├── Control Tower (Landing Zone)                       │
│  └── CloudFormation StackSets (baseline config)         │
└────────────────────────┬───────────────────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
┌───┴─── Audit ────┐ ┌──┴── Workload ──┐ ┌──┴── Sandbox ──┐
│ Security Hub     │ │ GuardDuty       │ │ Limited SCPs   │
│ (aggregator)     │ │ Inspector       │ │ Budget alerts  │
│ Config Recorder  │ │ Config Rules    │ │ Auto-cleanup   │
│ IAM Analyzer     │ │ CloudTrail      │ │                │
└──────┬───────────┘ └────────┬────────┘ └────────────────┘
       │                      │
       └──────────┬───────────┘
                  │
    ┌─────────────┴─────────────┐
    │    EventBridge Central     │
    │         │                  │
    │   ┌─────┼─────┐           │
    │   │     │     │           │
    │ Lambda  SNS  Step Func    │
    │ (auto   (Slack (incident  │
    │  fix)   alert) workflow)  │
    └───────────────────────────┘
```

### Project Structure
```
aws-devsecops/
├── terraform/
│   ├── organization/
│   │   ├── main.tf             # AWS Organizations setup
│   │   ├── ous.tf              # Organizational Units
│   │   ├── accounts.tf         # Account factory
│   │   └── scps/
│   │       ├── deny-regions.json
│   │       ├── security-guardrails.json
│   │       └── sandbox-limits.json
│   ├── security-baseline/
│   │   ├── guardduty.tf
│   │   ├── security-hub.tf
│   │   ├── config-rules.tf
│   │   ├── inspector.tf
│   │   ├── access-analyzer.tf
│   │   ├── cloudtrail.tf
│   │   └── iam-baseline.tf
│   └── auto-remediation/
│       ├── eventbridge.tf
│       ├── lambda.tf
│       └── step-functions.tf
├── lambda/
│   ├── guardduty-remediation/
│   │   └── handler.py
│   ├── config-remediation/
│   │   └── handler.py
│   └── security-hub-enrichment/
│       └── handler.py
├── policies/
│   ├── deny-regions.json
│   ├── security-guardrails.json
│   └── sandbox-limits.json
└── dashboards/
    └── security-posture.json   # Grafana/CloudWatch dashboard
```

### Deliverables
- [ ] AWS Organizations with OUs (Security, Workloads, Sandbox, Infrastructure)
- [ ] SCPs: region lock, deny root, protect security services, sandbox limits
- [ ] GuardDuty enabled org-wide with auto-remediation Lambda
- [ ] Security Hub with AWS Best Practices + CIS Benchmark enabled
- [ ] AWS Config with 10+ managed rules and auto-remediation
- [ ] Inspector scanning EC2 + ECR + Lambda
- [ ] IAM Access Analyzer (Organization-wide)
- [ ] CloudTrail org trail → S3 (log archive account)
- [ ] EventBridge rules routing findings → SNS → Slack
- [ ] Security posture dashboard (compliance score, open findings)
- [ ] Incident response runbook (GuardDuty finding → investigation → remediation)
- [ ] All infrastructure in Terraform with remote state

---

## Interview Questions
1. What is the difference between IAM policies and SCPs?
2. How does GuardDuty detect threats without agents?
3. Explain the Landing Zone concept and Control Tower guardrails.
4. How would you set up a multi-account security strategy?
5. What's the difference between preventive and detective guardrails?
6. How do you auto-remediate Security Hub findings?
7. What are Config Rules vs Config Conformance Packs?
8. How does IAM Access Analyzer generate least-privilege policies?
