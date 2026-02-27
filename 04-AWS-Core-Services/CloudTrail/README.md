# CloudTrail — API Audit Logging

> Records every API call in your AWS account. Essential for security auditing and compliance.

## Key Concepts
- **Management Events** — control plane operations (CreateBucket, RunInstances)
- **Data Events** — data plane operations (S3 GetObject, Lambda Invoke)
- **Insights Events** — anomaly detection (unusual API activity)
- **Trail** — configuration for logging to S3 + CloudWatch Logs
- **Organization Trail** — single trail for all accounts

## Labs
```bash
# Create trail
aws cloudtrail create-trail \
    --name production-audit-trail \
    --s3-bucket-name audit-logs-bucket \
    --is-multi-region-trail \
    --enable-log-file-validation \
    --cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:ACCT:log-group:cloudtrail \
    --cloud-watch-logs-role-arn arn:aws:iam::ACCT:role/CloudTrailRole

# Start logging
aws cloudtrail start-logging --name production-audit-trail

# Lookup events
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
    --max-results 10
```
