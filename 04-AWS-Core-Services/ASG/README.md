# ASG — Auto Scaling Groups

> Automatically adjust compute capacity based on demand. Essential for cost efficiency and high availability.

## Scaling Policies
| Type | How It Works | Use Case |
|------|-------------|----------|
| **Target Tracking** | Maintain metric at target (e.g., CPU 50%) | Most common |
| **Step Scaling** | Scale by different amounts at thresholds | Complex rules |
| **Simple Scaling** | Scale by fixed amount, cooldown | Legacy |
| **Predictive** | ML-based forecast | Recurring patterns |
| **Scheduled** | Time-based scaling | Known peak times |

## Key Concepts
- **Launch Template** — defines instance configuration
- **Desired/Min/Max** — capacity boundaries
- **Lifecycle Hooks** — custom actions on launch/terminate
- **Warm Pools** — pre-initialized instances for fast scaling
- **Instance Refresh** — rolling update of all instances

## Labs
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

# Target tracking scaling policy
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

# SNS notification on scaling events
aws autoscaling put-notification-configuration \
    --auto-scaling-group-name prod-web-asg \
    --topic-arn arn:aws:sns:us-east-1:ACCT:scaling-alerts \
    --notification-types \
        autoscaling:EC2_INSTANCE_LAUNCH \
        autoscaling:EC2_INSTANCE_TERMINATE
```
