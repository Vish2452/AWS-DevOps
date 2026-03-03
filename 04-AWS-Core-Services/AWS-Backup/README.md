# AWS Backup — Centralized Backup Service

> Centralized backup management across AWS services with lifecycle policies, cross-region/account copies, and compliance reporting. Your "insurance policy" for AWS data.

---

## Real-World Analogy

AWS Backup is like a **professional document archival company**:
- You say: "Back up my important documents every day at 3 AM"
- They handle pickup (backup), storage (vault), organization (tags), and disaster copies (cross-region)
- They move old documents to cheaper storage after 30 days (lifecycle)
- They send copies to a second warehouse in another city (cross-region DR)
- You get a report showing all backup activity (compliance)

---

## Supported Services

| Service | What Gets Backed Up | Example |
|---------|-------------------|---------|
| **EC2** | AMI (full machine image) | Production web server snapshot |
| **EBS** | Volume snapshots | Database disk backup |
| **RDS** | DB snapshots | PostgreSQL database backup |
| **Aurora** | Cluster snapshots | Aurora cluster backup |
| **DynamoDB** | Table backup | NoSQL table with all data |
| **EFS** | File system backup | Shared file system backup |
| **S3** | Bucket backup | Object storage backup |
| **FSx** | File system backup | Windows/Lustre file system |
| **Storage Gateway** | Volume backup | On-premises storage |
| **DocumentDB** | Cluster snapshot | MongoDB-compatible DB |
| **Neptune** | Graph DB snapshot | Graph database backup |
| **Redshift** | Cluster snapshot | Data warehouse backup |
| **SAP HANA** | Database backup | Enterprise SAP systems |

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Backup Plan** | Schedule + lifecycle + vault assignment | "Daily at 3 AM, keep 30 days, copy to DR region" |
| **Backup Vault** | Encrypted container for backups (KMS) | Separate vaults for prod vs dev |
| **Backup Rules** | Frequency, retention, cross-region copy | Daily + weekly + monthly schedules |
| **Recovery Points** | Individual backup snapshots | "Restore to March 1st, 2026 at 3:00 AM" |
| **Backup Selection** | Which resources to back up (by tag) | All resources tagged `Backup=daily` |
| **Vault Lock** | WORM (Write Once Read Many) — immutable | Compliance: nobody can delete backups for 1 year |
| **Audit Manager** | Compliance reporting | Generate SOC2/HIPAA backup compliance report |

---

## Real-Time Example 1: Enterprise Backup Strategy

**Scenario:** Your company runs a 3-tier application (EC2 + RDS + S3). You need a backup strategy with:
- Daily backups retained for 30 days
- Weekly backups retained for 3 months
- Monthly backups retained for 1 year
- Cross-region copies for disaster recovery

```
Backup Plan: "Enterprise-3-Tier"
│
├── Rule 1: Daily at 3 AM UTC
│   ├── Retention: 30 days
│   ├── Move to cold storage: after 7 days
│   └── Copy to eu-west-1 (DR): retained 30 days
│
├── Rule 2: Weekly (Sunday 2 AM UTC)
│   ├── Retention: 90 days
│   ├── Move to cold storage: after 14 days
│   └── Copy to eu-west-1 (DR): retained 90 days
│
└── Rule 3: Monthly (1st of month, 1 AM UTC)
    ├── Retention: 365 days
    ├── Move to cold storage: after 30 days
    └── Copy to eu-west-1 (DR): retained 365 days

Resources: All tagged with Backup=enterprise
├── EC2 instances (web servers, app servers)
├── RDS databases (primary + read replicas)
├── EFS file systems
└── S3 buckets (customer data)
```

---

## Real-Time Example 2: Compliance with Vault Lock

**Scenario:** Your healthcare company must comply with HIPAA. Regulators require that backup data cannot be deleted for 7 years, even by administrators.

```bash
# Create a vault with lock (WORM — nobody can delete)
aws backup create-backup-vault --backup-vault-name hipaa-compliance-vault \
    --encryption-key-arn arn:aws:kms:us-east-1:ACCT:key/xxxx

# Apply vault lock policy (irreversible after grace period!)
aws backup put-backup-vault-lock-configuration \
    --backup-vault-name hipaa-compliance-vault \
    --min-retention-days 2555 \
    --max-retention-days 2920 \
    --changeable-for-days 3

# After 3 days, this lock becomes PERMANENT
# Even the root account CANNOT delete backups before 2555 days (7 years)
```

**Explanation:** Vault Lock creates an immutable backup policy. Once the grace period expires, even AWS Support cannot modify it. This satisfies compliance requirements where data must be retained for specific periods and protected from tampering.

---

## Real-Time Example 3: Automated Restore Testing

**Scenario:** Having backups is useless if they don't work. You need to periodically test restores.

```bash
# Step 1: Get the latest recovery point
RECOVERY_POINT=$(aws backup list-recovery-points-by-backup-vault \
    --backup-vault-name prod-vault \
    --by-resource-type RDS \
    --max-results 1 \
    --query 'RecoveryPoints[0].RecoveryPointArn' --output text)

# Step 2: Start a restore job
aws backup start-restore-job \
    --recovery-point-arn $RECOVERY_POINT \
    --iam-role-arn arn:aws:iam::ACCT:role/AWSBackupRestoreRole \
    --metadata '{
        "DBInstanceIdentifier": "restore-test-db",
        "DBInstanceClass": "db.t3.medium",
        "DBSubnetGroupName": "test-subnets"
    }'

# Step 3: Verify the restore
# Run automated tests against restore-test-db

# Step 4: Clean up test resource
aws rds delete-db-instance --db-instance-identifier restore-test-db \
    --skip-final-snapshot
```

**Explanation:** Many companies discover their backups are corrupted only when they need to restore (worst time to find out!). Schedule monthly restore tests — restore to a test environment, run validation queries, then clean up.

---

## Labs

### Lab 1: Create Complete Backup Plan
```bash
# Create backup vault
aws backup create-backup-vault --backup-vault-name prod-vault

# Create backup plan with daily + weekly rules
PLAN_ID=$(aws backup create-backup-plan --backup-plan '{
    "BackupPlanName": "Production-Backup",
    "Rules": [
        {
            "RuleName": "DailyBackup",
            "ScheduleExpression": "cron(0 3 * * ? *)",
            "StartWindowMinutes": 60,
            "CompletionWindowMinutes": 180,
            "TargetBackupVaultName": "prod-vault",
            "Lifecycle": {
                "MoveToColdStorageAfterDays": 7,
                "DeleteAfterDays": 30
            },
            "CopyActions": [{
                "DestinationBackupVaultArn": "arn:aws:backup:eu-west-1:ACCT:backup-vault:dr-vault",
                "Lifecycle": {"DeleteAfterDays": 30}
            }]
        },
        {
            "RuleName": "WeeklyBackup",
            "ScheduleExpression": "cron(0 2 ? * SUN *)",
            "StartWindowMinutes": 120,
            "TargetBackupVaultName": "prod-vault",
            "Lifecycle": {
                "MoveToColdStorageAfterDays": 14,
                "DeleteAfterDays": 90
            }
        }
    ]
}' --query 'BackupPlanId' --output text)
```

### Lab 2: Assign Resources by Tag
```bash
# Back up all resources tagged Backup=daily
aws backup create-backup-selection --backup-plan-id $PLAN_ID \
    --backup-selection '{
        "SelectionName": "TaggedResources",
        "IamRoleArn": "arn:aws:iam::ACCT:role/AWSBackupRole",
        "ListOfTags": [{
            "ConditionType": "STRINGEQUALS",
            "ConditionKey": "Backup",
            "ConditionValue": "daily"
        }]
    }'

# Tag your resources
aws ec2 create-tags --resources i-xxxx --tags Key=Backup,Value=daily
aws rds add-tags-to-resource \
    --resource-name arn:aws:rds:us-east-1:ACCT:db:prod-db \
    --tags Key=Backup,Value=daily
```

### Lab 3: Monitor Backup Jobs
```bash
# List recent backup jobs
aws backup list-backup-jobs \
    --by-state COMPLETED \
    --max-results 10

# Get job details
aws backup describe-backup-job --backup-job-id JOB_ID

# Set up SNS notification for backup failures
aws backup put-backup-vault-notifications \
    --backup-vault-name prod-vault \
    --sns-topic-arn arn:aws:sns:us-east-1:ACCT:backup-alerts \
    --backup-vault-events BACKUP_JOB_FAILED RESTORE_JOB_COMPLETED
```

---

## Backup Strategy Recommendations

| Environment | Frequency | Retention | Cross-Region | Vault Lock |
|-------------|-----------|-----------|--------------|------------|
| **Development** | Daily | 7 days | No | No |
| **Staging** | Daily | 14 days | No | No |
| **Production** | Daily + Weekly + Monthly | 30/90/365 days | Yes (DR) | Recommended |
| **Compliance** | Daily + Monthly | 1-7 years | Yes | Required (WORM) |

---

## Interview Questions

1. **What is AWS Backup and why not just use native snapshots?**
   > AWS Backup provides centralized management across 15+ services. Instead of writing separate scripts for EC2 snapshots, RDS backups, EFS backups — one backup plan handles everything. Also provides cross-region/account copies, lifecycle management, and compliance reporting.

2. **How does AWS Backup cross-region copy work?**
   > Each backup rule can include a CopyAction that replicates recovery points to a vault in another region. Happens automatically after each backup. Essential for disaster recovery — if us-east-1 goes down, your data is safe in eu-west-1.

3. **What is Vault Lock and when is it required?**
   > WORM protection that prevents anyone (even root account) from deleting backups before the retention period. Required for HIPAA, SEC Rule 17a-4, and financial regulations. Once locked after the grace period, it's irreversible.

4. **How do you select which resources to back up?**
   > By tag (e.g., `Backup=daily`), by resource ARN, or by resource type. Tag-based selection is best because new resources automatically get backed up when tagged. Promotes consistency across the organization.

5. **What is the difference between warm and cold storage in AWS Backup?**
   > Warm: faster restore (minutes), higher cost. Cold: cheaper storage, slower restore (hours). Lifecycle policies auto-move backups from warm to cold after N days. Use cold for long-retention archives.

6. **How would you test that backups are working?**
   > Schedule monthly restore tests: restore backup to a test environment, run validation queries/checks, verify data integrity, then clean up. AWS Backup provides restore job monitoring. Some companies automate this with Lambda + Step Functions.

7. **Can AWS Backup work across AWS accounts?**
   > Yes. Use AWS Organizations + backup policies to manage backups centrally. Copy backups to a central backup account for additional protection. The central account can have Vault Lock so individual accounts can't delete their backups.

8. **How do you handle backup failures?**
   > Configure SNS notifications on backup vault for BACKUP_JOB_FAILED events. Create CloudWatch alarms for failed job metrics. Investigate common causes: insufficient IAM permissions, resource in wrong state, KMS key access issues.
