# EBS — Elastic Block Store

> Block-level storage volumes for EC2 instances. Think of it as the "hard drive" that you attach to your virtual server.

---

## Real-World Analogy

EBS is like an **external hard drive** for your computer:
- You can attach it, detach it, and reattach it to a different computer
- **gp3** = SSD (fast, general use — your laptop's main drive)
- **io2** = NVMe SSD (ultra-fast — gaming PC or database server)
- **st1** = HDD (slower but cheap — storing old movies)
- **Snapshots** = creating a backup image of your hard drive (you can restore anytime)
- Unlike your computer's built-in drive (Instance Store), EBS persists even if the EC2 is stopped

---

## Volume Types

| Type | IOPS | Throughput | Cost | Use Case | Real-World Example |
|------|------|------------|------|----------|-------------------|
| **gp3** | 3,000-16,000 | 125-1,000 MB/s | $0.08/GB | General purpose (default) | Web servers, dev environments, small databases |
| **gp2** | Up to 16,000 | Up to 250 MB/s | $0.10/GB | Legacy general purpose | Existing workloads (migrate to gp3) |
| **io2 Block Express** | Up to 256,000 | Up to 4,000 MB/s | $0.125/GB | Mission-critical databases | Oracle, SAP HANA, real-time trading |
| **io2** | Up to 64,000 | Up to 1,000 MB/s | $0.125/GB | High-performance databases | Production MySQL, PostgreSQL with heavy writes |
| **st1** | Up to 500 | Up to 500 MB/s | $0.045/GB | Throughput-optimized HDD | Big data, log processing, Kafka |
| **sc1** | Up to 250 | Up to 250 MB/s | $0.015/GB | Cold storage HDD | Infrequent access, archival data |

---

## Real-Time Example 1: Database Volume Optimization

**Scenario:** Your PostgreSQL database is slow. You're running on gp2 with 100GB.

```
Current: gp2 100GB → 300 IOPS (baseline) → Database is IO-starved during peak
Problem: gp2 IOPS scales with volume size (3 IOPS per GB)
         To get 3000 IOPS on gp2, you'd need 1,000 GB ($100/month for unused space!)

Solution: Migrate to gp3
- gp3 100GB → 3,000 IOPS baseline (10x more!) + 125 MB/s throughput
- Independently configure up to 16,000 IOPS
- Cost: $8/month (gp3) vs $10/month (gp2) — cheaper AND faster!
```

```bash
# Modify volume from gp2 to gp3 with 5000 IOPS (no downtime!)
aws ec2 modify-volume --volume-id vol-xxxx \
    --volume-type gp3 --iops 5000 --throughput 250

# Monitor modification progress
aws ec2 describe-volumes-modifications --volume-ids vol-xxxx
```

**Explanation:** This is a real optimization companies do. gp3 gives you 3,000 baseline IOPS regardless of volume size. With gp2, you had to over-provision storage to get IOPS. Migration to gp3 is live (no downtime).

---

## Real-Time Example 2: Automated Snapshot Backup & Cross-Region DR

**Scenario:** You need daily backups of your production database volume, and copies in another region for disaster recovery.

```
Daily at 2 AM:
EBS Volume (us-east-1) → Snapshot → Copy to EU-West-1 → Delete snapshots older than 30 days

       us-east-1                         eu-west-1
    ┌──────────────┐                 ┌──────────────┐
    │  EBS vol-xxxx │                 │  DR Snapshot  │
    │  (Production) │ ──Snapshot──► │  (30 days)    │
    └──────────────┘                 └──────────────┘
```

```bash
# Create snapshot with description
SNAP_ID=$(aws ec2 create-snapshot --volume-id vol-xxxx \
    --description "Daily backup $(date +%Y%m%d)" \
    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Backup,Value=daily},{Key=Retention,Value=30}]' \
    --query 'SnapshotId' --output text)

# Copy to DR region
aws ec2 copy-snapshot --source-region us-east-1 \
    --source-snapshot-id $SNAP_ID \
    --destination-region eu-west-1 \
    --description "DR copy - $(date +%Y%m%d)" \
    --encrypted --kms-key-id alias/dr-key

# Delete snapshots older than 30 days (cleanup script)
aws ec2 describe-snapshots --owner-ids self \
    --filters "Name=tag:Backup,Values=daily" \
    --query "Snapshots[?StartTime<='$(date -d '30 days ago' +%Y-%m-%d)'].SnapshotId" \
    --output text | tr '\t' '\n' | while read snap; do
        aws ec2 delete-snapshot --snapshot-id $snap
    done
```

---

## Real-Time Example 3: Encrypting an Existing Unencrypted Volume

**Scenario:** Security audit finds your production database volume is unencrypted. You need to encrypt it with minimal downtime.

```
Step 1: Create snapshot of unencrypted volume
Step 2: Copy snapshot with encryption enabled (creates encrypted snapshot)
Step 3: Create new encrypted volume from encrypted snapshot
Step 4: Stop instance → detach old volume → attach new encrypted volume → start instance
```

```bash
# Step 1: Snapshot the unencrypted volume
SNAP=$(aws ec2 create-snapshot --volume-id vol-unencrypted \
    --description "Encrypt migration" --query 'SnapshotId' --output text)

aws ec2 wait snapshot-completed --snapshot-ids $SNAP

# Step 2: Copy with encryption
ENC_SNAP=$(aws ec2 copy-snapshot --source-region us-east-1 \
    --source-snapshot-id $SNAP \
    --encrypted --kms-key-id alias/ebs-key \
    --description "Encrypted copy" --query 'SnapshotId' --output text)

# Step 3: Create encrypted volume
ENC_VOL=$(aws ec2 create-volume --snapshot-id $ENC_SNAP \
    --volume-type gp3 --availability-zone us-east-1a \
    --encrypted --kms-key-id alias/ebs-key \
    --query 'VolumeId' --output text)

# Step 4: Swap volumes (requires brief downtime)
aws ec2 stop-instances --instance-ids i-xxxx
aws ec2 wait instance-stopped --instance-ids i-xxxx
aws ec2 detach-volume --volume-id vol-unencrypted
aws ec2 attach-volume --volume-id $ENC_VOL --instance-id i-xxxx --device /dev/xvda
aws ec2 start-instances --instance-ids i-xxxx
```

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Snapshots** | Point-in-time backup to S3, incremental | First snap: 100GB. Second snap: only changed blocks (5GB) |
| **Encryption** | AES-256 via KMS | Mandatory for HIPAA/PCI compliance |
| **Multi-Attach** | io2 volumes to multiple instances | Shared volume for clustered databases |
| **EBS-Optimized** | Dedicated throughput to EBS | Default for most modern instance types |
| **Elastic Volumes** | Modify type/size/IOPS live | Increase from 100GB to 500GB without downtime |
| **Fast Snapshot Restore** | Eliminate initialization penalty | New volume from snapshot immediately at full performance |

---

## Labs

### Lab 1: Create and Attach Encrypted gp3 Volume
```bash
# Create encrypted gp3 volume
VOL_ID=$(aws ec2 create-volume --volume-type gp3 --size 100 \
    --iops 5000 --throughput 250 \
    --encrypted --kms-key-id alias/ebs-key \
    --availability-zone us-east-1a \
    --query 'VolumeId' --output text)

# Attach to instance
aws ec2 attach-volume --volume-id $VOL_ID \
    --instance-id i-xxxx --device /dev/xvdf

# On the EC2 instance: format and mount
sudo mkfs -t xfs /dev/xvdf
sudo mkdir /data
sudo mount /dev/xvdf /data
echo "/dev/xvdf /data xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab
```

### Lab 2: Snapshot and Cross-Region Copy
```bash
# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxxx \
    --description "Daily backup $(date +%Y%m%d)"

# Copy to DR region
aws ec2 copy-snapshot --source-region us-east-1 \
    --source-snapshot-id snap-xxxx --destination-region eu-west-1
```

### Lab 3: Live Volume Modification
```bash
# Increase volume size and IOPS without downtime
aws ec2 modify-volume --volume-id vol-xxxx \
    --size 200 --iops 8000 --throughput 500

# On the EC2 instance: extend the filesystem
sudo xfs_growfs /data    # for XFS
sudo resize2fs /dev/xvdf  # for ext4
```

---

## Interview Questions

1. **gp3 vs gp2 — why is gp3 preferred?**
   > gp3: 3,000 baseline IOPS regardless of size, independently configurable IOPS and throughput, 20% cheaper. gp2: IOPS tied to volume size (3 per GB), must over-provision. Always use gp3 for new volumes.

2. **How do EBS snapshots work (incremental)?**
   > First snapshot copies entire volume. Subsequent snapshots only copy changed blocks. A 100GB volume with 5GB changes = 5GB snapshot. Snapshots are stored in S3 (managed by AWS). You can delete old snapshots — AWS handles block dependencies.

3. **How to encrypt an existing unencrypted volume?**
   > Snapshot → Copy snapshot with encryption → Create volume from encrypted snapshot → Stop instance → Swap volumes. You cannot directly encrypt an existing volume. Requires brief downtime for the swap.

4. **EBS vs Instance Store — when to use each?**
   > EBS: persistent, survives stop/start, can be backed up, recommended for databases and applications. Instance Store: ephemeral (lost on stop), higher IOPS, dirt cheap — use for cache, temp files, swap.

5. **What is Multi-Attach and when would you use it?**
   > io2 volumes can be attached to up to 16 instances in the same AZ. Use for clustered applications (Oracle RAC). Both instances can read/write — app must handle concurrent access (cluster-aware filesystem).

6. **How do you monitor EBS performance?**
   > CloudWatch metrics: VolumeReadOps, VolumeWriteOps, VolumeQueueLength. If QueueLength > 1, the volume is IO-starved. Solution: upgrade volume type or increase IOPS.

7. **What is Fast Snapshot Restore and when do you need it?**
   > Normally, volumes from snapshots undergo initialization (first-read is slow). FSR pre-initializes the volume at full performance immediately. Use for databases that need instant full performance after restore.

8. **How do you handle EBS in a multi-AZ architecture?**
   > EBS is AZ-locked. For multi-AZ, use snapshots to create volumes in other AZs, or use EFS (multi-AZ by default). For databases, use RDS Multi-AZ instead of managing EBS replication manually.
