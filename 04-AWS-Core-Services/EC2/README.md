# EC2 — Elastic Compute Cloud

> **EC2 is the workhorse of AWS. Understanding compute is fundamental to every AWS architecture.** It's like renting a computer in Amazon's data centers that you can configure exactly how you need.

---

## Real-World Analogy

EC2 is like **renting an apartment**:
- You choose the size (instance type) — studio, 1-bedroom, penthouse
- You pick the neighborhood (region/AZ)
- You furnish it (AMI + user data)
- You install locks (security groups + key pairs)
- You can rent month-to-month (On-Demand), sign a lease (Reserved), or bid on distressed properties (Spot)
- You can move to a bigger apartment later (instance type change)

---

## Topics

### Instance Families Deep Dive

| Family | Type | vCPU:Memory | Use Case | Example |
|--------|------|-------------|----------|---------|
| **T3/T3a** | General (burstable) | 1:2 GB | Dev, small web apps | t3.micro — $7.59/month |
| **M6i/M7i** | General (fixed) | 1:4 GB | App servers, mid-size DB | m6i.xlarge for Java apps |
| **C6i/C7i** | Compute optimized | 1:2 GB | Batch, ML inference, gaming | c6i.2xlarge for video encoding |
| **R6i/R7i** | Memory optimized | 1:8 GB | In-memory cache, big DB | r6i.4xlarge for Redis/SAP |
| **I3/I4i** | Storage optimized | High IOPS | NoSQL, data warehousing | i3.xlarge for Cassandra |
| **P4d/P5** | GPU | 8 GPU | ML training, HPC | p4d.24xlarge — 8x A100 GPUs |
| **G5** | GPU (graphics) | 1-8 GPU | Video rendering, gaming | g5.xlarge for game streaming |
| **Inf2** | ML inference | Inferentia chips | Cost-effective inference | inf2.xlarge — 70% cheaper than GPU |

**How to choose:** Think "TCMR" — **T**iny apps (T3), **C**ompute heavy (C6i), **M**emory heavy (R6i), **M**iddle ground (M6i)

### Core Concepts
- **AMI (Amazon Machine Image)** — pre-configured OS images (your apartment's blueprint)
- **Key pairs** — SSH authentication (your apartment keys)
- **User data** — bootstrap scripts at launch (moving-in checklist)
- **Instance metadata** — `http://169.254.169.254/latest/meta-data/`
- **IMDSv2** — secure metadata access (required in production — prevents SSRF attacks)

### Purchasing Options
| Option | Savings | Commitment | Best For | Monthly Cost (m5.xlarge) |
|--------|---------|------------|----------|-------------------------|
| On-Demand | None | None | Dev/test, unpredictable | ~$140 |
| Reserved (1yr) | Up to 40% | 1 year | Steady-state workloads | ~$84 |
| Reserved (3yr) | Up to 72% | 3 years | Long-running production | ~$56 |
| Savings Plans | Up to 72% | 1 or 3 years | Flexible commitment | ~$56-84 |
| Spot | Up to 90% | None | Fault-tolerant, batch | ~$14-42 |
| Dedicated Hosts | N/A | N/A | Compliance, licensing | Premium |

### Placement Groups
- **Cluster** — low latency within single AZ (HPC, tightly coupled)
- **Spread** — across distinct hardware, max 7 per AZ (HA for critical instances)
- **Partition** — large distributed workloads across fault-isolated partitions (Kafka, Cassandra, HDFS)

---

## Real-Time Example 1: E-Commerce Platform Architecture

**Scenario:** You're building an e-commerce platform that needs to handle Black Friday traffic (10x normal). You need cost-effective compute with high availability.

```
                         ┌─────────────────────────────────────────┐
                         │          Production Architecture         │
                         └────────────────┬────────────────────────┘
                                          │
               ┌──────────────────────────┼──────────────────────────┐
               │                          │                          │
     ┌─────────▼─────────┐    ┌──────────▼──────────┐    ┌─────────▼─────────┐
     │   Web Tier (ASG)   │    │   App Tier (ASG)    │    │   Worker Tier     │
     │                     │    │                     │    │                   │
     │  t3.medium × 4     │    │  m6i.xlarge × 6     │    │  c6i.xlarge × 10  │
     │  (On-Demand)        │    │  (Reserved 1yr)     │    │  (Spot 80% +      │
     │                     │    │  Steady baseline     │    │   On-Demand 20%)  │
     │  Cost: $120/mo      │    │  Cost: $300/mo       │    │  Cost: $150/mo    │
     └─────────────────────┘    └──────────────────────┘    └───────────────────┘

     Monthly compute cost: ~$570 (vs $1,400 all On-Demand = 59% savings!)
```

**Instance Selection Rationale:**
- **Web servers (t3.medium):** Low CPU, burstable — handles HTTP requests, serves cached content
- **App servers (m6i.xlarge):** Balanced CPU + memory — runs Java/Node.js business logic
- **Workers (c6i.xlarge on Spot):** CPU-intensive — order processing, image resizing, email sending. Spot is safe because workers are fault-tolerant (SQS re-delivers failed messages)

```bash
# Launch template for web tier with IMDSv2
aws ec2 create-launch-template \
    --launch-template-name web-server-lt \
    --launch-template-data '{
        "ImageId": "ami-xxxx",
        "InstanceType": "t3.medium",
        "SecurityGroupIds": ["sg-web"],
        "IamInstanceProfile": {"Name": "WebServerRole"},
        "MetadataOptions": {"HttpTokens": "required", "HttpEndpoint": "enabled"},
        "UserData": "'$(base64 -w 0 userdata.sh)'",
        "TagSpecifications": [{
            "ResourceType": "instance",
            "Tags": [
                {"Key": "Name", "Value": "web-server"},
                {"Key": "Environment", "Value": "production"},
                {"Key": "CostCenter", "Value": "ecommerce"}
            ]
        }]
    }'
```

---

## Real-Time Example 2: Golden AMI Pipeline

**Scenario:** Your company has 50+ EC2 instances. Every time you launch a new one, developers manually install packages (takes 20 minutes). You need a standardized, automated AMI pipeline.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Base AMI    │────▶│  Launch +    │────▶│  Create AMI  │────▶│  Test AMI    │
│  (Amazon     │     │  Install     │     │  "golden-ami │     │  (Launch +   │
│   Linux 2023)│     │  packages    │     │   -20260115" │     │   validate)  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                       │
                     ┌──────────────┐     ┌──────────────┐            │
                     │ Share to all │◀────│ Approve &    │◀───────────┘
                     │ accounts     │     │ Tag "latest" │   PASS: share
                     └──────────────┘     └──────────────┘   FAIL: alert & stop
```

```bash
# Step 1: Launch base instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t3.medium \
    --key-name build-key \
    --security-group-ids sg-build \
    --subnet-id subnet-private \
    --iam-instance-profile Name=AMIBuilderRole \
    --query 'Instances[0].InstanceId' --output text)

# Step 2: Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Step 3: Install software (via SSM Run Command — no SSH needed!)
aws ssm send-command --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters commands='[
        "yum update -y",
        "yum install -y nginx amazon-cloudwatch-agent aws-cli",
        "systemctl enable nginx",
        "systemctl enable amazon-cloudwatch-agent",
        "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start",
        "yum clean all",
        "rm -rf /tmp/* /var/tmp/*"
    ]'

# Step 4: Create AMI
AMI_ID=$(aws ec2 create-image --instance-id $INSTANCE_ID \
    --name "golden-ami-$(date +%Y%m%d-%H%M)" \
    --description "Production AMI: Nginx + CW Agent + SSM" \
    --no-reboot \
    --query 'ImageId' --output text)

# Step 5: Wait for AMI and tag it
aws ec2 wait image-available --image-ids $AMI_ID
aws ec2 create-tags --resources $AMI_ID \
    --tags Key=Status,Value=tested Key=Version,Value=latest

# Step 6: Terminate build instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

echo "Golden AMI created: $AMI_ID"
```

---

## Real-Time Example 3: Spot Instance Fleet for Batch Processing

**Scenario:** Your data team needs to process 10TB of log files daily. Using On-Demand would cost $1,200/day. Spot instances can do it for $180/day.

```bash
# Create Spot Fleet with multiple instance types (diversification = fewer interruptions)
aws ec2 request-spot-fleet --spot-fleet-request-config '{
    "IamFleetRole": "arn:aws:iam::ACCT:role/SpotFleetRole",
    "TargetCapacity": 20,
    "SpotPrice": "0.10",
    "AllocationStrategy": "capacityOptimized",
    "TerminateInstancesWithExpiration": true,
    "Type": "maintain",
    "LaunchSpecifications": [
        {
            "ImageId": "ami-xxxx",
            "InstanceType": "c6i.xlarge",
            "SubnetId": "subnet-1a",
            "WeightedCapacity": 4
        },
        {
            "ImageId": "ami-xxxx",
            "InstanceType": "c5.xlarge",
            "SubnetId": "subnet-1b",
            "WeightedCapacity": 4
        },
        {
            "ImageId": "ami-xxxx",
            "InstanceType": "c5a.xlarge",
            "SubnetId": "subnet-1c",
            "WeightedCapacity": 4
        },
        {
            "ImageId": "ami-xxxx",
            "InstanceType": "m6i.xlarge",
            "SubnetId": "subnet-1a",
            "WeightedCapacity": 4
        }
    ]
}'
```

**Handling Spot Interruptions:**
```bash
# In user data — monitor for spot termination notice
cat > /usr/local/bin/spot-monitor.sh << 'SCRIPT'
#!/bin/bash
while true; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        http://169.254.169.254/latest/meta-data/spot/instance-action)
    if [ "$STATUS" == "200" ]; then
        echo "$(date): Spot interruption notice received! Saving state..."
        # Save current processing state to S3
        aws s3 cp /tmp/processing-state.json s3://batch-state/$(hostname).json
        # Drain and signal ASG/queue
        echo "State saved. Graceful shutdown..."
    fi
    sleep 5
done
SCRIPT
```

**Cost Comparison:**
| Approach | Instance Type | Count | Monthly Cost |
|----------|--------------|-------|-------------|
| All On-Demand | c6i.xlarge | 20 | ~$36,000 |
| All Spot | Mixed c5/c6i/m6i | 20 | ~$5,400 |
| Mixed (70/30) | On-Demand + Spot | 20 | ~$14,580 |

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

### Lab 4: Monitor Instance with CloudWatch
```bash
# Enable detailed monitoring (1-minute intervals instead of 5)
aws ec2 monitor-instances --instance-ids i-xxxx

# Get CPU utilization for the last hour
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-xxxx \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average Maximum

# Set up CPU alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "High-CPU-WebServer" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:ops-alerts \
    --dimensions Name=InstanceId,Value=i-xxxx
```

---

## Best Practices

| Practice | Why | How |
|----------|-----|-----|
| **Use IMDSv2** | Prevents SSRF attacks (Capital One breach was via IMDSv1) | `--metadata-options HttpTokens=required` |
| **Use Launch Templates** | Version-controlled, supports mixed instances | Never use Launch Configurations (legacy) |
| **Right-size regularly** | Avoid paying for unused capacity | Use AWS Compute Optimizer recommendations |
| **Tag everything** | Cost allocation, automation, compliance | Enforce via SCP or Config Rules |
| **Use SSM Session Manager** | No SSH keys to manage, no port 22 needed | Attach `AmazonSSMManagedInstanceCore` role |
| **Encrypt EBS volumes** | Data at rest protection | Default encryption in account settings |

---

## Interview Questions

1. **What are EC2 instance types and how to choose the right one?**
   > Instance families are optimized for different workloads: T3 (burstable, dev/test), M6i (general purpose, app servers), C6i (compute — batch, encoding), R6i (memory — Redis, SAP), I3 (storage — Cassandra). Choose based on your bottleneck: CPU → C-family, Memory → R-family, Balanced → M-family, Cost-sensitive → T-family.

2. **Explain On-Demand vs Reserved vs Spot instances. When would you use each?**
   > On-Demand: pay per second, no commitment — for unpredictable/short-lived workloads. Reserved: up to 72% discount with 1-3 year commitment — for steady-state production. Spot: up to 90% off but can be interrupted with 2-min notice — for fault-tolerant batch processing. Best practice: Reserved for baseline + Spot for variable load.

3. **What is a launch template and how does it differ from launch configuration?**
   > Launch Template is the modern replacement. Supports versioning, multiple instance types, Spot+On-Demand mix, T2/T3 unlimited, and can be updated (LC is immutable). Always use Launch Templates — LC is legacy and doesn't support new features.

4. **How does user data work and when does it run?**
   > User data is a shell script (Linux) or PowerShell script (Windows) that runs ONCE at first boot as root/admin. It's base64-encoded and limited to 16KB. Use it for bootstrapping: install packages, pull configs from S3, register with config management. For subsequent boots, use cloud-init per-boot scripts.

5. **What is IMDSv2 and why is it important?**
   > Instance Metadata Service v2 requires a session token (PUT request first, then GET with token header). IMDSv1 allowed simple GET requests, which SSRF vulnerabilities could exploit (attacker tricks app into requesting metadata URL → steals IAM role credentials). The 2019 Capital One breach exploited IMDSv1. Always enforce v2.

6. **How to create a golden AMI pipeline?**
   > Launch base instance → Install/configure software → Create AMI → Test (launch from AMI, run validation) → Tag as "approved" → Share to other accounts. Automate with EC2 Image Builder or Jenkins pipeline. Update launch templates to use new AMI. Old instances get replaced via ASG instance refresh.

7. **Explain placement groups — cluster vs spread vs partition.**
   > **Cluster:** All instances on same rack — lowest latency (10 Gbps between instances), used for HPC. Risk: rack failure kills all. **Spread:** Each instance on different hardware, max 7 per AZ — for critical instances that must survive failures. **Partition:** Instances grouped into partitions on separate racks — for Hadoop/Kafka/Cassandra where you need fault isolation between groups.

8. **How do you handle Spot instance interruptions?**
   > AWS gives 2-minute warning via instance metadata (`/spot/instance-action`). Best practices: (1) Use diverse instance types/AZs to reduce interruption chance, (2) Use `capacityOptimized` allocation strategy, (3) Save processing state to S3/SQS on interruption notice, (4) Use Spot Fleet or ASG to automatically replace terminated instances, (5) Design workloads to be stateless and resumable.
