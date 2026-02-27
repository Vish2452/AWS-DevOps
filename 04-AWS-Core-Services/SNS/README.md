# SNS — Simple Notification Service

> Pub/sub messaging for decoupled architectures. Fan-out notifications to multiple subscribers.

## Subscription Types
- **Email/SMS** — human notifications
- **Lambda** — serverless processing
- **SQS** — queue for async processing
- **HTTP/HTTPS** — webhook endpoints
- **Kinesis Firehose** — stream to S3/Redshift

## Labs
```bash
# Create topic
TOPIC_ARN=$(aws sns create-topic --name deploy-notifications --query 'TopicArn' --output text)

# Subscribe email
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint team@example.com

# Subscribe Lambda
aws sns subscribe --topic-arn $TOPIC_ARN --protocol lambda \
    --notification-endpoint arn:aws:lambda:us-east-1:ACCT:function:process-alert

# Publish message
aws sns publish --topic-arn $TOPIC_ARN \
    --subject "Deployment Complete" \
    --message "v1.2.3 deployed to production successfully at $(date)"
```
