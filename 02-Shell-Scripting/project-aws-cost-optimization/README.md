# Real-Time Project: Automated AWS Cost Optimization Script

> **Industry Context:** Cloud cost optimization (FinOps) is a top priority in every organization. This project builds an automated tool to identify and report wasteful AWS resources.

## Architecture

```
┌────────────────────────────────────────────────────────┐
│           AWS Cost Optimization Script                  │
│                                                        │
│  Scans:                                                │
│  ├── 💾 Unused EBS Volumes (unattached)                │
│  ├── 🌐 Unassociated Elastic IPs ($3.65/mo each)      │
│  ├── 💤 Idle EC2 Instances (CPU < 5% for 7 days)      │
│  ├── 📸 Old EBS Snapshots (> 90 days)                 │
│  ├── 🔄 Unused NAT Gateways                           │
│  └── 🪣 Empty S3 Buckets                              │
│                                                        │
│  Output:                                               │
│  ├── CSV report per resource type                      │
│  ├── Summary with estimated monthly savings            │
│  └── SNS notification with report link                 │
│                                                        │
│  Scheduling:                                           │
│  └── Daily at 6 AM UTC via cron (or EventBridge)      │
└────────────────────────────────────────────────────────┘
```

## Project Structure

```
project-aws-cost-optimization/
├── README.md
├── cost-optimizer.sh          # Main script
├── lib/
│   ├── check-ebs.sh           # Unused EBS volumes
│   ├── check-eip.sh           # Unassociated Elastic IPs
│   ├── check-ec2.sh           # Idle EC2 instances
│   ├── check-snapshots.sh     # Old EBS snapshots
│   ├── check-nat.sh           # Unused NAT Gateways
│   └── report-generator.sh    # Generate & send report
├── config/
│   └── thresholds.conf        # Configurable thresholds
└── reports/                   # Generated reports (gitignored)
```

## Usage

```bash
# Run full cost analysis
./cost-optimizer.sh

# Run with custom region
AWS_REGION=eu-west-1 ./cost-optimizer.sh

# Run specific check only
./cost-optimizer.sh --check ebs

# Run with SNS notification
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456:cost-alerts ./cost-optimizer.sh

# Dry run (scan only, no delete)
./cost-optimizer.sh --dry-run

# Delete mode (with confirmation)
./cost-optimizer.sh --cleanup
```

## Key Learning Outcomes
- AWS CLI mastery for resource discovery
- JQ for JSON processing
- Cost awareness and FinOps practices
- Automated reporting and alerting
- Production bash scripting patterns
