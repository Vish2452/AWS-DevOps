# SNS — Simple Notification Service

> Pub/sub messaging for decoupled architectures. Fan-out notifications to multiple subscribers simultaneously. The "megaphone" of AWS.

---

## Real-World Analogy

SNS is like a **WhatsApp group** or a **radio broadcast**:
- **Topic** = a WhatsApp group (e.g., "Server Alerts")
- **Publisher** = someone sends a message to the group
- **Subscribers** = everyone in the group receives it simultaneously
- **Fan-out** = one message → delivered to email, SMS, Slack, Lambda ALL at the same time
- Unlike SQS (which is a queue/mailbox), SNS pushes messages immediately

---

## How SNS Fits in Architecture

```
Event occurs (server down, deployment complete, new order)
        │
        ▼
   SNS Topic
        │
        ├──► Email → DevOps team gets email alert
        ├──► SMS → On-call engineer gets text message
        ├──► Lambda → Auto-remediation function runs
        ├──► SQS → Queue for processing (fan-out pattern)
        ├──► HTTP/HTTPS → Webhook to Slack/PagerDuty
        └──► Kinesis Firehose → Archive to S3/Redshift
```

---

## Subscription Types

| Protocol | Use Case | Real-World Example |
|----------|----------|-------------------|
| **Email/SMS** | Human notifications | "Server CPU at 95% - investigate immediately" |
| **Lambda** | Serverless processing | Auto-terminate rogue EC2 instances |
| **SQS** | Async queue processing | Order placed → queue for payment, inventory, shipping |
| **HTTP/HTTPS** | Webhook endpoints | Send alerts to Slack, PagerDuty, custom dashboard |
| **Kinesis Firehose** | Stream to storage | Archive all alerts to S3 for compliance |
| **Mobile Push** | App notifications | "Your order has been shipped!" push notification |

---

## Real-Time Example 1: DevOps Alert Pipeline

**Scenario:** Your production application runs on EC2 behind an ALB. You need to alert the team when things go wrong.

```
CloudWatch Alarm (CPU > 80%)
        │
        ▼
   SNS Topic: "production-alerts"
        │
        ├──► Email: devops-team@company.com
        │    Subject: "⚠️ High CPU Alert - prod-web-01"
        │    Body: "CPU at 87% for 5 minutes. Investigate immediately."
        │
        ├──► SMS: +1-555-123-4567 (on-call engineer)
        │    "ALARM: prod-web-01 CPU 87%. Check CloudWatch."
        │
        ├──► Lambda: auto-scale-handler
        │    Automatically adds 2 more instances to the ASG
        │
        └──► HTTPS: https://hooks.slack.com/services/xxxx
             Posts formatted alert to #production-alerts Slack channel
```

```bash
# Set up this entire pipeline:

# 1. Create topic
TOPIC_ARN=$(aws sns create-topic --name production-alerts --query 'TopicArn' --output text)

# 2. Subscribe email
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol email \
    --notification-endpoint devops-team@company.com

# 3. Subscribe SMS
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol sms \
    --notification-endpoint "+15551234567"

# 4. Subscribe Lambda for auto-remediation
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol lambda \
    --notification-endpoint arn:aws:lambda:us-east-1:ACCT:function:auto-scale-handler

# 5. Subscribe Slack webhook
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol https \
    --notification-endpoint "https://hooks.slack.com/services/T00/B00/xxxx"

# 6. Link CloudWatch alarm to SNS
aws cloudwatch put-metric-alarm --alarm-name "HighCPU" \
    --metric-name CPUUtilization --namespace AWS/EC2 \
    --statistic Average --period 300 --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $TOPIC_ARN
```

---

## Real-Time Example 2: E-Commerce Order Fan-Out

**Scenario:** When a customer places an order, multiple systems need to process it simultaneously: payment, inventory, shipping, email confirmation.

```
Customer places order
        │
        ▼
   SNS Topic: "new-order"
        │
        ├──► SQS: payment-queue → Payment service processes payment
        ├──► SQS: inventory-queue → Inventory service reserves stock
        ├──► SQS: shipping-queue → Shipping service creates label
        ├──► Lambda: send-confirmation → Sends order confirmation email
        └──► Kinesis Firehose → Archives order to S3 for analytics
```

**Why this pattern?**
- **Decoupled:** If the shipping service is down, payment and inventory still process
- **Scalable:** Each queue can be processed at its own speed
- **Reliable:** SQS retries failed messages automatically
- Without SNS, you'd need the order service to call each system individually — one failure breaks everything

```python
# Publishing an order event from your application:
import boto3, json

sns = boto3.client('sns')

def place_order(order):
    # Save order to database...
    
    # Fan-out to all downstream systems
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:ACCT:new-order',
        Subject='NewOrder',
        Message=json.dumps({
            'orderId': order['id'],
            'customerId': order['customerId'],
            'items': order['items'],
            'total': order['total'],
            'timestamp': '2026-03-02T10:30:00Z'
        }),
        MessageAttributes={
            'orderType': {
                'DataType': 'String',
                'StringValue': order['type']  # 'standard' or 'express'
            }
        }
    )
```

---

## Real-Time Example 3: SNS Message Filtering

**Scenario:** You have one "orders" topic, but the shipping service should only process express orders, not standard ones.

```bash
# Subscribe shipping service ONLY to express orders
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:us-east-1:ACCT:express-shipping-queue \
    --attributes '{
        "FilterPolicy": "{\"orderType\": [\"express\"]}"
    }'

# Subscribe standard processing to standard orders
aws sns subscribe --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:us-east-1:ACCT:standard-processing-queue \
    --attributes '{
        "FilterPolicy": "{\"orderType\": [\"standard\"]}"
    }'
```

**Explanation:** Message filtering lets subscribers receive only relevant messages. Without filtering, every subscriber gets every message and must discard irrelevant ones — wasteful and expensive at scale.

---

## SNS vs SQS — When to Use Each

| Feature | SNS (Notification) | SQS (Queue) |
|---------|-------------------|-------------|
| **Pattern** | Pub/Sub (push) | Queue (pull) |
| **Delivery** | Immediate push | Consumer polls for messages |
| **Consumers** | Multiple (fan-out) | Single consumer group |
| **Persistence** | No (fire and forget) | Yes (up to 14 days) |
| **Use Case** | Alerts, fan-out | Work queues, decoupling |
| **Retry** | Limited | Built-in retry + DLQ |

**Best practice:** Often used together — **SNS → SQS** (fan-out to queues)

---

## Advanced Features

| Feature | Description |
|---------|-------------|
| **FIFO Topics** | Ordered, exactly-once delivery (paired with FIFO SQS) |
| **Message Filtering** | Subscribers only receive matching messages |
| **Dead Letter Queue** | Failed deliveries sent to SQS DLQ for investigation |
| **Encryption** | SSE with KMS for sensitive messages |
| **Cross-account** | Publish from one AWS account, subscribe in another |
| **Message Archiving** | Store all messages in Kinesis Firehose for audit |

---

## Labs

### Lab 1: Create Alert Pipeline
```bash
# Create topic and subscribe
TOPIC_ARN=$(aws sns create-topic --name deploy-notifications --query 'TopicArn' --output text)
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint team@example.com

# Publish test message
aws sns publish --topic-arn $TOPIC_ARN \
    --subject "Deployment Complete" \
    --message "v1.2.3 deployed to production successfully at $(date)"
```

### Lab 2: Fan-Out Pattern (SNS → Multiple SQS)
```bash
# Create queues
for q in payment inventory shipping; do
    aws sqs create-queue --queue-name order-${q}-queue
done

# Subscribe all queues to one topic
for q in payment inventory shipping; do
    QUEUE_ARN=$(aws sqs get-queue-attributes \
        --queue-url "https://sqs.us-east-1.amazonaws.com/ACCT/order-${q}-queue" \
        --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
    aws sns subscribe --topic-arn $TOPIC_ARN \
        --protocol sqs --notification-endpoint $QUEUE_ARN
done
```

### Lab 3: FIFO Topic for Ordered Processing
```bash
# Create FIFO topic (name must end with .fifo)
aws sns create-topic --name orders.fifo \
    --attributes FifoTopic=true,ContentBasedDeduplication=true

# Messages are delivered in order and exactly once
```

---

## Interview Questions

1. **What is SNS and how is it different from SQS?**
   > SNS is pub/sub (push to many subscribers simultaneously). SQS is a message queue (one consumer pulls messages). SNS is for fan-out and notifications, SQS is for decoupling and work queues.

2. **Explain the fan-out pattern with a real example.**
   > When an order is placed, publish to SNS → subscribers include SQS queues for payment, inventory, shipping, and a Lambda for email confirmation. One event triggers multiple independent processes.

3. **What is SNS message filtering and why use it?**
   > Subscribers set a filter policy to receive only relevant messages. Example: express shipping queue only gets messages where `orderType = "express"`. Reduces unnecessary processing and costs.

4. **How do you ensure message delivery with SNS?**
   > Use SNS → SQS for guaranteed delivery (SQS persists messages). Configure a dead letter queue for failed deliveries. For critical paths, use FIFO topics for exactly-once, ordered delivery.

5. **What is the difference between Standard and FIFO SNS topics?**
   > Standard: best-effort ordering, at-least-once delivery, nearly unlimited throughput. FIFO: strict ordering within message groups, exactly-once delivery, but limited to 300 messages/sec.

6. **How would you send CloudWatch alarms to Slack?**
   > CloudWatch Alarm → SNS Topic → Lambda function → Lambda formats the message and calls Slack webhook API. Alternatively, use AWS Chatbot which integrates SNS directly with Slack.

7. **Can SNS deliver messages across AWS accounts?**
   > Yes. Set the SNS topic policy to allow the other account's ARN to subscribe or publish. Common in enterprise setups where a central security account receives alerts from all accounts.

8. **What happens if an SNS subscriber is temporarily down?**
   > For Lambda/SQS: SNS retries with exponential backoff. For HTTP: configurable retry policy (up to 100 retries over hours). For email/SMS: limited retries. Best practice: use SNS → SQS so messages aren't lost.
