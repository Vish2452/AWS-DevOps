# Task 1 — Provision EC2 Instance & Explore File System

## Objective
Launch an Amazon Linux 2023 EC2 instance, connect via SSH, and explore the Linux file system hierarchy.

## Steps

### 1. Launch EC2 Instance
```bash
# Using AWS CLI
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t2.micro \
  --key-name my-key-pair \
  --security-group-ids sg-xxxxxxxx \
  --subnet-id subnet-xxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Linux-Lab}]'
```

### 2. Connect via SSH
```bash
chmod 400 my-key-pair.pem
ssh -i my-key-pair.pem ec2-user@<public-ip>
```

### 3. Explore File System Hierarchy
```bash
# View root directory structure
ls -la /

# Key directories to explore
ls -la /etc          # Configuration files
ls -la /var/log      # Log files
ls -la /home         # User home directories
ls -la /tmp          # Temporary files
ls -la /opt          # Optional software
ls -la /usr/bin      # User binaries
ls -la /sbin         # System binaries
ls -la /proc         # Process information (virtual)
ls -la /sys          # System information (virtual)
ls -la /dev          # Device files

# System information
uname -a
cat /etc/os-release
hostname
uptime
free -h
df -h
lscpu
```

### 4. Practice Basic Commands
```bash
# Navigate and create directory structure
mkdir -p /home/ec2-user/projects/{web,api,scripts}
cd /home/ec2-user/projects
tree .

# File operations
touch web/index.html api/app.py scripts/deploy.sh
cp web/index.html web/index.backup.html
mv api/app.py api/main.py
ln -s /home/ec2-user/projects /home/ec2-user/work  # symbolic link

# Find and locate
find / -name "*.conf" -type f 2>/dev/null | head -20
find /var/log -mtime -1 -type f   # modified in last 24h
which python3
whereis nginx

# Disk and memory
df -hT
du -sh /var/log/*
free -m
vmstat 1 5
```

## Validation Checklist
- [ ] EC2 instance is running and accessible via SSH
- [ ] Can navigate the full file system hierarchy
- [ ] Understand the purpose of each top-level directory
- [ ] Practiced 20+ basic Linux commands
