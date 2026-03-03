# ASG — Auto Scaling Groups

> Automatically adjust compute capacity based on demand. Essential for cost efficiency, high availability, and handling traffic spikes without manual intervention.

---

## Real-World Analogy

ASG is like a **restaurant that hires and fires waiters based on how busy it is**:
- **Lunch rush (12-2 PM):** Automatically hire 5 extra waiters
- **Evening quiet (9 PM):** Send extra waiters home, keep only 2
- **Unexpected celebrity visit:** Detect long customer queue → immediately call in more staff
- **Waiter gets sick:** Automatically replace with a healthy one
- You set rules: "Always have at least 2 waiters, never more than 20"

---

## Scaling Policies

| Type | How It Works | Use Case | Real-World Example |
|------|-------------|----------|-------------------|
| **Target Tracking** | Maintain metric at target value | Most common, easy | "Keep CPU at 50%" — ASG adds/removes instances automatically |
| **Step Scaling** | Scale by different amounts at different thresholds | Complex rules | CPU 60% → add 1, CPU 80% → add 3, CPU 95% → add 5 |
| **Simple Scaling** | Scale by fixed amount, then cooldown | Legacy | Add 1 instance when alarm fires, wait 5 min |
| **Predictive** | ML-based forecast from past data | Recurring patterns | Every Friday at 6 PM traffic spikes → pre-warm instances |
| **Scheduled** | Time-based scaling | Known peak times | Black Friday sale: scale to 50 instances at 12 AM |

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Launch Template** | Instance blueprint (AMI, type, security groups) | "All new servers should be t3.large, Amazon Linux 2, with Nginx" |
| **Desired/Min/Max** | Capacity boundaries | Min=2 (always available), Max=20 (cost control), Desired=5 |
| **Lifecycle Hooks** | Custom actions on launch/terminate | On launch: register with service discovery. On terminate: drain connections |
| **Warm Pools** | Pre-initialized instances ready to go | Instead of 3-min boot time, instances are warm and join in 30 sec |
| **Instance Refresh** | Rolling update of all instances | Deploy new AMI across 50 instances with zero downtime |
| **Health Checks** | EC2 status + ELB health check | If instance fails ALB health check, ASG replaces it automatically |
| **Cooldown Period** | Wait time between scaling actions | Prevents rapid add/remove cycles (thrashing) |
| **Mixed Instances** | Use multiple instance types | 70% on-demand + 30% spot instances for cost savings |

---

## Real-Time Example 1: E-Commerce Flash Sale

**Scenario:** Your e-commerce site normally handles 1,000 users. Black Friday brings 50,000 users. Without ASG, your site crashes.

```
Normal Day (Mon-Thu):
┌────┐ ┌────┐
│EC2 │ │EC2 │     2 instances, CPU at 30%
└────┘ └────┘

Black Friday Sale Starts (12:00 AM):
┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
│EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │ │EC2 │
└────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘
     10 instances, CPU at 50%  ← ASG scaled from 2 → 10

Sale Ends (Sunday):
┌────┐ ┌────┐ ┌────┐
│EC2 │ │EC2 │ │EC2 │     3 instances, gradual scale-in
└────┘ └────┘ └────┘

Cost: You only paid for extra instances during the 3-day sale!
Without ASG: You'd keep 10 instances running 24/7, wasting $$$ on idle servers.
```

```bash
# Scheduled scaling for Black Friday
# Scale up Thursday 11:55 PM
aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name prod-web-asg \
    --scheduled-action-name "black-friday-scale-up" \
    --start-time "2026-11-26T23:55:00Z" \
    --desired-capacity 10 --min-size 5 --max-size 30

# Scale back down Monday
aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name prod-web-asg \
    --scheduled-action-name "black-friday-scale-down" \
    --start-time "2026-11-30T06:00:00Z" \
    --desired-capacity 3 --min-size 2 --max-size 10
```

---

## Real-Time Example 2: Zero-Downtime Deployment with Instance Refresh

**Scenario:** You have 10 instances running v1.0. You built a new AMI with v2.0. You want to deploy without any downtime.

```
Start: All 10 instances running v1.0 AMI
Step 1: Replace 2 instances (20% batch) → 8 x v1.0 + 2 x v2.0
Step 2: Health check passes → replace next batch
Step 3: Replace 2 more → 6 x v1.0 + 4 x v2.0
...
Step 5: All 10 instances now running v2.0 AMI ✅
```

```bash
# Update launch template to new AMI
aws ec2 create-launch-template-version \
    --launch-template-name prod-web-server \
    --source-version 1 \
    --launch-template-data '{"ImageId": "ami-new-v2-0"}'

# Trigger rolling deployment
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name prod-web-asg \
    --preferences '{
        "MinHealthyPercentage": 80,
        "InstanceWarmup": 120,
        "MaxHealthyPercentage": 110
    }'

# Monitor progress
aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name prod-web-asg
```

**Explanation:** Instance Refresh replaces instances in batches. `MinHealthyPercentage: 80` means at least 80% of instances are always serving traffic. Each new instance gets 120 seconds to warm up before receiving full traffic. This is how companies like Uber deploy across thousands of servers.

---

## Real-Time Example 3: Cost Optimization with Mixed Instances

**Scenario:** You want to reduce EC2 costs by 60% using Spot instances, but need reliability.

```bash
# Mixed instances: On-Demand base + Spot for scaling
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name prod-web-asg \
    --mixed-instances-policy '{
        "LaunchTemplate": {
            "LaunchTemplateSpecification": {
                "LaunchTemplateName": "prod-web-server",
                "Version": "$Latest"
            },
            "Overrides": [
                {"InstanceType": "t3.large"},
                {"InstanceType": "t3a.large"},
                {"InstanceType": "m5.large"},
                {"InstanceType": "m5a.large"}
            ]
        },
        "InstancesDistribution": {
            "OnDemandBaseCapacity": 2,
            "OnDemandPercentageAboveBaseCapacity": 30,
            "SpotAllocationStrategy": "capacity-optimized"
        }
    }' \
    --min-size 2 --max-size 20 --desired-capacity 6 \
    --vpc-zone-identifier "subnet-priv-1,subnet-priv-2"
```

**Explanation:** 
- First 2 instances are always On-Demand (guaranteed availability)
- Above that, 30% On-Demand + 70% Spot instances
- Multiple instance types listed — if one type is unavailable, ASG uses another
- Result: ~60% cost reduction while maintaining reliability

---

## Lifecycle Hooks — Advanced Use Cases

```
Instance Launching:
EC2 Starting ──► PENDING:WAIT ──► [Your custom action] ──► PENDING:PROCEED ──► InService
                       │
                       ├── Pull application code from S3
                       ├── Register with service mesh (Consul/Envoy)
                       ├── Run health check before receiving traffic
                       └── Send Slack notification: "New instance joining"

Instance Terminating:
InService ──► TERMINATING:WAIT ──► [Your custom action] ──► TERMINATING:PROCEED ──► Terminated
                       │
                       ├── Drain active connections (graceful shutdown)
                       ├── Deregister from service discovery
                       ├── Push final logs to S3
                       └── Send notification: "Instance leaving"
```

```bash
# Add lifecycle hook for graceful shutdown
aws autoscaling put-lifecycle-hook \
    --lifecycle-hook-name "graceful-shutdown" \
    --auto-scaling-group-name prod-web-asg \
    --lifecycle-transition "autoscaling:EC2_INSTANCE_TERMINATING" \
    --heartbeat-timeout 300 \
    --notification-target-arn arn:aws:sns:us-east-1:ACCT:lifecycle-events \
    --role-arn arn:aws:iam::ACCT:role/ASGLifecycleRole
```

---

## Labs

### Lab 1: Create ASG with Target Tracking
```bash
# Create ASG
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name prod-web-asg \
    --launch-template LaunchTemplateName=prod-web-server,Version='$Latest' \
    --min-size 2 --max-size 10 --desired-capacity 3 \
    --vpc-zone-identifier "subnet-priv-1,subnet-priv-2" \
    --target-group-arns $TG_ARN \
    --health-check-type ELB --health-check-grace-period 300 \
    --tags Key=Name,Value=prod-web,PropagateAtLaunch=true

# Target tracking — keep CPU at 50%
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name prod-web-asg \
    --policy-name cpu-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "TargetValue": 50.0
    }'
```

### Lab 2: SNS Notifications on Scaling Events
```bash
aws autoscaling put-notification-configuration \
    --auto-scaling-group-name prod-web-asg \
    --topic-arn arn:aws:sns:us-east-1:ACCT:scaling-alerts \
    --notification-types \
        autoscaling:EC2_INSTANCE_LAUNCH \
        autoscaling:EC2_INSTANCE_TERMINATE \
        autoscaling:EC2_INSTANCE_LAUNCH_ERROR
```

### Lab 3: Custom Metric Scaling (requests per instance)
```bash
# Scale based on requests-per-target from ALB
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name prod-web-asg \
    --policy-name requests-per-target \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ALBRequestCountPerTarget",
            "ResourceLabel": "app/prod-alb/xxxx/targetgroup/web-targets/yyyy"
        },
        "TargetValue": 1000.0
    }'
```

---

## Interview Questions

1. **What is an Auto Scaling Group and why is it important?**
   > ASG automatically adjusts the number of EC2 instances based on demand. Ensures high availability (replaces unhealthy instances), cost efficiency (scale down when idle), and performance (scale up during peak).

2. **Explain target tracking vs step scaling.**
   > Target tracking: "Keep CPU at 50%"— ASG figures out how many instances to add/remove. Step scaling: "If CPU 60-80% add 1, if CPU 80%+ add 3." Target tracking is simpler and recommended for most cases. Step scaling gives fine-grained control.

3. **How does ASG handle instance failures?**
   > ASG performs health checks (EC2 status checks + ELB health checks). If an instance fails, ASG terminates it and launches a replacement in the same AZ to maintain desired capacity.

4. **What is the difference between desired, minimum, and maximum capacity?**
   > Min = never go below this (availability guarantee). Max = never exceed this (cost control). Desired = current target. Auto scaling adjusts desired between min and max based on policies.

5. **How do you deploy a new AMI across an ASG without downtime?**
   > Instance Refresh: Update launch template with new AMI, then start instance refresh with MinHealthyPercentage=80. ASG replaces instances in batches, ensuring 80% are always healthy.

6. **How do you reduce costs with ASG?**
   > Mixed instances policy: On-Demand base + Spot for scaling. Multiple instance types for Spot availability. Predictive/scheduled scaling to match known patterns. Scale-in aggressively during off-hours.

7. **What are lifecycle hooks and when to use them?**
   > Hooks pause instance launch/termination so you can run custom actions. Use cases: drain connections before termination, run configuration scripts before receiving traffic, register/deregister from service discovery.

8. **What is a warm pool and when is it useful?**
   > Pre-initialized instances in a stopped or running state, ready to join quickly. Normal launch: 3-5 minutes (boot + configure). Warm pool: 30 seconds (already configured, just start). Use for apps with long initialization times.
