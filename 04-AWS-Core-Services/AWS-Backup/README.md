# AWS Backup — Centralized Backup Service

> Centralized backup management across AWS services with lifecycle policies and cross-region/account copies.

## Supported Services
S3, EBS, EFS, RDS, DynamoDB, Aurora, EC2 (AMI), FSx, Storage Gateway, DocumentDB, Neptune

## Key Concepts
- **Backup Plan** — schedule, lifecycle, vault assignment
- **Backup Vault** — encrypted container for backups (KMS)
- **Backup Rules** — frequency, retention, copy to another region
- **Recovery Points** — individual backup snapshots

## Labs
```bash
# Create backup vault
aws backup create-backup-vault --backup-vault-name prod-vault

# Create backup plan (daily, 30-day retention)
aws backup create-backup-plan --backup-plan '{
    "BackupPlanName": "DailyBackups",
    "Rules": [{
        "RuleName": "DailyRule",
        "ScheduleExpression": "cron(0 3 * * ? *)",
        "StartWindowMinutes": 60,
        "CompletionWindowMinutes": 180,
        "TargetBackupVaultName": "prod-vault",
        "Lifecycle": {
            "DeleteAfterDays": 30,
            "MoveToColdStorageAfterDays": 7
        },
        "CopyActions": [{
            "DestinationBackupVaultArn": "arn:aws:backup:eu-west-1:ACCT:backup-vault:dr-vault",
            "Lifecycle": {"DeleteAfterDays": 90}
        }]
    }]
}'

# Assign resources by tag
aws backup create-backup-selection --backup-plan-id PLAN_ID \
    --backup-selection '{
        "SelectionName": "TaggedResources",
        "IamRoleArn": "arn:aws:iam::ACCT:role/AWSBackupRole",
        "ListOfTags": [{
            "ConditionType": "STRINGEQUALS",
            "ConditionKey": "Backup",
            "ConditionValue": "daily"
        }]
    }'
```
