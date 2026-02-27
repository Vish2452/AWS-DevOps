# CloudWatch — Monitoring & Logging

> Centralized monitoring for all AWS resources. Metrics, logs, alarms, and dashboards.

## Components
| Component | Purpose |
|-----------|---------|
| **Metrics** | Numerical data points (CPU, memory, custom) |
| **Logs** | Log groups → log streams (application logs) |
| **Alarms** | Trigger actions based on metric thresholds |
| **Dashboards** | Visual monitoring views |
| **Events/EventBridge** | React to AWS state changes |
| **Log Insights** | Query and analyze logs |
| **Container Insights** | ECS/EKS monitoring |

## Labs
```bash
# Create custom metric
aws cloudwatch put-metric-data --namespace "MyApp" \
    --metric-name "ActiveUsers" --value 42 --unit Count

# Create alarm
aws cloudwatch put-metric-alarm --alarm-name "HighCPU" \
    --metric-name CPUUtilization --namespace AWS/EC2 \
    --statistic Average --period 300 --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:alerts \
    --dimensions Name=InstanceId,Value=i-xxxx

# Query logs
aws logs start-query --log-group-name /app/production \
    --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s) \
    --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'
```
