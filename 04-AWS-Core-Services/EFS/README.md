# EFS — Elastic File System

> Managed NFS file system shared across multiple EC2 instances simultaneously. The "shared Google Drive" of AWS.

---

## Real-World Analogy

- **EBS** = USB flash drive — plugs into one computer at a time
- **EFS** = Network shared folder (like Google Drive/OneDrive) — everyone in the office can access the same files simultaneously
- **Instance Store** = RAM disk — super fast but everything is lost when you restart

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **NFS v4.1** | POSIX-compliant file system | Mount on Linux like any folder: `mount /mnt/efs` |
| **Multi-AZ** | Automatically replicated across AZs | Survives entire data center failure |
| **Elastic** | Grows/shrinks automatically | Start with 1 GB, grow to 1 PB — no provisioning needed |
| **Mount Targets** | ENI in each AZ subnet | Each AZ has its own access point for low latency |
| **Access Points** | Application-specific entry points | App A sees `/app-a/data`, App B sees `/app-b/data` |
| **Lifecycle** | Auto-move infrequently accessed files | Files untouched for 30 days → move to IA (90% cheaper) |

---

## Performance & Storage Modes

| Mode | Description | When to Use |
|------|-------------|-------------|
| **General Purpose** | Low latency, IOPS-limited | Web serving, CMS, home directories |
| **Max I/O** | Higher latency, higher aggregate throughput | Big data, media processing |
| **Bursting** | Bursts based on file system size | Most workloads (<1 TB) |
| **Elastic** | Automatic throughput scaling | Unpredictable workloads (recommended) |
| **Provisioned** | Fixed throughput regardless of size | Small file system needing high throughput |

## Storage Classes

| Class | Cost | Use Case |
|-------|------|----------|
| **Standard** | $0.30/GB | Frequently accessed files |
| **Infrequent Access (IA)** | $0.025/GB | Files accessed < once per month |
| **Archive** | $0.008/GB | Files accessed < once per year |
| **One Zone** | 47% cheaper than Standard | Dev/test, single-AZ workloads |
| **One Zone IA** | Cheapest | Dev/test infrequent access |

---

## Real-Time Example 1: WordPress/CMS Shared Storage

**Scenario:** You run WordPress behind an ALB with 5 EC2 instances (via ASG). Users upload images and plugins. ALL instances need to see the same files.

```
Without EFS:
User uploads photo → saved on EC2-1 local disk
Next request goes to EC2-2 → "File not found!" ❌

With EFS:
User uploads photo → saved on EFS (shared)
Any EC2 instance → sees the same photo ✅
```

```
ALB
 │
 ├── EC2-1  ──┐
 ├── EC2-2  ──┼──► EFS (shared /var/www/html)
 ├── EC2-3  ──┤    ├── wp-content/uploads/photo.jpg
 ├── EC2-4  ──┤    ├── wp-content/plugins/
 └── EC2-5  ──┘    └── wp-content/themes/
```

```bash
# User data script for EC2 instances in ASG
#!/bin/bash
yum install -y amazon-efs-utils httpd php
mount -t efs -o tls fs-xxxxxxxx:/ /var/www/html
echo "fs-xxxxxxxx:/ /var/www/html efs _netdev,tls 0 0" >> /etc/fstab
systemctl start httpd
```

---

## Real-Time Example 2: Machine Learning Training Data

**Scenario:** Your data science team has 500GB of training data. Multiple GPU instances need to read the same data simultaneously for parallel training.

```
Training Data on EFS:
/ml-data/
├── training/     (400 GB — images, CSV)
├── validation/   (50 GB)
└── models/       (50 GB — saved model checkpoints)

4 GPU instances (p3.2xlarge) all mount /ml-data
Each reads different portions of training data simultaneously
When training completes, model saved to /ml-data/models/ — visible to all
```

```bash
# Create EFS optimized for ML (Max I/O for parallel reads)
EFS_ID=$(aws efs create-file-system \
    --performance-mode maxIO \
    --throughput-mode elastic \
    --encrypted \
    --tags Key=Name,Value=ml-training-data \
    --query 'FileSystemId' --output text)

# Create mount target in the subnet where GPU instances run
aws efs create-mount-target --file-system-id $EFS_ID \
    --subnet-id subnet-gpu --security-groups sg-efs
```

---

## Real-Time Example 3: Container Shared Storage (ECS/EKS)

**Scenario:** Your microservices on ECS need shared configuration files and logs.

```
ECS Tasks on Fargate
├── Service A (3 tasks) ──┐
├── Service B (5 tasks) ──┼──► EFS Access Point: /config
└── Service C (2 tasks) ──┘    ├── app-config.yml
                                ├── feature-flags.json
                                └── shared-templates/
```

```bash
# Create access point for each application
aws efs create-access-point --file-system-id $EFS_ID \
    --posix-user Uid=1000,Gid=1000 \
    --root-directory "Path=/config,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755}"
```

---

## EBS vs EFS vs Instance Store — Complete Comparison

| Feature | EBS | EFS | Instance Store |
|---------|-----|-----|----------------|
| **Type** | Block storage | File storage (NFS) | Block storage |
| **Multi-attach** | io2 only (same AZ) | Yes — hundreds of instances | No |
| **Persistence** | Yes (survives stop) | Yes | No (ephemeral) |
| **Cross-AZ** | No (AZ-locked) | Yes (multi-AZ default) | No |
| **Max Size** | 64 TiB per volume | Petabytes | Depends on instance |
| **Performance** | Up to 256K IOPS | Up to 500K+ IOPS (aggregate) | Millions of IOPS |
| **Cost** | $0.08/GB (gp3) | $0.30/GB (std), $0.025/GB (IA) | Free (included) |
| **Scaling** | Manual resize | Automatic | Fixed |
| **Backup** | Snapshots | AWS Backup | Must replicate yourself |
| **Use Case** | Databases, boot volumes | Shared files, CMS, ML data | Cache, temp, swap |

---

## Labs

### Lab 1: Create and Mount EFS
```bash
# Create EFS with encryption and lifecycle policy
EFS_ID=$(aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode elastic \
    --encrypted \
    --tags Key=Name,Value=shared-app-data \
    --query 'FileSystemId' --output text)

# Set lifecycle policy (move to IA after 30 days)
aws efs put-lifecycle-configuration --file-system-id $EFS_ID \
    --lifecycle-policies '[
        {"TransitionToIA": "AFTER_30_DAYS"},
        {"TransitionToArchive": "AFTER_90_DAYS"},
        {"TransitionToPrimaryStorageClass": "AFTER_1_ACCESS"}
    ]'

# Create mount targets in each AZ
for subnet in subnet-1a subnet-1b subnet-1c; do
    aws efs create-mount-target --file-system-id $EFS_ID \
        --subnet-id $subnet --security-groups sg-efs
done
```

### Lab 2: Mount on EC2 Instance
```bash
# Install EFS utils and mount
sudo yum install -y amazon-efs-utils
sudo mkdir /mnt/efs
sudo mount -t efs -o tls $EFS_ID:/ /mnt/efs

# Make persistent across reboots
echo "$EFS_ID:/ /mnt/efs efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
```

### Lab 3: EFS with Access Points
```bash
# Create access point for web application
aws efs create-access-point --file-system-id $EFS_ID \
    --posix-user Uid=1000,Gid=1000 \
    --root-directory "Path=/webapp,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755}"

# Create access point for data pipeline
aws efs create-access-point --file-system-id $EFS_ID \
    --posix-user Uid=2000,Gid=2000 \
    --root-directory "Path=/pipeline,CreationInfo={OwnerUid=2000,OwnerGid=2000,Permissions=750}"
```

---

## Interview Questions

1. **When would you use EFS over EBS?**
   > When multiple instances need to read/write the same files simultaneously. Example: WordPress behind a load balancer, shared ML training data, or container shared storage. EBS is single-instance (except io2 Multi-Attach).

2. **What is the difference between EFS performance modes?**
   > General Purpose: low latency, good for web/CMS. Max I/O: higher latency but massive aggregate throughput — for big data and ML with many clients. Most new workloads should use Elastic throughput mode.

3. **How does EFS pricing work and how do you optimize costs?**
   > Standard: $0.30/GB, IA: $0.025/GB (92% cheaper). Enable lifecycle policies to auto-move files to IA after 30 days. For dev/test, use One Zone (47% cheaper). A 1TB EFS with 80% IA can cost $55/month vs $300/month all-Standard.

4. **Can you use EFS with containers (ECS/Fargate)?**
   > Yes, EFS integrates natively with ECS and EKS. Define EFS volume in task definition, and all containers in the task/pod mount the shared filesystem. Use Access Points for per-application isolation.

5. **How does EFS handle availability and durability?**
   > Standard EFS replicates data across 3+ AZs. Survives AZ failure. 99.999999999% (11 nines) durability. One Zone EFS stores in a single AZ — cheaper but no AZ redundancy.

6. **What are EFS Access Points and when to use them?**
   > Application-specific entry points with their own POSIX user/group and root directory. Example: App A sees `/app-a/` as root, App B sees `/app-b/`. Provides isolation without multiple EFS file systems.

7. **How does EFS encryption work?**
   > Encryption at rest: enabled at creation, uses KMS (cannot add later). Encryption in transit: use the TLS mount option (`mount -t efs -o tls`). Both should be enabled for production.

8. **EFS vs FSx — when to choose each?**
   > EFS: Linux NFS workloads. FSx for Windows: Windows SMB file shares, Active Directory integration. FSx for Lustre: HPC and ML (extreme performance). FSx for NetApp ONTAP: multi-protocol enterprise storage.
