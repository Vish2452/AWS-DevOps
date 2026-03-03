# STS — Security Token Service

> Issue temporary, limited-privilege security credentials. The foundation of cross-account access, federation, and role assumption.

---

## Real-World Analogy

STS is like a **hotel front desk issuing temporary room key cards**:
- You present ID (your credentials) → front desk verifies → issues a temporary card
- Card has specific access (only your floor), expires in 12 hours
- Different card tiers: guest (basic role), VIP (admin role), staff (service role)
- Card stops working after checkout (token expiry)

---

## Key Operations

| Operation | Use Case | Max Duration |
|-----------|----------|-------------|
| **AssumeRole** | Cross-account access, service roles | 1-12 hours |
| **AssumeRoleWithWebIdentity** | OIDC federation (GitHub, Google) | 1-12 hours |
| **AssumeRoleWithSAML** | Enterprise SSO (Active Directory) | 1-12 hours |
| **GetSessionToken** | MFA-protected API access | 15 min - 36 hours |
| **GetFederationToken** | Temporary access for federated users | 15 min - 36 hours |

---

## Real-Time Example 1: Cross-Account Deployment

**Scenario:** CI/CD in Account A deploys to Account B.

```bash
# In Account A: Assume role in Account B
CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::222222222222:role/DeployRole \
    --role-session-name ci-deploy-$(date +%s) \
    --external-id "deploy-secret-2026" \
    --duration-seconds 900)

# Extract temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

# Now all AWS CLI commands operate in Account B
aws ecs update-service --cluster prod --service web --force-new-deployment

# Credentials expire automatically after 15 minutes
```

---

## Real-Time Example 2: Temporary S3 Access for External Partner

**Scenario:** Give a partner temporary read-only access to a specific S3 bucket for 1 hour.

```bash
aws sts assume-role \
    --role-arn arn:aws:iam::ACCT:role/PartnerReadOnlyRole \
    --role-session-name partner-access \
    --duration-seconds 3600 \
    --policy '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:GetObject"],
            "Resource": "arn:aws:s3:::shared-reports/partner-data/*"
        }]
    }'
# Session policy further restricts (intersection with role policy)
```

---

## Labs

### Lab 1: AssumeRole
```bash
# Check current identity
aws sts get-caller-identity

# Assume a role
aws sts assume-role --role-arn arn:aws:iam::ACCT:role/AdminRole \
    --role-session-name test-session

# Verify new identity
aws sts get-caller-identity
```

---

## Interview Questions

1. **What is STS and why is it important?**
   > STS issues temporary credentials (access key + secret + session token) that expire automatically. Eliminates need for long-lived access keys. Foundation of: cross-account access, OIDC federation (GitHub Actions), service roles (EC2, Lambda), and MFA-protected operations.

2. **How does AssumeRole work?**
   > Caller makes `sts:AssumeRole` call with target role ARN. STS checks: (1) caller has permission to call AssumeRole, (2) role's trust policy allows the caller, (3) optional ExternalId matches. Returns temporary credentials valid 1-12 hours. Caller uses these for subsequent API calls.

3. **What is the confused deputy problem?**
   > When a service (deputy) is tricked into accessing resources it shouldn't. Example: Service X assumes Role Y on behalf of Customer A, but Customer B provides Service X with Role Y's ARN too. Solution: ExternalId — a secret shared between the role creator and the trusted party, preventing unauthorized assumption.

4. **What is a session policy?**
   > An inline policy passed during AssumeRole that further restricts (intersects with) the role's permissions. The effective permissions = role policies ∩ session policy. Use to give different callers different subsets of a role's permissions without creating multiple roles.

5. **How long do temporary credentials last?**
   > Default: 1 hour. Configurable: 15 minutes to 12 hours (role setting). For `GetSessionToken`: up to 36 hours. Best practice: use shortest duration needed. For CI/CD: 15-30 minutes. For interactive sessions: 1-4 hours.
