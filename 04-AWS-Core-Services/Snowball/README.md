# Snowball — Physical Data Transfer

> Move terabytes to petabytes of data into/out of AWS using physical devices. When the internet is too slow, ship a hard drive.

---

## Real-World Analogy

Snowball is like **hiring a moving truck instead of mailing boxes one by one**:
- Uploading 100 TB over a 1 Gbps connection = ~12 days (non-stop)
- Uploading 100 TB over 100 Mbps = ~120 days
- Snowball: ship a device, load data, ship it back = ~1 week total
- "Never underestimate the bandwidth of a truck full of hard drives"

---

## Snow Family Devices

| Device | Capacity | Use Case | Compute |
|--------|----------|----------|---------|
| **Snowcone** | 8 TB (HDD) / 14 TB (SSD) | Edge computing, small migrations | 2 vCPUs, 4 GB RAM |
| **Snowball Edge Storage** | 80 TB usable | Large migrations, edge storage | 40 vCPUs, 80 GB RAM |
| **Snowball Edge Compute** | 42 TB usable | Edge ML, processing | 52 vCPUs, 208 GB RAM, optional GPU |
| **Snowmobile** | 100 PB | Exabyte-scale DC migration | Literal shipping container truck |

```
When to use which:

                  ┌─────────────┐
   Data Size?     │             │
                  └──────┬──────┘
                         │
            ┌────────────┼───────────────┐
            │            │               │
        < 10 TB     10 TB - 10 PB    > 10 PB
            │            │               │
        Snowcone    Snowball Edge    Snowmobile
                    (Storage or       (truck)
                     Compute)
```

---

## How Snowball Works

```
Step 1: Order               Step 2: Receive           Step 3: Load
┌──────────────┐           ┌──────────────┐          ┌──────────────┐
│ AWS Console  │           │  Device      │          │ snowball cp   │
│ Create Job   │──ship──▶  │  arrives at  │──load──▶ │ data to      │
│              │           │  your site   │          │ device       │
└──────────────┘           └──────────────┘          └──────────────┘
                                                            │
Step 6: Data in S3         Step 5: Import            Step 4: Ship back
┌──────────────┐           ┌──────────────┐          ┌──────────────┐
│ S3 bucket    │◀──copy──  │ AWS facility │◀──ship── │ Schedule UPS │
│ available    │           │ processes    │          │ pickup       │
└──────────────┘           └──────────────┘          └──────────────┘
```

### Data Security
- **256-bit encryption** — data encrypted before leaving your premises
- **Tamper-resistant enclosure** — physical security
- **TPM (Trusted Platform Module)** — hardware security chip
- **AWS KMS keys** — you control the encryption keys
- **Erased after transfer** — NIST 800-88 media sanitization
- **E-Ink shipping label** — no USB or external access during transit

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Import to S3** | Copy on-premise data to Snowball → ship to AWS → data lands in S3 |
| **Export from S3** | AWS copies S3 data to Snowball → ships to you → copy locally |
| **Edge Computing** | Run EC2 instances or Lambda functions on the device at remote sites |
| **Clustering** | Group multiple Snowball Edge devices for large local storage (up to 45 TB × N) |
| **OpsHub** | GUI application to manage Snow devices, transfer data, launch instances |
| **S3 Adapter** | S3-compatible endpoint on the device for data transfer |
| **NFS Mount** | Mount Snowball as a network file share for drag-and-drop transfers |

---

## Real-Time Example 1: Data Center Migration (100 TB)

**Scenario:** Company closing on-premise data center. Need to move 100 TB of archive data to S3 Glacier.

```bash
# Step 1: Create Snowball import job
aws snowball create-job \
    --job-type IMPORT \
    --resources '{"S3Resources":[{"BucketArn":"arn:aws:s3:::dc-migration-archive"}]}' \
    --address-id ADID-12345 \
    --role-arn arn:aws:iam::ACCT:role/SnowballImportRole \
    --snowball-type EDGE \
    --shipping-option SECOND_DAY \
    --kms-key-arn arn:aws:kms:us-east-1:ACCT:key/12345

# Step 2: When device arrives, unlock it
aws snowball get-job-unlock-code --job-id JID-12345

# Step 3: Get manifest from console, unlock device
snowballEdge unlock-device --manifest-file manifest.bin --unlock-code XXXXX --endpoint https://192.168.1.100

# Step 4: Copy data using snowball cp or S3 adapter
# Option A: S3 Adapter
aws s3 cp /data/archive/ s3://dc-migration-archive/ \
    --recursive \
    --endpoint http://192.168.1.100:8080 \
    --profile snowball

# Option B: NFS mount
mount -t nfs 192.168.1.100:/buckets/dc-migration-archive /mnt/snowball
cp -r /data/archive/* /mnt/snowball/

# Step 5: Ship back → data appears in S3
# Step 6: Apply lifecycle policy to move to Glacier
aws s3api put-bucket-lifecycle-configuration \
    --bucket dc-migration-archive \
    --lifecycle-configuration '{
      "Rules": [{
        "ID": "MoveToGlacier",
        "Status": "Enabled",
        "Transitions": [{"Days": 0, "StorageClass": "GLACIER"}]
      }]
    }'
```

---

## Real-Time Example 2: Edge Computing at Remote Site

**Scenario:** Oil rig with no internet. Need to collect IoT sensor data, process locally, and periodically ship to AWS.

```bash
# Order Snowball Edge Compute Optimized
# On device: run EC2 AMI for data collection

# List available EC2 AMIs on the device
snowballEdge describe-device --endpoint https://10.0.0.1

# Launch local EC2 instance
aws ec2 run-instances \
    --image-id s.ami-12345 \
    --instance-type sbe-c.xlarge \
    --endpoint http://10.0.0.1:8008

# IoT sensors write to local S3 bucket on device
# Data processed locally by Lambda@Edge functions
# When device is full → ship to AWS → order new device

# This creates a "store and forward" pattern:
# Remote site → local processing → ship data → S3 → analytics
```

---

## Real-Time Example 3: Large-Scale Media Transfer

**Scenario:** Film production company needs to transfer 50 TB of raw 8K footage to S3 for cloud-based editing.

```bash
# Internet transfer time (1 Gbps): ~5 days non-stop
# Snowball transfer time: 2-3 days total (1 day load + shipping)

# Use OpsHub GUI for drag-and-drop transfer
# or CLI with parallel transfers:

# Transfer with multiple parallel streams
aws s3 cp /footage/project-x/ s3://media-ingest/project-x/ \
    --recursive \
    --endpoint http://192.168.1.100:8080 \
    --profile snowball \
    --only-show-errors

# Monitor transfer progress
snowballEdge status --endpoint https://192.168.1.100

# After import: set up MediaConvert for transcoding
# Raw 8K → delivery formats (4K, 1080p, HLS streams)
```

---

## Internet vs Snowball Decision Guide

| Data Size | Network Speed | Transfer Time (Internet) | Recommended |
|-----------|--------------|-------------------------|-------------|
| 10 TB | 1 Gbps | ~1 day | Internet |
| 10 TB | 100 Mbps | ~12 days | Snowball Edge |
| 50 TB | 1 Gbps | ~5 days | Snowball Edge |
| 100 TB | 1 Gbps | ~12 days | Snowball Edge |
| 100 TB | 100 Mbps | ~120 days | Snowball Edge |
| 1 PB | Any | Weeks-months | Multiple Snowballs |
| 10+ PB | Any | Impractical | Snowmobile |

**Rule of thumb:** If internet transfer takes > 1 week, use Snowball.

---

## Labs

### Lab 1: Create a Snowball Import Job (Console Walkthrough)
```bash
# In AWS Console:
# 1. Navigate to Snow Family → Create Job
# 2. Select Import into S3
# 3. Choose Snowball Edge Storage Optimized
# 4. Select target S3 bucket
# 5. Create/select IAM role for Snowball
# 6. Set encryption key (KMS)
# 7. Set shipping address and speed
# 8. Review and create job

# Monitor job status
aws snowball describe-job --job-id JID-12345
aws snowball list-jobs
```

### Lab 2: Simulate Data Transfer with S3 CLI
```bash
# Since physical device is not available in lab,
# simulate the workflow with S3 CLI:

# Create source data (simulating on-prem data)
mkdir -p /tmp/onprem-data
for i in $(seq 1 100); do
    dd if=/dev/urandom of=/tmp/onprem-data/file-$i.dat bs=1M count=10 2>/dev/null
done

# Upload to S3 (simulating Snowball import)
aws s3 sync /tmp/onprem-data/ s3://migration-target/ \
    --storage-class GLACIER \
    --only-show-errors

# Verify upload
aws s3 ls s3://migration-target/ --summarize --human-readable
```

---

## Interview Questions

1. **When would you use Snowball instead of direct internet transfer?**
   → When data > 10 TB and network speed makes internet transfer impractical (>1 week). Also for edge computing scenarios with limited connectivity.

2. **What security measures does Snowball use?**
   → 256-bit encryption (KMS managed), tamper-resistant enclosure, TPM chip, E-Ink label (no external ports during transit), NIST 800-88 erasure after import.

3. **Snowball Edge vs Snowcone — when to use each?**
   → Snowcone: <14 TB, lightweight, drone-deliverable, basic edge compute. Snowball Edge: 42-80 TB, full EC2/Lambda compute, clustering support.

4. **What is Snowmobile?**
   → A 45-foot shipping container on a semi-truck. Holds 100 PB. For exabyte-scale migrations. AWS drives it to your data center, connects via fiber, loads data.

5. **Can you run compute on Snowball Edge?**
   → Yes. EC2 instances (from pre-loaded AMIs) and Lambda functions. Supports IoT Greengrass. Useful for edge processing at remote locations.

6. **How does Snowball data get into S3?**
   → After device is shipped back, AWS imports data into specified S3 bucket. Status tracked via console/CLI. Original data on device is then securely erased.

7. **What is AWS OpsHub?**
   → A free GUI application for managing Snow devices. Provides drag-and-drop file transfer, device monitoring, and local EC2/Lambda management without CLI.

8. **Can Snowball export data FROM S3?**
   → Yes. Create an export job specifying S3 bucket/prefix. AWS loads data onto device and ships to you. Used for large downloads or DC provisioning.
