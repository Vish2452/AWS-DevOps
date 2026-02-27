# EC2 — Elastic Compute Cloud

> **EC2 is the workhorse of AWS. Understanding compute is fundamental to every AWS architecture.**

## Topics

### Instance Fundamentals
- **Instance families:** General (t3, m6i), Compute (c6i), Memory (r6i), Storage (i3), GPU (p4d)
- **AMI (Amazon Machine Image)** — pre-configured OS images
- **Key pairs** — SSH authentication
- **User data** — bootstrap scripts at launch
- **Instance metadata** — `http://169.254.169.254/latest/meta-data/`
- **IMDSv2** — secure metadata access (required in production)

### Purchasing Options
| Option | Savings | Commitment | Best For |
|--------|---------|------------|----------|
| On-Demand | None | None | Dev/test, unpredictable |
| Reserved | Up to 72% | 1 or 3 years | Steady-state workloads |
| Savings Plans | Up to 72% | 1 or 3 years | Flexible commitment |
| Spot | Up to 90% | None | Fault-tolerant, batch |
| Dedicated Hosts | N/A | N/A | Compliance, licensing |

### Placement Groups
- **Cluster** — low latency within single AZ (HPC)
- **Spread** — across distinct hardware (HA)
- **Partition** — large distributed workloads (Kafka, Cassandra)

### AMI Creation — Golden Image Pipeline
```bash
# 1. Launch base instance
# 2. Install and configure software
# 3. Create AMI
aws ec2 create-image --instance-id i-1234567890abcdef0 \
    --name "golden-ami-$(date +%Y%m%d)" \
    --description "Production-ready AMI with Nginx, monitoring agents" \
    --no-reboot

# 4. Use AMI in launch templates for ASG
```

---

## Hands-On Labs

### Lab 1: Launch EC2 with User Data
```bash
cat > userdata.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y nginx
systemctl enable --now nginx
echo "<h1>Server: $(hostname)</h1>" > /usr/share/nginx/html/index.html
EOF

aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t3.micro \
    --key-name my-key \
    --security-group-ids sg-xxxx \
    --subnet-id subnet-xxxx \
    --user-data file://userdata.sh \
    --iam-instance-profile Name=EC2-SSM-Role \
    --metadata-options HttpTokens=required \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]'
```

### Lab 2: Spot Instance Request
```bash
aws ec2 request-spot-instances \
    --spot-price "0.05" \
    --instance-count 2 \
    --type "one-time" \
    --launch-specification '{
        "ImageId": "ami-0c02fb55956c7d316",
        "InstanceType": "t3.large",
        "KeyName": "my-key"
    }'
```

### Lab 3: Create Launch Template
```bash
aws ec2 create-launch-template \
    --launch-template-name prod-web-server \
    --version-description "v1" \
    --launch-template-data '{
        "ImageId": "ami-xxxx",
        "InstanceType": "t3.medium",
        "KeyName": "my-key",
        "SecurityGroupIds": ["sg-xxxx"],
        "UserData": "BASE64_ENCODED_USERDATA",
        "IamInstanceProfile": {"Name": "EC2-SSM-Role"},
        "MetadataOptions": {"HttpTokens": "required"},
        "BlockDeviceMappings": [{
            "DeviceName": "/dev/xvda",
            "Ebs": {"VolumeSize": 20, "VolumeType": "gp3", "Encrypted": true}
        }]
    }'
```

---

## Interview Questions
1. What are EC2 instance types and how to choose?
2. Explain On-Demand vs Reserved vs Spot instances
3. What is a launch template and how does it differ from launch configuration?
4. How does user data work and when does it run?
5. What is IMDSv2 and why is it important?
6. How to create a golden AMI pipeline?
7. Explain placement groups — cluster vs spread vs partition
