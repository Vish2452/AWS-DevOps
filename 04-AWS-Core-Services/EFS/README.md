# EFS — Elastic File System

> Managed NFS file system shared across multiple EC2 instances. Perfect for shared application data.

## Key Concepts
- **NFS v4.1** protocol — POSIX-compliant
- **Multi-AZ** — automatically replicated for high availability
- **Elastic** — grows/shrinks automatically (no provisioning)
- **Performance modes:** General Purpose, Max I/O
- **Throughput modes:** Bursting, Provisioned, Elastic
- **Storage classes:** Standard, Infrequent Access (IA), Archive

## EBS vs EFS vs Instance Store

| Feature | EBS | EFS | Instance Store |
|---------|-----|-----|----------------|
| Type | Block | File (NFS) | Block |
| Multi-attach | io2 only | Yes (multiple EC2) | No |
| Persistence | Yes | Yes | No (ephemeral) |
| Cross-AZ | No (AZ locked) | Yes | No |
| Use Case | Databases, boot | Shared files, CMS | Cache, temp data |

## Labs
```bash
# Create EFS
EFS_ID=$(aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode elastic \
    --encrypted \
    --tags Key=Name,Value=shared-app-data \
    --query 'FileSystemId' --output text)

# Create mount targets in each AZ
aws efs create-mount-target --file-system-id $EFS_ID \
    --subnet-id subnet-xxxx --security-groups sg-xxxx

# Mount on EC2
sudo yum install -y amazon-efs-utils
sudo mount -t efs -o tls $EFS_ID:/ /mnt/efs
echo "$EFS_ID:/ /mnt/efs efs _netdev,tls 0 0" | sudo tee -a /etc/fstab
```
