# CloudWatch — Monitoring & Logging

> Centralized monitoring for all AWS resources. Metrics, logs, alarms, and dashboards — the "eyes and ears" of your AWS infrastructure.

---

## Real-World Analogy

Think of CloudWatch as the **security camera system + fire alarm** of a building:
- **Metrics** = temperature sensors, door counters, motion detectors
- **Alarms** = fire alarm that calls 911 when temperature exceeds threshold
- **Logs** = security camera recordings — review later if something goes wrong
- **Dashboards** = the security guard's monitor wall showing all camera feeds
- **EventBridge** = the smart assistant that says "If door opens after midnight, alert the manager"

---

## Components

| Component | Purpose | Real-Time Example |
|-----------|---------|-------------------|
| **Metrics** | Numerical data points (CPU, memory, custom) | Track EC2 CPU — if it stays at 95% for 5 min, indicates a problem |
| **Logs** | Log groups → log streams (application logs) | Store Nginx access logs — search for 5xx errors |
| **Alarms** | Trigger actions based on metric thresholds | CPU > 80% for 5 min → send SMS to on-call engineer |
| **Dashboards** | Visual monitoring views | CEO-friendly view: uptime %, latency, error rate |
| **Events/EventBridge** | React to AWS state changes | EC2 instance terminated → trigger Lambda to investigate |
| **Log Insights** | Query and analyze logs | "Show me the top 10 slowest API calls in the last hour" |
| **Container Insights** | ECS/EKS monitoring | Track pod CPU/memory across your Kubernetes cluster |
| **Contributor Insights** | Identify top-N contributors | Find the top 5 IP addresses hitting your API |
| **Synthetics (Canaries)** | Monitor endpoints proactively | Hit your login page every 5 min to ensure it works |
| **Anomaly Detection** | ML-based automatic thresholds | Detect unusual traffic spikes without setting manual thresholds |

---

## Real-Time Example 1: E-Commerce Application Monitoring

**Scenario:** You run an online shopping app (like Flipkart/Amazon). During a sale event, you need to ensure the app stays up.

```
                    CloudWatch Dashboard
                    ┌──────────────────────────────────────────┐
                    │  CPU: ██████████░░ 78%   Memory: 65%     │
                    │  Active Users: 12,450   Orders/min: 342  │
                    │  Error Rate: 0.3%       Latency: 120ms   │
                    │                                          │
                    │  ⚠️ ALARM: RDS connections at 85%         │
                    │  ✅ All health checks passing             │
                    └──────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
     EC2 Metrics        RDS Metrics       ALB Metrics
     - CPU Usage        - Connections     - Request Count
     - Network I/O      - Read IOPS       - 5xx Errors
     - Disk I/O         - Replica Lag     - Target Response
```

**What happens:**
1. **Metrics collected** every 60 seconds (or 1 sec with detailed monitoring)
2. **Alarm triggers** when DB connections > 80% → SNS sends alert to Slack
3. **Auto Scaling** kicks in when CPU > 70% → adds more EC2 instances
4. **Dashboard** shows live status — operations team watches during sale

---

## Real-Time Example 2: Application Log Analysis

**Scenario:** Users report "payment failed" errors. You need to find the root cause.

```bash
# Step 1: Search for payment errors in the last 2 hours
aws logs start-query --log-group-name /app/production \
    --start-time $(date -d '2 hours ago' +%s) \
    --end-time $(date +%s) \
    --query-string '
        fields @timestamp, @message, userId, errorCode
        | filter @message like /payment.*failed/
        | stats count() by errorCode
        | sort count desc
        | limit 10
    '

# Result shows: 
# errorCode=GATEWAY_TIMEOUT  → 342 occurrences
# errorCode=INVALID_CARD     → 23 occurrences
# Root cause: Payment gateway is timing out!
```

**Explanation:** CloudWatch Logs Insights lets you query logs with SQL-like syntax. Instead of SSH-ing into 50 servers and running `grep`, you search ALL logs from one place. This is how production teams debug issues in real companies.

---

## Real-Time Example 3: Custom Metrics for Business KPIs

**Scenario:** Your CEO wants to know "How many orders per minute are we processing?"

```python
# Lambda function that pushes custom business metrics
import boto3

cloudwatch = boto3.client('cloudwatch')

def handler(event, context):
    # After processing an order...
    cloudwatch.put_metric_data(
        Namespace='MyEcommerceApp',
        MetricData=[
            {
                'MetricName': 'OrdersProcessed',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'Environment', 'Value': 'production'},
                    {'Name': 'Region', 'Value': 'us-east-1'}
                ]
            },
            {
                'MetricName': 'OrderValue',
                'Value': event['orderTotal'],
                'Unit': 'None',
                'Dimensions': [
                    {'Name': 'Category', 'Value': event['category']}
                ]
            }
        ]
    )
```

**Explanation:** AWS default metrics only cover infrastructure (CPU, memory). For business metrics (orders, revenue, sign-ups), you push **custom metrics**. Now you can create alarms like "If orders drop below 10/min during business hours, alert the team."

---

## Metric Resolution & Costs

| Type | Frequency | Cost | Use Case |
|------|-----------|------|----------|
| **Basic Monitoring** | 5 minutes | Free | Development/testing |
| **Detailed Monitoring** | 1 minute | $3.50/instance/month | Production EC2 |
| **High-Resolution** | 1 second | Custom metric pricing | Trading platforms, gaming |

---

## CloudWatch Alarms — Deep Dive

### Alarm States
```
OK ──────────► ALARM ──────────► INSUFFICIENT_DATA
 ▲                │                     │
 └────────────────┘─────────────────────┘
    (metric recovers)    (no data points)
```

### Composite Alarms
```bash
# Only alert if BOTH CPU is high AND error rate is high
# (Avoids false alarms during deployments)
aws cloudwatch put-composite-alarm \
    --alarm-name "Production-Critical" \
    --alarm-rule 'ALARM("HighCPU") AND ALARM("HighErrorRate")' \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:pager-duty
```

**Real-world use:** During deployments, CPU spikes briefly (normal). A composite alarm ensures you only get paged when CPU is high AND errors are increasing — meaning a real problem.

---

## CloudWatch Synthetics (Canaries)

**Scenario:** You want to know when your website goes down BEFORE customers report it.

```javascript
// Canary script — runs every 5 minutes from multiple AWS regions
const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const pageLoadBlueprint = async function () {
    const page = await synthetics.getPage();
    
    // Test 1: Homepage loads
    const response = await page.goto('https://www.myapp.com', {
        waitUntil: 'domcontentloaded', timeout: 30000
    });
    if (response.status() !== 200) throw new Error('Homepage failed');
    
    // Test 2: Login flow works
    await page.type('#email', 'test@myapp.com');
    await page.type('#password', 'testPassword');
    await page.click('#login-button');
    await page.waitForSelector('#dashboard', { timeout: 10000 });
    
    log.info('All checks passed!');
};

exports.handler = async () => {
    return await pageLoadBlueprint();
};
```

**Explanation:** This is like having a robot customer that tries to use your website every 5 minutes. If it fails, you get alerted immediately — often before any real customer even notices.

---

## Labs

### Lab 1: Create Custom Metric and Alarm
```bash
# Push custom metric
aws cloudwatch put-metric-data --namespace "MyApp" \
    --metric-name "ActiveUsers" --value 42 --unit Count

# Create alarm that triggers when fewer than 5 active users (something is wrong)
aws cloudwatch put-metric-alarm --alarm-name "LowActiveUsers" \
    --metric-name ActiveUsers --namespace MyApp \
    --statistic Average --period 300 --threshold 5 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:alerts \
    --treat-missing-data breaching
```

### Lab 2: Set Up EC2 CPU Alarm with Auto Recovery
```bash
# If EC2 instance becomes unreachable, automatically reboot it
aws cloudwatch put-metric-alarm --alarm-name "EC2-AutoRecover" \
    --metric-name StatusCheckFailed_System --namespace AWS/EC2 \
    --statistic Maximum --period 60 --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:automate:us-east-1:ec2:recover \
    --dimensions Name=InstanceId,Value=i-xxxx
```

### Lab 3: Query Application Logs
```bash
# Find all ERROR entries in the last hour
aws logs start-query --log-group-name /app/production \
    --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s) \
    --query-string '
        fields @timestamp, @message
        | filter @message like /ERROR/
        | sort @timestamp desc
        | limit 20
    '

# Get query results
aws logs get-query-results --query-id QUERY_ID
```

### Lab 4: Create Monitoring Dashboard
```bash
aws cloudwatch put-dashboard --dashboard-name "Production-Overview" \
    --dashboard-body '{
        "widgets": [
            {
                "type": "metric",
                "properties": {
                    "title": "EC2 CPU Utilization",
                    "metrics": [["AWS/EC2","CPUUtilization","InstanceId","i-xxxx"]],
                    "period": 300, "stat": "Average"
                },
                "width": 12, "height": 6
            },
            {
                "type": "metric",
                "properties": {
                    "title": "ALB Request Count",
                    "metrics": [["AWS/ApplicationELB","RequestCount","LoadBalancer","app/prod-alb/xxxx"]],
                    "period": 60, "stat": "Sum"
                },
                "width": 12, "height": 6
            }
        ]
    }'
```

---

## Interview Questions

1. **What is the difference between CloudWatch Metrics and CloudWatch Logs?**
   > Metrics are numerical time-series data (CPU: 78%). Logs are text records (Nginx access log entries). You monitor infrastructure with metrics and debug applications with logs.

2. **How would you monitor a production application that runs on 50 EC2 instances?**
   > Install CloudWatch Agent on all instances → push memory/disk metrics + application logs → create dashboards → set alarms for CPU >80%, disk >90%, error rate >1% → route alarms through SNS to Slack/PagerDuty.

3. **What is the difference between basic and detailed monitoring?**
   > Basic: free, 5-minute intervals. Detailed: paid, 1-minute intervals. Use detailed for production where you need faster alarm response.

4. **How does a composite alarm work and why use it?**
   > It combines multiple alarms with AND/OR logic. Example: only alert if CPU is high AND errors are increasing. Reduces false positives — CPU spikes during deployments are normal if errors don't increase.

5. **Explain CloudWatch Logs Insights with a real use case.**
   > SQL-like query engine for logs. Example: "In the last hour, group all 500 errors by API endpoint and show the top 10." Saves hours vs SSH-ing into servers and grepping manually.

6. **What is the difference between CloudWatch Events and EventBridge?**
   > EventBridge is the next generation of CloudWatch Events. It supports custom event buses, third-party integrations (Datadog, PagerDuty), schema registry, and cross-account routing. Always use EventBridge for new projects.

7. **How do you monitor Lambda functions with CloudWatch?**
   > Lambda automatically sends metrics: Invocations, Duration, Errors, Throttles, ConcurrentExecutions. Set alarms on Errors > 0 and Duration > timeout threshold. Logs go to CloudWatch Logs automatically.

8. **What are CloudWatch Canaries and when would you use them?**
   > Automated scripts that run on a schedule to test your endpoints/APIs. Use them for synthetic monitoring — detect if your website is down before customers notice. Runs from multiple regions to test global availability.
