# Storage Gateway — Hybrid Cloud Storage

> Bridge between on-premises data and AWS cloud storage. Seamless integration of local applications with S3, FSx, and EBS. The "translator" between your data center and AWS.

---

## Real-World Analogy

Storage Gateway is like a **bilingual assistant between two offices**:
- Your on-premise apps speak "local file system" or "iSCSI"
- AWS speaks "S3, EBS, Glacier"
- Storage Gateway sits in between, translating seamlessly
- Local apps think they're using a normal file share or disk
- Behind the scenes, data is stored in AWS (with local cache for speed)

---

## Gateway Types

| Gateway Type | Protocol | Backend | Use Case |
|-------------|----------|---------|----------|
| **S3 File Gateway** | NFS / SMB | S3 (all tiers) | File shares backed by S3 |
| **FSx File Gateway** | SMB | Amazon FSx for Windows | Windows file shares with low-latency local cache |
| **Volume Gateway — Cached** | iSCSI | S3 + EBS snapshots | Block storage with S3 backend, local cache |
| **Volume Gateway — Stored** | iSCSI | Local + async S3 backup | Full dataset local, async backup to S3 |
| **Tape Gateway** | iSCSI VTL | S3 Glacier / Deep Archive | Replace physical tape libraries |

```
S3 File Gateway:
┌──────────────┐     NFS/SMB      ┌─────────────────┐    S3 API    ┌─────────┐
│ On-Premise   │ ──────────────▶  │  Storage Gateway │ ──────────▶ │   S3    │
│ Applications │                  │  (VM or HW)      │             │ Bucket  │
│              │ ◀── local cache  │  Cache: 150 GB+  │             │         │
└──────────────┘                  └─────────────────┘             └─────────┘

Volume Gateway (Cached):
┌──────────────┐     iSCSI        ┌─────────────────┐   blocks    ┌─────────┐
│ On-Premise   │ ──────────────▶  │  Storage Gateway │ ──────────▶│   S3    │
│ DB / App     │                  │  Cache: hot data │             │(volumes)│
│ Server       │ ◀── block I/O    │  Upload buffer   │             │         │
└──────────────┘                  └─────────────────┘             └─────────┘
                                         │
                                    EBS Snapshots
                                         │
                                  ┌──────▼──────┐
                                  │ EBS Volumes  │ (mountable on EC2)
                                  └─────────────┘

Tape Gateway:
┌──────────────┐     iSCSI VTL    ┌─────────────────┐             ┌─────────┐
│ Backup App   │ ──────────────▶  │  Storage Gateway │ ──────────▶│ S3      │
│ (Veeam,      │                  │  (Virtual Tape   │             │ Glacier │
│  NetBackup)  │                  │   Library)       │             │         │
└──────────────┘                  └─────────────────┘             └─────────┘
```

---

## Deployment Options

| Option | Description |
|--------|-------------|
| **VMware ESXi** | Deploy as VM on existing VMware infrastructure |
| **Microsoft Hyper-V** | Deploy as VM on Hyper-V |
| **Linux KVM** | Deploy as VM on KVM hypervisor |
| **EC2 Instance** | Deploy in AWS (for cloud-to-cloud or testing) |
| **Hardware Appliance** | Pre-configured Dell server from AWS |

### Minimum Requirements
- 4 vCPUs, 16 GB RAM (File Gateway)
- Cache disk: 150 GB minimum (SSD recommended)
- Upload buffer: 150 GB minimum
- Network: stable connection to AWS (Direct Connect recommended for production)

---

## Real-Time Example 1: File Share Migration to S3

**Scenario:** Company has 20 TB of files on a Windows file server. Users need continued SMB access while migrating to S3.

```bash
# Step 1: Deploy S3 File Gateway VM
# Download OVA from AWS Console → deploy on VMware

# Step 2: Activate gateway
aws storagegateway activate-gateway \
    --activation-key XXXXX-XXXXX-XXXXX \
    --gateway-name "office-file-gateway" \
    --gateway-timezone "GMT-5:00" \
    --gateway-type "FILE_S3" \
    --gateway-region us-east-1

# Step 3: Add cache disk
aws storagegateway add-cache \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345 \
    --disk-ids "/dev/sdb"

# Step 4: Create NFS/SMB file share
aws storagegateway create-smb-file-share \
    --client-token unique-token-123 \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345 \
    --role arn:aws:iam::ACCT:role/StorageGatewayS3Role \
    --location-arn arn:aws:s3:::company-file-archive \
    --default-storage-class S3_INTELLIGENT_TIERING \
    --authentication GuestAccess

# Step 5: Mount on Windows clients
# NET USE Z: \\192.168.1.50\company-file-archive

# Users see a normal Z: drive
# Files automatically sync to S3
# Hot files cached locally for fast access
# Old files in S3 Intelligent-Tiering save 40%+ on storage
```

---

## Real-Time Example 2: Volume Gateway for Database Backup

**Scenario:** On-premise SQL Server needs block-level backup to AWS for disaster recovery.

```bash
# Deploy Volume Gateway (Cached mode)
# Create cached volume
aws storagegateway create-cached-iscsi-volume \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345 \
    --volume-size-in-bytes 1099511627776 \
    --target-name "sqlserver-data" \
    --network-interface-id 192.168.1.50 \
    --client-token sql-vol-001

# On-premise server mounts iSCSI volume
# SQL Server stores database files on the volume
# Data automatically replicated to S3

# Create snapshot for point-in-time recovery
aws storagegateway create-snapshot \
    --volume-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345/volume/vol-12345 \
    --snapshot-description "SQL Server daily backup"

# DR scenario: Create EBS volume from snapshot → attach to EC2
aws ec2 create-volume \
    --snapshot-id snap-12345 \
    --availability-zone us-east-1a \
    --volume-type gp3

# Mount on EC2 SQL Server instance → database restored
```

---

## Real-Time Example 3: Tape Gateway Replacing Physical Tapes

**Scenario:** Company spends $50K/year on physical tape storage (Iron Mountain). Replace with virtual tapes in Glacier.

```bash
# Deploy Tape Gateway
# Configure backup software (Veeam, NetBackup) to use VTL

# Create virtual tape
aws storagegateway create-tapes \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345 \
    --tape-size-in-bytes 107374182400 \
    --client-token tape-001 \
    --num-tapes-to-create 10 \
    --tape-barcode-prefix "BAK"

# Backup software writes to virtual tapes (same as physical)
# Tapes archived to S3 Glacier automatically

# List available tapes
aws storagegateway list-tapes \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345

# Retrieve archived tape (takes 3-5 hours from Glacier)
aws storagegateway retrieve-tape-archive \
    --tape-arn arn:aws:storagegateway:us-east-1:ACCT:tape/BAK001 \
    --gateway-arn arn:aws:storagegateway:us-east-1:ACCT:gateway/sgw-12345

# Cost savings:
# Physical tape: $50K/year (media + Iron Mountain + management)
# Tape Gateway:  $5K/year (Glacier storage + data transfer)
# Savings: 90%
```

---

## Labs

### Lab 1: Deploy File Gateway on EC2 (Lab Environment)
```bash
# Launch Storage Gateway AMI on EC2
aws ec2 run-instances \
    --image-id ami-storagegateway \
    --instance-type m5.xlarge \
    --subnet-id subnet-private \
    --security-group-ids sg-gateway \
    --block-device-mappings '[
      {"DeviceName":"/dev/sdb","Ebs":{"VolumeSize":150,"VolumeType":"gp3"}},
      {"DeviceName":"/dev/sdc","Ebs":{"VolumeSize":150,"VolumeType":"gp3"}}
    ]'

# Activate gateway through console
# Add cache and upload buffer disks
# Create SMB/NFS file share pointing to S3 bucket
# Mount from another EC2 instance and test file operations
# Verify files appear in S3 bucket
```

### Lab 2: Test Cached Volume Gateway
```bash
# Create cached iSCSI volume
# Connect from EC2 Linux instance using iSCSI initiator
# Write data to volume
# Create snapshot
# Create EBS volume from snapshot
# Mount on new EC2 instance → verify data integrity
```

### Lab 3: Monitor Gateway Performance
```bash
# Check CloudWatch metrics for gateway
aws cloudwatch get-metric-statistics \
    --namespace AWS/StorageGateway \
    --metric-name CacheHitPercent \
    --dimensions Name=GatewayId,Value=sgw-12345 \
    --start-time 2025-12-01T00:00:00Z \
    --end-time 2025-12-02T00:00:00Z \
    --period 3600 \
    --statistics Average

# Monitor: CacheHitPercent, CachePercentUsed, UploadBufferPercentUsed
# Set alarms for low cache hit rate or high buffer usage
```

---

## Interview Questions

1. **When would you use Storage Gateway vs direct S3 uploads?**
   → When on-premise applications need standard file protocols (NFS/SMB/iSCSI) and can't be modified to use S3 APIs. Gateway provides transparent caching + cloud backend.

2. **Explain the difference between Cached and Stored Volume Gateway.**
   → Cached: primary data in S3, hot data cached locally (better for large datasets). Stored: full dataset local, async backup to S3 (better when low-latency access to ALL data is needed).

3. **What is a Tape Gateway?**
   → Virtual Tape Library (VTL) that emulates physical tape infrastructure. Backup software writes to virtual tapes that are stored in S3/Glacier. Eliminates physical tape costs.

4. **How does File Gateway handle caching?**
   → Recently accessed files cached on local SSD. Cache size determines how much hot data stays local. Cache miss triggers download from S3. Write-back cache for new/modified files.

5. **Can you use S3 lifecycle policies with File Gateway?**
   → Yes. Files written via gateway land in S3 Standard. Lifecycle rules can transition to IA, Glacier, etc. But gateway only caches — retrieval from Glacier requires restore first.

6. **What network connectivity does Storage Gateway need?**
   → HTTPS to AWS endpoints (port 443). Recommended: AWS Direct Connect for consistent performance. Minimum 100 Mbps for production workloads.

7. **How do you handle disaster recovery with Volume Gateway?**
   → Create EBS snapshots from gateway volumes. In DR: create EBS volumes from snapshots → attach to EC2 instances. RTO depends on volume size and snapshot creation frequency.

8. **S3 File Gateway vs FSx File Gateway — when to use each?**
   → S3 File Gateway: Linux/NFS or basic SMB, need S3 integration, lifecycle tiering. FSx File Gateway: Windows-native SMB with AD integration, NTFS permissions, DFS namespaces.
