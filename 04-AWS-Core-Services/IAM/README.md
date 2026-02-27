# IAM — Identity & Access Management

> **Every AWS security architecture starts with IAM. This is the most asked topic in DevOps interviews.**

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
| Type | Scope | Use Case |
|------|-------|----------|
| AWS Managed | AWS-maintained | Standard permissions (ReadOnlyAccess) |
| Customer Managed | Your account | Custom organization policies |
| Inline | Single entity | One-off permissions (avoid in production) |

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
# Create a policy allowing S3 access to specific bucket only
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

### Lab 4: OIDC for GitHub Actions
```bash
# Create OIDC provider for GitHub
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create role with OIDC trust
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
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:*"
                }
            }
        }
    ]
}
EOF
```

---

## Interview Questions
1. Explain the difference between IAM roles and users
2. What is the principle of least privilege and how to implement it?
3. How does cross-account access work with STS AssumeRole?
4. What are SCPs and how do they differ from IAM policies?
5. How to set up OIDC federation for GitHub Actions?
6. What is IAM Access Analyzer and when to use it?
7. Explain permission boundaries
8. What happens when an IAM policy has both Allow and Deny?
