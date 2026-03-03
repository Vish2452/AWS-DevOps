# IAM — Identity & Access Management

> **Every AWS security architecture starts with IAM. This is the most asked topic in DevOps interviews.** IAM is FREE — no charges for users, groups, roles, or policies.

---

## Real-World Analogy

IAM is like a **corporate building security system**:
- **Users** = Employee ID badges (individual identity)
- **Groups** = Department teams (Engineering, Finance — shared access)
- **Roles** = Temporary visitor badges (assumed by services, apps, or cross-account)
- **Policies** = Access rules printed on badges ("Can enter floors 1-3, lab hours 9-5")
- **MFA** = Biometric verification (second factor beyond badge)
- **SCPs** = Building-wide restrictions ("Nobody can enter server room on weekends")

---

## Topics

### Core Concepts
- **Users** — individual identities (people, service accounts)
- **Groups** — collection of users with shared permissions
- **Roles** — assumed by services, applications, or cross-account access
- **Policies** — JSON documents defining permissions

### Policy Structure
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3ReadOnly",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::my-bucket",
                "arn:aws:s3:::my-bucket/*"
            ],
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "10.0.0.0/8"
                }
            }
        }
    ]
}
```

### Policy Types
| Type | Scope | Use Case | Example |
|------|-------|----------|---------|
| AWS Managed | AWS-maintained | Standard permissions | `ReadOnlyAccess`, `AdministratorAccess` |
| Customer Managed | Your account | Custom organization policies | "Dev team can only access dev resources" |
| Inline | Single entity | One-off permissions (avoid) | Emergency access for one user |

### Policy Evaluation Logic
```
                     ┌──────────────────┐
                     │  API Request     │
                     └────────┬─────────┘
                              │
                     ┌────────▼─────────┐
                     │  Is there an     │──── YES ──▶ DENY
                     │  explicit DENY?  │
                     └────────┬─────────┘
                              │ NO
                     ┌────────▼─────────┐
                     │  SCP allows?     │──── NO ───▶ DENY
                     │  (Org level)     │
                     └────────┬─────────┘
                              │ YES
                     ┌────────▼─────────┐
                     │  Permission      │──── NO ───▶ DENY
                     │  Boundary allows?│
                     └────────┬─────────┘
                              │ YES
                     ┌────────▼─────────┐
                     │  Is there an     │──── NO ───▶ DENY (implicit)
                     │  explicit ALLOW? │
                     └────────┬─────────┘
                              │ YES
                     ┌────────▼─────────┐
                     │     ALLOW ✅     │
                     └──────────────────┘

KEY RULE: Explicit DENY always wins over ALLOW
```

### Advanced IAM
- **Least privilege principle** — start with zero permissions, add as needed
- **IAM role switching** — cross-account access via STS AssumeRole
- **OIDC federation** — GitHub Actions, Google, external IdP
- **Service-linked roles** — auto-created by services
- **IAM Access Analyzer** — find unintended access
- **Credential reports** — audit user access keys
- **SCP (Service Control Policies)** — guardrails with AWS Organizations
- **Identity Center (SSO)** — modern multi-account access
- **Permission boundaries** — maximum permissions for a role

---

## Real-Time Example 1: Secure Multi-Team AWS Environment

**Scenario:** Your company has 3 teams (Dev, QA, DevOps). Each needs different access levels. You need to implement least privilege without creating individual policies for 50+ people.

```
                    AWS Organization
                           │
              ┌────────────┼────────────┐
              │            │            │
         Dev Account   QA Account   Prod Account
              │            │            │
    ┌─────────┼─────┐     │      ┌─────┼──────┐
    │         │     │     │      │     │      │
 Dev Team  QA Read  │  QA Team  DevOps  OnCall
 (Group)   (Group)  │  (Group)  (Group) (Group)
    │               │     │      │      │
 EC2+S3+RDS      ReadOnly │   Full    Admin+
 Dev resources   all accts│   QA env  Emergency
                          │           access
```

```bash
# Step 1: Create groups (never attach policies to users directly!)
aws iam create-group --group-name Developers
aws iam create-group --group-name QATeam
aws iam create-group --group-name DevOps
aws iam create-group --group-name ReadOnly

# Step 2: Create custom policy — Developers can only use dev resources
cat > dev-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowDevResources",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "s3:*",
                "rds:*",
                "lambda:*",
                "logs:*",
                "cloudwatch:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "development"
                }
            }
        },
        {
            "Sid": "AllowDescribeAll",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "s3:ListAllMyBuckets",
                "rds:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DenyProductionAccess",
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "production"
                }
            }
        }
    ]
}
EOF

POLICY_ARN=$(aws iam create-policy \
    --policy-name DeveloperAccess \
    --policy-document file://dev-policy.json \
    --query 'Policy.Arn' --output text)

aws iam attach-group-policy --group-name Developers --policy-arn $POLICY_ARN

# Step 3: Enforce MFA for all users
cat > mfa-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAllExceptMFASetup",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:GetUser",
                "iam:ListMFADevices",
                "iam:ListVirtualMFADevices",
                "sts:GetSessionToken"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
EOF
```

---

## Real-Time Example 2: Cross-Account CI/CD Pipeline

**Scenario:** Your Jenkins/GitHub Actions in the DevOps account needs to deploy to the Production account. You need secure cross-account access without sharing credentials.

```
┌─────────────────────┐         ┌─────────────────────┐
│   DevOps Account    │         │   Production Account │
│   (111111111111)    │         │   (222222222222)     │
│                     │         │                      │
│  Jenkins/GHA Role   │──STS──▶│  DeploymentRole      │
│  (can AssumeRole    │ Assume │  (can deploy to ECS, │
│   in Prod account)  │  Role  │   update Lambda,     │
│                     │         │   push to ECR)       │
└─────────────────────┘         └──────────────────────┘
```

```bash
# IN PRODUCTION ACCOUNT: Create role that DevOps account can assume
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::111111111111:role/JenkinsRole"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "deploy-2026-secure"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name CrossAccountDeployRole \
    --assume-role-policy-document file://trust-policy.json

# Attach deployment permissions
cat > deploy-permissions.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:RegisterTaskDefinition",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam put-role-policy --role-name CrossAccountDeployRole \
    --policy-name DeployPermissions \
    --policy-document file://deploy-permissions.json

# IN DEVOPS ACCOUNT: Jenkins assumes the role
aws sts assume-role \
    --role-arn arn:aws:iam::222222222222:role/CrossAccountDeployRole \
    --role-session-name jenkins-deploy-$(date +%s) \
    --external-id deploy-2026-secure \
    --duration-seconds 900

# Returns temporary credentials (AccessKeyId, SecretAccessKey, SessionToken)
# Jenkins uses these to deploy to production
```

---

## Real-Time Example 3: GitHub Actions OIDC (No Stored Credentials)

**Scenario:** You want GitHub Actions to deploy to AWS without storing long-lived AWS credentials as GitHub secrets. Use OIDC federation.

```
┌─────────────────┐                    ┌──────────────────┐
│  GitHub Actions  │──(1) JWT Token──▶ │  AWS STS         │
│  Workflow        │                    │                  │
│                  │◀──(2) Temp ───────│  Validates OIDC  │
│                  │   Credentials      │  token from      │
│                  │                    │  GitHub           │
│  (3) Deploy to  │                    └──────────────────┘
│  AWS with temp  │
│  credentials    │
└─────────────────┘

Benefits:
- NO stored AWS keys in GitHub Secrets
- Credentials expire in 1 hour
- Can restrict to specific repo/branch/environment
```

```bash
# Step 1: Create OIDC provider for GitHub
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Step 2: Create role with OIDC trust (restrict to specific repo + branch)
cat > github-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name GitHubActionsDeployRole \
    --assume-role-policy-document file://github-trust-policy.json

# Step 3: Attach permissions
aws iam attach-role-policy --role-name GitHubActionsDeployRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
```

**GitHub Actions Workflow:**
```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write    # Required for OIDC
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsDeployRole
          aws-region: us-east-1
      - run: aws ecs update-service --cluster prod --service web --force-new-deployment
```

---

## Hands-On Labs

### Lab 1: Create IAM Users and Groups
```bash
# Create groups
aws iam create-group --group-name Developers
aws iam create-group --group-name DevOps
aws iam create-group --group-name ReadOnly

# Attach policies
aws iam attach-group-policy --group-name Developers \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
aws iam attach-group-policy --group-name DevOps \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam attach-group-policy --group-name ReadOnly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Create user and add to group
aws iam create-user --user-name dev-alice
aws iam add-user-to-group --user-name dev-alice --group-name Developers
```

### Lab 2: Create Custom Policy
```bash
cat > s3-restricted-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
            "Resource": [
                "arn:aws:s3:::my-app-bucket",
                "arn:aws:s3:::my-app-bucket/*"
            ]
        }
    ]
}
EOF

aws iam create-policy \
    --policy-name S3RestrictedAccess \
    --policy-document file://s3-restricted-policy.json
```

### Lab 3: Cross-Account Role Switching
```bash
# In Account B: Create role that Account A can assume
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::ACCOUNT_A_ID:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "cross-acct-2026"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name CrossAccountRDSReader \
    --assume-role-policy-document file://trust-policy.json

# In Account A: Assume the role
aws sts assume-role \
    --role-arn arn:aws:iam::ACCOUNT_B_ID:role/CrossAccountRDSReader \
    --role-session-name cross-acct-session \
    --external-id cross-acct-2026
```

### Lab 4: IAM Security Audit
```bash
# Generate credential report
aws iam generate-credential-report
sleep 10
aws iam get-credential-report --query 'Content' --output text | base64 -d > cred-report.csv

# Find users without MFA
cat cred-report.csv | awk -F',' '$4=="true" && $8=="false" {print $1, "- NO MFA!"}'

# Find unused access keys (>90 days)
cat cred-report.csv | awk -F',' '$4=="true" && $11!="N/A" {print $1, $11}'

# Run IAM Access Analyzer
aws accessanalyzer create-analyzer --analyzer-name org-analyzer --type ACCOUNT
aws accessanalyzer list-findings --analyzer-arn arn:aws:access-analyzer:us-east-1:ACCT:analyzer/org-analyzer
```

---

## IAM Best Practices Checklist

| # | Practice | Impact |
|---|----------|--------|
| 1 | Enable MFA on root account | Prevents root account compromise |
| 2 | Never use root account for daily tasks | Limit blast radius |
| 3 | Use groups, not user-level policies | Scalable management |
| 4 | Use roles for applications (never embed keys) | No credential rotation needed |
| 5 | Use OIDC for CI/CD (no stored keys) | Eliminate long-lived credentials |
| 6 | Enable Access Analyzer | Find unintended public/cross-account access |
| 7 | Rotate access keys regularly (or better: don't use them) | Limit key exposure window |
| 8 | Use permission boundaries for delegated admin | Cap maximum permissions |
| 9 | Implement SCPs in AWS Organizations | Org-wide guardrails |
| 10 | Regular credential reports + audit | Catch stale/unused access |

---

## Interview Questions

1. **Explain the difference between IAM roles and users.**
   > **Users** have permanent long-term credentials (password, access keys) tied to a specific person or application. **Roles** have no permanent credentials — they provide temporary security credentials (via STS) when assumed. Roles are assumed by EC2 instances, Lambda functions, other AWS accounts, or federated users. Best practice: use roles everywhere, minimize users.

2. **What is the principle of least privilege and how to implement it?**
   > Start with zero permissions, add only what's needed. Implementation: (1) Use IAM Access Advisor to see which services are actually used, (2) Start with AWS managed policies, then create custom policies with specific resources/conditions, (3) Use IAM Access Analyzer to find over-permissive policies, (4) Regular audits to revoke unused permissions.

3. **How does cross-account access work with STS AssumeRole?**
   > Account B creates a role with a trust policy allowing Account A. Account A calls `sts:AssumeRole` with the role ARN. STS returns temporary credentials (key, secret, session token) valid for 1-12 hours. Account A uses these to access Account B resources. ExternalId prevents confused deputy attacks. No credentials are shared between accounts.

4. **What are SCPs and how do they differ from IAM policies?**
   > SCPs (Service Control Policies) are guardrails in AWS Organizations. They define the MAXIMUM permissions for all accounts in an OU/org. SCPs don't grant access — they restrict it. Even if a user has Admin policy, if the SCP doesn't allow the action, it's denied. Use for: "No one can delete CloudTrail logs," "Only us-east-1 and eu-west-1 allowed," "Must use encryption."

5. **How to set up OIDC federation for GitHub Actions?**
   > (1) Create OIDC provider in IAM for `token.actions.githubusercontent.com`, (2) Create role with trust policy allowing the OIDC provider, (3) Add conditions to restrict to specific repo/branch, (4) In GitHub workflow, use `aws-actions/configure-aws-credentials` action with `role-to-assume`. No AWS credentials stored in GitHub — uses short-lived tokens.

6. **What is IAM Access Analyzer and when to use it?**
   > Analyzes resource policies (S3 buckets, IAM roles, KMS keys, Lambda, SQS) to find resources shared with external entities. Reports findings like "This S3 bucket is accessible from account 999999999999." Use it to: catch accidental public access, audit cross-account sharing, validate policy changes before applying. Run continuously, not just one-time.

7. **Explain permission boundaries.**
   > A permission boundary sets the MAXIMUM permissions an IAM entity can have. Even if a policy grants `s3:*`, if the boundary only allows `s3:GetObject`, only GetObject works. Use case: delegated administration — let team leads create roles, but those roles can never exceed the boundary. The effective permissions = IAM policies ∩ permission boundary.

8. **What happens when an IAM policy has both Allow and Deny?**
   > Explicit Deny ALWAYS wins. Evaluation order: (1) Default deny → (2) Check all policies for explicit deny (if found → DENY) → (3) Check for explicit allow (if found → ALLOW) → (4) If no explicit allow → implicit DENY. This is why you can't override a Deny with an Allow — it's the fundamental security principle of IAM.
