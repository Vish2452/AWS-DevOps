# CloudTrail — API Audit Logging

> Records every API call in your AWS account. Essential for security auditing, compliance, and incident investigation.

---

## Real-World Analogy

CloudTrail is like the **CCTV + visitor log book** at a bank:
- Every person who enters gets logged: **who** came, **when**, **what** they did, **from where**
- If money goes missing, you check the recordings to find out who opened the vault
- The logs are tamper-proof — nobody can delete the evidence
- You can set up alerts: "Notify me if anyone opens the vault after 9 PM"

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Management Events** | Control plane operations | Someone created a new S3 bucket or launched an EC2 instance |
| **Data Events** | Data plane operations | Someone downloaded a file from S3 or invoked a Lambda function |
| **Insights Events** | Anomaly detection | "Normally you have 5 API calls/min, suddenly there are 500" |
| **Trail** | Configuration for logging to S3 + CloudWatch | Your audit log pipeline setup |
| **Organization Trail** | Single trail for all accounts in AWS Org | Enterprise-wide auditing |
| **Log File Validation** | SHA-256 digest to detect tampering | Ensure nobody modified the audit logs |

---

## Real-Time Example 1: Security Incident Investigation

**Scenario:** Your AWS bill suddenly spikes to $50,000. Someone may have launched hundreds of EC2 instances for crypto mining. You need to find out WHO did it and WHEN.

```bash
# Step 1: Find who launched EC2 instances in the last 7 days
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
    --start-time "2026-02-23T00:00:00Z" \
    --end-time "2026-03-02T23:59:59Z" \
    --max-results 50

# Result might show:
# {
#   "Username": "compromised-user@company.com",
#   "EventTime": "2026-02-25T03:22:00Z",
#   "SourceIPAddress": "185.143.xx.xx",      ← Unknown IP from Russia!
#   "EventName": "RunInstances",
#   "Resources": [{"ResourceType": "AWS::EC2::Instance", "ResourceName": "i-0abc123"}]
# }
```

**Explanation:** CloudTrail recorded the entire attack. You can see:
- **Who**: The compromised IAM user
- **When**: 3:22 AM (unusual time)
- **From where**: Foreign IP address (not your office)
- **What**: Launched 200 high-CPU instances

**Response:** Disable the compromised user, terminate the instances, rotate all access keys, enable MFA.

---

## Real-Time Example 2: Compliance Auditing

**Scenario:** Your company needs SOC2 compliance. Auditors ask: "Can you prove that only authorized users access production databases?"

```bash
# Find all RDS-related actions by specific users
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::RDS::DBInstance \
    --start-time "2026-01-01T00:00:00Z" \
    --end-time "2026-03-01T23:59:59Z"

# This shows EVERY person who:
# - Created/deleted databases
# - Modified security groups
# - Took snapshots
# - Changed backup settings
```

**For deeper analysis with Athena:**
```sql
-- Create Athena table over CloudTrail logs in S3
-- Then query like a database:

SELECT 
    userIdentity.userName,
    eventName,
    eventTime,
    sourceIPAddress,
    requestParameters
FROM cloudtrail_logs
WHERE eventSource = 'rds.amazonaws.com'
    AND eventTime BETWEEN '2026-01-01' AND '2026-03-01'
ORDER BY eventTime DESC;
```

**Explanation:** CloudTrail logs stored in S3 can be queried with Athena (serverless SQL). This gives auditors a searchable database of every action taken in your AWS account. Companies like banks and healthcare organizations MUST have this for regulatory compliance.

---

## Real-Time Example 3: Alerting on Dangerous Actions

**Scenario:** You want to be notified IMMEDIATELY if someone:
- Deletes an S3 bucket
- Stops CloudTrail logging (covering their tracks)
- Creates an IAM user with admin access

```bash
# CloudTrail → CloudWatch Logs → Metric Filter → Alarm

# Step 1: Create metric filter for dangerous APIs
aws logs put-metric-filter \
    --log-group-name "CloudTrail/logs" \
    --filter-name "DangerousAPICall" \
    --filter-pattern '{ ($.eventName = "DeleteBucket") || 
                        ($.eventName = "StopLogging") || 
                        ($.eventName = "CreateUser") || 
                        ($.eventName = "AttachUserPolicy") }' \
    --metric-transformations \
        metricName=DangerousAPICalls,metricNamespace=SecurityAlerts,metricValue=1

# Step 2: Create alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "DangerousAPIDetected" \
    --metric-name DangerousAPICalls \
    --namespace SecurityAlerts \
    --statistic Sum --period 300 --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:security-team
```

**Explanation:** This creates a real-time security alert pipeline. If someone tries to stop CloudTrail (to hide their actions), you get notified instantly. This is a standard security best practice used in enterprise environments.

---

## CloudTrail Architecture

```
API Call (any AWS service)
        │
        ▼
   CloudTrail
        │
        ├──► S3 Bucket (long-term storage, Athena queries)
        │        └── Log file validation (tamper detection)
        │
        ├──► CloudWatch Logs (real-time alerting)
        │        └── Metric Filters → Alarms → SNS
        │
        └──► EventBridge (trigger automated responses)
                 └── Lambda → auto-remediate
```

---

## Labs

### Lab 1: Create Multi-Region Trail
```bash
# Create trail that logs ALL regions
aws cloudtrail create-trail \
    --name production-audit-trail \
    --s3-bucket-name audit-logs-bucket \
    --is-multi-region-trail \
    --enable-log-file-validation \
    --cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:ACCT:log-group:cloudtrail \
    --cloud-watch-logs-role-arn arn:aws:iam::ACCT:role/CloudTrailRole

# Start logging
aws cloudtrail start-logging --name production-audit-trail
```

### Lab 2: Enable Data Events (S3 + Lambda)
```bash
# Log every S3 read/write and Lambda invocation
aws cloudtrail put-event-selectors --trail-name production-audit-trail \
    --event-selectors '[{
        "ReadWriteType": "All",
        "IncludeManagementEvents": true,
        "DataResources": [
            {"Type": "AWS::S3::Object", "Values": ["arn:aws:s3:::sensitive-data-bucket/"]},
            {"Type": "AWS::Lambda::Function", "Values": ["arn:aws:lambda:us-east-1:ACCT:function:payment-processor"]}
        ]
    }]'
```

### Lab 3: Lookup Recent Events
```bash
# Find who deleted a specific resource
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket \
    --max-results 10

# Find all actions by a specific user
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=Username,AttributeValue=john@company.com \
    --max-results 20
```

---

## Best Practices

1. **Enable in ALL regions** — attackers target unused regions
2. **Enable log file validation** — detect tampering
3. **Send to S3 with versioning + MFA delete** — prevent log deletion
4. **Stream to CloudWatch Logs** — real-time alerting
5. **Enable Insights** — detect unusual API patterns
6. **Use Organization Trail** — cover all accounts
7. **Enable data events** for sensitive S3 buckets and critical Lambda functions
8. **Retain logs for 1+ year** — compliance requirement

---

## Interview Questions

1. **What is CloudTrail and why is it important?**
   > CloudTrail records every API call in your AWS account — who did what, when, and from where. It's essential for security auditing, compliance (SOC2, HIPAA), and incident investigation.

2. **What is the difference between Management Events and Data Events?**
   > Management events are control plane (CreateBucket, RunInstances). Data events are data plane (GetObject from S3, Invoke Lambda). Data events generate much higher volume and cost extra.

3. **How would you detect if someone compromised an AWS access key?**
   > Check CloudTrail for: API calls from unusual IP addresses, calls at unusual times, bulk resource creation (crypto mining), disabled security features. Set up automated alerting with CloudWatch metric filters.

4. **What is log file validation and why enable it?**
   > CloudTrail creates SHA-256 digests of each log file. If someone modifies a log to cover their tracks, the digest won't match − proving tampering occurred. Essential for legal evidence.

5. **How do you query CloudTrail logs at scale?**
   > Store logs in S3, create an Athena table over them, then run SQL queries. Example: "Show me all IAM changes in the last 90 days." This is how large enterprises perform security investigations.

6. **What is CloudTrail Insights?**
   > ML-based anomaly detection for API call patterns. If your account normally sees 10 RunInstances/day and suddenly sees 500, Insights generates an event. Great for detecting compromised credentials or misconfigured automation.

7. **Should you enable CloudTrail in all regions? Why?**
   > Yes, always. Attackers intentionally target regions you don't use (e.g., ap-southeast-1) because they assume you're not monitoring there. A multi-region trail catches this.

8. **How do you prevent someone from deleting CloudTrail logs?**
   > S3 bucket policy denying DeleteObject, enable S3 versioning + MFA Delete, use S3 Object Lock, restrict trail modification with SCP in AWS Organizations.
