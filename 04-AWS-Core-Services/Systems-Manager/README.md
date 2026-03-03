# Systems Manager (SSM) — Operations Management

> Manage EC2 instances, on-premises servers, and AWS resources at scale. The Swiss Army knife of AWS operations — patch, configure, run commands, connect securely.

---

## Real-World Analogy

SSM is like a **building management system for a skyscraper**:
- **Session Manager** = Master key card (access any server without physical keys/SSH)
- **Run Command** = PA system (broadcast instructions to all floors at once)
- **Patch Manager** = Maintenance crew (update all systems on a schedule)
- **Parameter Store** = Bulletin board (centralized configuration)
- **Inventory** = Asset register (what software/hardware is on each floor)
- **State Manager** = Building code enforcement (ensure all floors comply with standards)

---

## Key Components

| Component | Purpose | Example |
|-----------|---------|---------|
| **Session Manager** | Secure shell access (no SSH/keys) | Connect to EC2 without port 22 |
| **Run Command** | Execute commands on multiple instances | Install security patch on 500 servers |
| **Patch Manager** | Automated patching | Patch all Linux servers every Tuesday 2 AM |
| **Parameter Store** | Centralized config/secrets | Store DB connection strings, feature flags |
| **Inventory** | Collect instance metadata | List all installed packages across fleet |
| **State Manager** | Enforce desired configuration | Ensure CloudWatch agent is always running |
| **Automation** | Multi-step runbooks | Automated Golden AMI creation |
| **Maintenance Windows** | Scheduled operations | "Only patch during 2 AM-5 AM Saturday" |

---

## Real-Time Example 1: Replace Bastion Hosts with Session Manager

**Scenario:** You have 50 bastion hosts ($2,000/month) managing SSH access to 500 servers. Migration to Session Manager eliminates all bastions.

```
BEFORE (Bastion Host):
Developer → VPN → Bastion Host (SSH, port 22) → Private EC2
- Need bastion in every VPC ($40/month each)
- Manage SSH keys for all developers
- Port 22 open = attack surface
- Key rotation is painful

AFTER (Session Manager):
Developer → AWS Console/CLI → Session Manager → Private EC2
- No bastion hosts needed ($0)
- IAM-based access (no SSH keys!)
- No ports open (uses SSM agent → AWS endpoints)
- Full logging in CloudTrail + S3
- Savings: $2,000/month
```

```bash
# Prerequisites: EC2 must have SSM agent + IAM role
# Attach this managed policy to EC2 role:
# arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Connect to instance (no SSH key, no port 22!)
aws ssm start-session --target i-xxxx

# For VPC without internet, create VPC endpoints:
for SERVICE in ssm ssmmessages ec2messages; do
    aws ec2 create-vpc-endpoint --vpc-id $VPC_ID \
        --service-name com.amazonaws.us-east-1.$SERVICE \
        --vpc-endpoint-type Interface \
        --subnet-ids $PRIV_A $PRIV_B \
        --security-group-ids $ENDPOINT_SG \
        --private-dns-enabled
done

# Enable session logging to S3 + CloudWatch
aws ssm update-document --name "SSM-SessionManagerRunShell" \
    --document-version '$LATEST' \
    --content '{
        "schemaVersion": "1.0",
        "description": "Session Manager settings",
        "sessionType": "Standard_Stream",
        "inputs": {
            "s3BucketName": "session-logs-bucket",
            "s3KeyPrefix": "ssm-sessions/",
            "cloudWatchLogGroupName": "/aws/ssm/sessions",
            "cloudWatchEncryptionEnabled": true
        }
    }'
```

---

## Real-Time Example 2: Automated Patching with Maintenance Windows

**Scenario:** 500 EC2 instances across dev/staging/prod. Patch dev on Tuesday, staging on Wednesday, prod on Saturday — all automated.

```bash
# Step 1: Create patch baselines
aws ssm create-patch-baseline --name "Prod-Linux-Baseline" \
    --operating-system AMAZON_LINUX_2023 \
    --approval-rules '{
        "PatchRules": [{
            "PatchFilterGroup": {
                "PatchFilters": [
                    {"Key": "CLASSIFICATION", "Values": ["Security", "Bugfix"]},
                    {"Key": "SEVERITY", "Values": ["Critical", "Important"]}
                ]
            },
            "ApproveAfterDays": 7,
            "ComplianceLevel": "CRITICAL"
        }]
    }'

# Step 2: Create maintenance window (Saturdays 2-5 AM)
MW_ID=$(aws ssm create-maintenance-window --name "Prod-Patch-Window" \
    --schedule "cron(0 2 ? * SAT *)" \
    --duration 3 --cutoff 1 \
    --allow-unassociated-targets \
    --query 'WindowId' --output text)

# Step 3: Register targets (by tag)
aws ssm register-target-with-maintenance-window \
    --window-id $MW_ID \
    --resource-type INSTANCE \
    --targets Key=tag:Environment,Values=production

# Step 4: Register patching task
aws ssm register-task-with-maintenance-window \
    --window-id $MW_ID \
    --task-arn "AWS-RunPatchBaseline" \
    --task-type RUN_COMMAND \
    --max-concurrency "25%" \
    --max-errors "10%" \
    --task-invocation-parameters '{
        "RunCommand": {
            "Parameters": {"Operation": ["Install"]},
            "TimeoutSeconds": [3600]
        }
    }'

# Step 5: Check compliance
aws ssm describe-instance-patch-states \
    --instance-ids i-xxxx i-yyyy i-zzzz
```

---

## Real-Time Example 3: Parameter Store for Application Configuration

**Scenario:** Centralized configuration for microservices across environments.

```bash
# Hierarchical naming convention
aws ssm put-parameter --name "/myapp/prod/db/host" \
    --value "prod-db.xxxx.rds.amazonaws.com" --type String

aws ssm put-parameter --name "/myapp/prod/db/port" \
    --value "5432" --type String

aws ssm put-parameter --name "/myapp/prod/db/password" \
    --value "superSecret123" --type SecureString \
    --key-id alias/myapp-key

aws ssm put-parameter --name "/myapp/prod/feature-flags" \
    --value '{"darkMode": true, "newCheckout": false}' --type String

# Application retrieves all config at once
aws ssm get-parameters-by-path --path "/myapp/prod" --recursive --with-decryption

# Result: all 4 parameters returned in one API call!
# Application can cache locally and poll for changes

# Dev environment has different path
aws ssm put-parameter --name "/myapp/dev/db/host" \
    --value "dev-db.xxxx.rds.amazonaws.com" --type String
```

---

## Labs

### Lab 1: Run Command Across Fleet
```bash
# Install nginx on all instances tagged Web
aws ssm send-command \
    --targets Key=tag:Role,Values=WebServer \
    --document-name "AWS-RunShellScript" \
    --parameters commands=["yum install -y nginx","systemctl enable --now nginx"] \
    --max-concurrency "50%" \
    --max-errors "10%"

# Check command status
aws ssm list-command-invocations --command-id CMD_ID --details
```

### Lab 2: SSM Automation Runbook
```bash
# Create Golden AMI automation
aws ssm start-automation-execution \
    --document-name "AWS-CreateImage" \
    --parameters '{
        "InstanceId": ["i-xxxx"],
        "NoReboot": ["true"],
        "ImageName": ["golden-ami-{{global:DATE_TIME}}"]
    }'
```

### Lab 3: Inventory Collection
```bash
# Enable inventory collection
aws ssm create-association --name "AWS-GatherSoftwareInventory" \
    --targets Key=tag:Environment,Values=production \
    --schedule-expression "rate(1 day)"

# Query inventory
aws ssm get-inventory --filters Key=AWS:Application.Name,Values=nginx,Type=Equal
```

---

## Interview Questions

1. **What is Session Manager and why use it over SSH?**
   > Session Manager provides shell access without SSH keys, bastion hosts, or open ports. Access is IAM-controlled, all sessions are logged to CloudTrail/S3/CloudWatch. Works through VPC endpoints (no internet needed). Eliminates key management, reduces attack surface, enables centralized auditing.

2. **How does Run Command work?**
   > Send commands to instances using SSM documents (predefined or custom). Target by instance ID, tag, or resource group. Supports rate control (max concurrency) and error thresholds. Commands execute via the SSM agent on each instance. Results are captured and can be sent to S3/CloudWatch. No SSH needed.

3. **How would you implement automated patching?**
   > Create patch baselines (which patches to apply), maintenance windows (when to patch), and targets (which instances). Use `AWS-RunPatchBaseline` document. Set `maxConcurrency` to patch in waves (25% at a time). Monitor compliance with `describe-instance-patch-states`. Alert on non-compliant instances.

4. **Parameter Store vs Secrets Manager?**
   > Parameter Store: free tier, hierarchical organization, good for config values and feature flags. Secrets Manager: $0.40/secret/month, built-in automatic rotation, cross-account sharing, multi-region replication. Use Parameter Store for non-sensitive config, Secrets Manager for credentials that need rotation.

5. **How does SSM agent communication work without opening ports?**
   > SSM agent on the instance initiates an outbound HTTPS connection to SSM endpoints (port 443). The agent polls for commands. For private subnets, use VPC endpoints (ssm, ssmmessages, ec2messages). No inbound ports needed — all communication is agent-initiated outbound.

6. **What is State Manager?**
   > Ensures instances maintain a desired configuration state. Example: "CloudWatch agent must always be running on all production instances." If someone stops it, State Manager re-applies the configuration. Uses associations (document + targets + schedule). Like a lightweight configuration management tool.
