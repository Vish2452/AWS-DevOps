# SQS — Simple Queue Service

> Fully managed message queuing service for decoupling microservices. Processes billions of messages daily with zero administration.

---

## Real-World Analogy

SQS is like a **restaurant order ticket system**:
- **Producer** = Waiter writes order tickets and puts them on the rack
- **Queue** = The order rack between kitchen and waiters
- **Consumer** = Cook takes tickets from the rack, prepares food
- **Visibility Timeout** = Cook takes a ticket — others can't see it while being prepared
- **Dead Letter Queue** = If a dish fails 3 times, ticket goes to the "problem orders" pile for manager review
- **FIFO** = Sushi bar where orders MUST be prepared in exact sequence

---

## Queue Types

| Feature | Standard Queue | FIFO Queue |
|---------|---------------|------------|
| **Throughput** | Unlimited (thousands/sec) | 300 msg/sec (3,000 with batching) |
| **Order** | Best-effort (may be out of order) | Guaranteed FIFO |
| **Delivery** | At-least-once (possible duplicates) | Exactly-once processing |
| **Use Case** | High-throughput, order doesn't matter | Financial transactions, inventory |
| **Name** | Any name | Must end in `.fifo` |
| **Cost** | $0.40 per million requests | $0.50 per million requests |

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Message** | Up to 256KB payload | `{"orderId": "123", "action": "process"}` |
| **Visibility Timeout** | Time message is invisible after read (default: 30s) | Cook has 30s to prepare before order goes back |
| **Retention Period** | How long messages stay (1 min - 14 days, default: 4 days) | Old orders expire after 4 days |
| **Delay Queue** | Postpone delivery of new messages | "Process refund after 5-minute cooling period" |
| **Dead Letter Queue** | Failed messages moved here after N retries | Orders that keep failing → manager review |
| **Long Polling** | Wait up to 20s for messages (reduces empty responses) | Cook waits at rack instead of checking every second |
| **Message Groups** | FIFO only — parallel processing with per-group ordering | Separate lanes per customer |

---

## Real-Time Example 1: E-Commerce Order Processing Pipeline

**Scenario:** Your e-commerce platform gets 10,000 orders per minute during sales events. Processing each order (payment, inventory, shipping) takes 5 seconds. You can't process synchronously — website would time out.

```
                 ┌─────────────────────────────────────────────────────┐
                 │              Order Processing Pipeline               │
                 └──────────────────────┬──────────────────────────────┘
                                        │
 ┌──────────┐    ┌──────────┐    ┌──────▼──────┐    ┌──────────┐
 │  Web App  │──▶│ Order    │──▶│  Payment    │──▶│ Inventory │
 │  (API GW) │    │  Queue   │    │  Lambda     │    │  Queue    │
 │           │    │ (SQS)    │    │  (Process)  │    │  (SQS)    │
 └──────────┘    └──────────┘    └─────────────┘    └─────┬─────┘
                       │                                     │
                 ┌─────▼─────┐                      ┌───────▼───────┐
                 │  DLQ      │                      │  Warehouse    │
                 │  (Failed  │                      │  Lambda       │
                 │   Orders) │                      │  (Ship)       │
                 └───────────┘                      └───────┬───────┘
                                                            │
                                                    ┌───────▼───────┐
                                                    │ Notification  │
                                                    │ Queue (SQS)   │
                                                    │ → SNS Email   │
                                                    └───────────────┘

 Benefits:
 - Web app responds in <200ms (just puts message on queue)
 - Each stage scales independently
 - Failed payments retry automatically (3x then → DLQ)
 - Can handle 10,000 orders/min during Black Friday
```

```bash
# Create the order processing queue
aws sqs create-queue --queue-name order-processing \
    --attributes '{
        "VisibilityTimeout": "300",
        "MessageRetentionPeriod": "86400",
        "ReceiveMessageWaitTimeSeconds": "20",
        "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:ACCT:order-dlq\",\"maxReceiveCount\":\"3\"}"
    }'

# Create Dead Letter Queue
aws sqs create-queue --queue-name order-dlq \
    --attributes '{"MessageRetentionPeriod": "1209600"}'

# Send an order message
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/order-processing \
    --message-body '{
        "orderId": "ORD-2026-001",
        "customerId": "CUST-456",
        "items": [{"sku": "LAPTOP-001", "qty": 1, "price": 999.00}],
        "total": 999.00,
        "timestamp": "2026-01-15T10:30:00Z"
    }'

# Receive and process (consumer)
MSG=$(aws sqs receive-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/order-processing \
    --max-number-of-messages 10 \
    --wait-time-seconds 20)

# After processing, delete the message
aws sqs delete-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/order-processing \
    --receipt-handle $RECEIPT_HANDLE
```

---

## Real-Time Example 2: FIFO Queue for Financial Transactions

**Scenario:** Your banking application processes transactions. Order matters — a withdrawal must be processed after a deposit, or the account goes negative. Standard SQS could process out of order.

```bash
# Create FIFO queue (name MUST end in .fifo)
aws sqs create-queue --queue-name transactions.fifo \
    --attributes '{
        "FifoQueue": "true",
        "ContentBasedDeduplication": "true",
        "DeduplicationScope": "messageGroup",
        "FifoThroughputLimit": "perMessageGroupId"
    }'

# Send transactions for account A-123 (all in same message group = ordered)
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/transactions.fifo \
    --message-body '{"type": "deposit", "amount": 1000, "account": "A-123"}' \
    --message-group-id "A-123" \
    --message-deduplication-id "txn-001"

aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/transactions.fifo \
    --message-body '{"type": "withdrawal", "amount": 500, "account": "A-123"}' \
    --message-group-id "A-123" \
    --message-deduplication-id "txn-002"

# Different account can be processed in parallel (different message group)
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/transactions.fifo \
    --message-body '{"type": "deposit", "amount": 2000, "account": "B-456"}' \
    --message-group-id "B-456" \
    --message-deduplication-id "txn-003"

# Result: A-123 deposit processes before withdrawal (FIFO within group)
#         B-456 processes in parallel (different group)
```

---

## Real-Time Example 3: Auto-Scaling Workers Based on Queue Depth

**Scenario:** You have EC2 workers processing video transcoding jobs from SQS. During upload spikes, the queue grows. You want workers to auto-scale based on queue depth.

```bash
# CloudWatch alarm on queue depth
aws cloudwatch put-metric-alarm \
    --alarm-name "VideoQueue-HighDepth" \
    --metric-name ApproximateNumberOfMessagesVisible \
    --namespace AWS/SQS \
    --dimensions Name=QueueName,Value=video-transcoding \
    --statistic Average \
    --period 60 \
    --threshold 100 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:us-east-1:ACCT:scalingPolicy:xxx

# Or use Step Scaling:
# 0-50 messages    → 2 workers
# 50-200 messages  → 5 workers
# 200-1000 messages → 10 workers
# 1000+ messages   → 20 workers
```

---

## SQS vs SNS vs EventBridge

| Feature | SQS | SNS | EventBridge |
|---------|-----|-----|-------------|
| **Pattern** | Queue (point-to-point) | Pub/Sub (fan-out) | Event bus (routing) |
| **Consumers** | One consumer per message | Multiple subscribers | Rule-based routing |
| **Persistence** | Yes (up to 14 days) | No (immediate delivery) | Yes (archive + replay) |
| **Use Case** | Decouple producers from consumers | Notify multiple systems | Event-driven architecture |
| **Example** | Order processing pipeline | Alert ops, email user, log | Route AWS events to targets |

---

## Labs

### Lab 1: Create Queue with DLQ
```bash
# DLQ first
DLQ_ARN=$(aws sqs create-queue --queue-name my-app-dlq \
    --query 'QueueUrl' --output text)
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url $DLQ_ARN \
    --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

# Main queue with DLQ
aws sqs create-queue --queue-name my-app-queue \
    --attributes "{
        \"VisibilityTimeout\": \"60\",
        \"ReceiveMessageWaitTimeSeconds\": \"20\",
        \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
    }"
```

### Lab 2: Lambda Trigger from SQS
```bash
# Create event source mapping (Lambda polls SQS automatically)
aws lambda create-event-source-mapping \
    --function-name order-processor \
    --event-source-arn arn:aws:sqs:us-east-1:ACCT:order-processing \
    --batch-size 10 \
    --maximum-batching-window-in-seconds 5 \
    --function-response-types ReportBatchItemFailures
```

### Lab 3: Monitor Queue Metrics
```bash
# Check queue depth
aws sqs get-queue-attributes \
    --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/my-app-queue \
    --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

# Check DLQ for failed messages
aws sqs receive-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/ACCT/my-app-dlq \
    --max-number-of-messages 10
```

---

## Interview Questions

1. **What is SQS and when would you use it?**
   > SQS is a fully managed message queue for decoupling application components. Use it when: you need to absorb traffic spikes (queue buffers bursts), decouple microservices (producer doesn't wait for consumer), need guaranteed delivery (messages persist until processed), or want independent scaling of producers and consumers.

2. **Standard vs FIFO queue — what's the difference?**
   > Standard: unlimited throughput, best-effort ordering, at-least-once delivery (possible duplicates). FIFO: 300 msg/sec (3,000 batched), strict ordering within message groups, exactly-once processing. Use FIFO for: financial transactions, inventory updates, anything where order/deduplication matters.

3. **What is a Dead Letter Queue and why is it important?**
   > DLQ receives messages that failed processing after N retries (maxReceiveCount). Without DLQ, failed messages block the queue (poison pill problem). With DLQ, failures are isolated for investigation. Best practice: set maxReceiveCount=3, monitor DLQ depth via CloudWatch alarm, and set up alerts for any messages in DLQ.

4. **How does visibility timeout work?**
   > When a consumer receives a message, it becomes invisible to other consumers for the visibility timeout period (default: 30s). If the consumer processes and deletes it within this window — done. If it doesn't delete it (crash/timeout), the message becomes visible again for another consumer to try. Set visibility timeout > your processing time.

5. **How would you scale consumers based on queue depth?**
   > Use CloudWatch metric `ApproximateNumberOfMessagesVisible` with Auto Scaling step policies. Example: 0-50 msgs → 2 instances, 50-200 → 5, 200+ → 10. For Lambda consumers, concurrency auto-scales (up to 1,000 concurrent). Also consider the backlog-per-instance metric: `QueueMessages / RunningInstances`.

6. **SQS vs SNS — when to use which?**
   > **SQS:** One consumer processes each message (work queue pattern). Messages persist until processed. **SNS:** Fan-out — one message goes to multiple subscribers. No persistence. **Together (fan-out pattern):** SNS publishes to multiple SQS queues, each processed independently. Example: Order placed → SNS → Payment SQS + Inventory SQS + Email SQS.

7. **What is long polling and why use it?**
   > Without long polling, `ReceiveMessage` returns immediately (even if empty) — wastes API calls and costs money. Long polling (set `WaitTimeSeconds` up to 20s) waits for messages to arrive before returning. Reduces empty responses by 90%+, reduces costs, and decreases latency.

8. **How do you ensure exactly-once processing with Standard queues?**
   > Standard queues deliver at-least-once (possible duplicates). For idempotency: (1) Include a unique message ID in the body, (2) Check if already processed before processing (using DynamoDB conditional writes), (3) Make operations idempotent (e.g., "set balance to X" not "add X to balance"). Or use FIFO queues which guarantee exactly-once.
