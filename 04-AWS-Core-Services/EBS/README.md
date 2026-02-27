# EBS — Elastic Block Store

> Block-level storage volumes for EC2 instances. Choose the right volume type for your workload.

## Volume Types
| Type | IOPS | Throughput | Use Case |
|------|------|------------|----------|
| **gp3** | 3,000-16,000 | 125-1,000 MB/s | General purpose (default) |
| **gp2** | Up to 16,000 | Up to 250 MB/s | Legacy general purpose |
| **io2** | Up to 64,000 | Up to 1,000 MB/s | High-performance databases |
| **st1** | Up to 500 | Up to 500 MB/s | Big data, streaming |
| **sc1** | Up to 250 | Up to 250 MB/s | Cold storage, infrequent |

## Key Concepts
- **Snapshots** — point-in-time backup to S3, incremental
- **Encryption** — AES-256 via KMS, encrypt at creation
- **Multi-Attach** — io2 volumes can attach to multiple instances
- **EBS-Optimized instances** — dedicated throughput to EBS

## Labs
```bash
# Create encrypted gp3 volume
aws ec2 create-volume --volume-type gp3 --size 100 \
    --iops 5000 --throughput 250 \
    --encrypted --kms-key-id alias/ebs-key \
    --availability-zone us-east-1a

# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxxx \
    --description "Daily backup $(date +%Y%m%d)"

# Copy snapshot cross-region (DR)
aws ec2 copy-snapshot --source-region us-east-1 \
    --source-snapshot-id snap-xxxx --destination-region eu-west-1
```

## Interview Questions
1. gp3 vs gp2 — why is gp3 preferred?
2. How do EBS snapshots work (incremental)?
3. How to encrypt an existing unencrypted volume?
4. EBS vs Instance Store — when to use each?
