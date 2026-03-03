# Secrets Manager — Secure Secret Storage & Rotation

> Centralized secret management with automatic rotation, cross-account sharing, and audit logging. Never hardcode credentials again.

---

## Real-World Analogy

Secrets Manager is like a **bank safety deposit box**:
- Your secrets (DB passwords, API keys) are locked in a vault
- Only authorized people (IAM roles) can access specific boxes
- The bank automatically changes the lock combination every 30 days (automatic rotation)
- Every access is logged (CloudTrail)
- You get a receipt number (secret ARN) — never carry the actual key

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Secret** | Encrypted credential/config | DB password, API key, OAuth token |
| **Secret Value** | The actual data (string or JSON) | `{"username":"admin","password":"xK9$mP2"}` |
| **Version** | Track changes (current + previous) | `AWSCURRENT`, `AWSPREVIOUS` |
| **Rotation** | Auto-change secrets on schedule | Every 30 days, rotate RDS password |
| **Resource Policy** | Cross-account access | Share secrets with prod account |
| **Replication** | Multi-region secrets | Same secret available in DR region |

---

## Secrets Manager vs Parameter Store

| Feature | Secrets Manager | SSM Parameter Store |
|---------|----------------|-------------------|
| **Cost** | $0.40/secret/month + $0.05/10K calls | Free (standard), $0.05/advanced |
| **Rotation** | Built-in automatic rotation | Manual (you build it) |
| **Cross-account** | Native resource policy | Complex (via IAM roles) |
| **Max size** | 64KB | 8KB (standard), 64KB (advanced) |
| **Replication** | Multi-region native | Not supported |
| **Best for** | DB credentials, API keys (need rotation) | Config values, feature flags, non-sensitive |

**Rule of thumb:** If it needs rotation → Secrets Manager. If it's configuration → Parameter Store.

---

## Real-Time Example 1: RDS Password Rotation

**Scenario:** Your RDS database password should rotate every 30 days automatically without any downtime.

```
┌──────────────────────────────────────────────────────────────┐
│              Automatic Rotation Flow                          │
│                                                              │
│  Day 1: Secret = "oldPassword123"                            │
│                                                              │
│  Day 30: Rotation Lambda runs                                │
│  ├── Step 1: createSecret → generates "newPassword456"       │
│  ├── Step 2: setSecret → changes password in RDS             │
│  ├── Step 3: testSecret → connects to RDS with new password  │
│  └── Step 4: finishSecret → moves AWSCURRENT to new version  │
│                                                              │
│  App calls GetSecretValue → always gets current password     │
│  Zero downtime! App never knows password changed.            │
└──────────────────────────────────────────────────────────────┘
```

```bash
# Create RDS secret
aws secretsmanager create-secret --name prod/rds/master \
    --description "Production RDS master credentials" \
    --secret-string '{"username":"admin","password":"initialP@ssw0rd","host":"prod-db.xxxx.us-east-1.rds.amazonaws.com","port":"5432","dbname":"myapp"}'

# Enable automatic rotation (every 30 days)
aws secretsmanager rotate-secret --secret-id prod/rds/master \
    --rotation-lambda-arn arn:aws:lambda:us-east-1:ACCT:function:SecretsManagerRDSRotation \
    --rotation-rules AutomaticallyAfterDays=30

# Application retrieves current secret (always up-to-date)
aws secretsmanager get-secret-value --secret-id prod/rds/master \
    --query 'SecretString' --output text
```

**In Application Code (Python):**
```python
import boto3, json

def get_db_credentials():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='prod/rds/master')
    secret = json.loads(response['SecretString'])
    return secret['username'], secret['password'], secret['host']

# Never hardcode credentials! Always fetch from Secrets Manager.
```

---

## Real-Time Example 2: Multi-Environment Secret Management

**Scenario:** Manage secrets across dev/staging/prod with proper access control.

```bash
# Naming convention: {env}/{service}/{secret-name}
aws secretsmanager create-secret --name dev/api/stripe-key \
    --secret-string '{"api_key":"sk_test_xxx"}' \
    --tags Key=Environment,Value=dev

aws secretsmanager create-secret --name prod/api/stripe-key \
    --secret-string '{"api_key":"sk_live_xxx"}' \
    --tags Key=Environment,Value=prod

# IAM policy: dev team can only access dev/* secrets
# {
#   "Effect": "Allow",
#   "Action": "secretsmanager:GetSecretValue",
#   "Resource": "arn:aws:secretsmanager:us-east-1:ACCT:secret:dev/*"
# }

# Prod secrets: only prod roles can access
# Plus: deny console access (force API-only retrieval)
```

---

## Real-Time Example 3: Cross-Account Secret Sharing

**Scenario:** Central security account manages secrets. Application accounts retrieve them.

```bash
# In security account: create secret with resource policy
aws secretsmanager put-resource-policy --secret-id prod/shared/api-key \
    --resource-policy '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"AWS": "arn:aws:iam::APP_ACCOUNT:role/AppRole"},
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "*"
        }]
    }'

# In app account: retrieve cross-account secret
aws secretsmanager get-secret-value \
    --secret-id arn:aws:secretsmanager:us-east-1:SECURITY_ACCT:secret:prod/shared/api-key
```

---

## Labs

### Lab 1: Create and Retrieve Secret
```bash
aws secretsmanager create-secret --name demo/db-password \
    --secret-string '{"username":"admin","password":"mySecret123"}'

aws secretsmanager get-secret-value --secret-id demo/db-password
aws secretsmanager list-secrets

# Update secret
aws secretsmanager update-secret --secret-id demo/db-password \
    --secret-string '{"username":"admin","password":"newSecret456"}'
```

### Lab 2: Enable Rotation
```bash
# Use AWS-provided rotation Lambda for RDS
aws secretsmanager rotate-secret --secret-id prod/rds/master \
    --rotation-lambda-arn arn:aws:lambda:us-east-1:ACCT:function:rotation-fn \
    --rotation-rules AutomaticallyAfterDays=30

# Test rotation
aws secretsmanager rotate-secret --secret-id prod/rds/master
```

---

## Interview Questions

1. **Secrets Manager vs Parameter Store — when to use which?**
   > Secrets Manager: for credentials that need automatic rotation (DB passwords, API keys). Costs $0.40/secret/month. Parameter Store: for configuration values, feature flags, non-sensitive data. Free tier available. Use both: Secrets Manager for passwords, Parameter Store for config.

2. **How does automatic rotation work?**
   > Secrets Manager invokes a Lambda function on schedule (e.g., every 30 days). The Lambda has 4 steps: createSecret (generate new), setSecret (update in DB), testSecret (verify new credential works), finishSecret (mark as AWSCURRENT). AWS provides pre-built Lambda templates for RDS, Redshift, DocumentDB.

3. **How do applications retrieve secrets without downtime during rotation?**
   > App calls `GetSecretValue` at runtime (cached in memory for a short time). During rotation, both old and new credentials work briefly (dual-secret strategy). Once `finishSecret` completes, `AWSCURRENT` points to new credential. App's next `GetSecretValue` call gets the new one. No restart needed.

4. **How to prevent secrets from being logged?**
   > (1) Never print/log secret values in application code, (2) Use CloudTrail to audit who accessed secrets, (3) Encrypt secrets with KMS (CMK for additional control), (4) Use VPC endpoint for Secrets Manager (traffic stays in VPC), (5) IAM policies with conditions (e.g., require MFA for secret access).

5. **How does multi-region replication work?**
   > Primary secret is created in one region, replicas are auto-synced to other regions. If primary region goes down, replicas can be promoted. Use for: disaster recovery, low-latency access from multiple regions. Replicas are read-only until promoted.

6. **How to audit secret access?**
   > CloudTrail logs every `GetSecretValue`, `CreateSecret`, `UpdateSecret`, `RotateSecret` call with who, when, and from where (IP). Set up CloudWatch alarms for suspicious patterns (e.g., failed access attempts, access from unexpected roles, bulk secret retrieval).
