# EventBridge — Serverless Event Bus

> Route events between AWS services, SaaS apps, and custom applications. The backbone of event-driven architecture on AWS.

---

## Real-World Analogy

EventBridge is like an **intelligent post office**:
- **Event Bus** = The post office (receives all mail)
- **Events** = Letters (JSON messages with metadata)
- **Rules** = Sorting rules ("Letters from AWS → DevOps mailbox", "Letters about payments → Finance")
- **Targets** = Mailboxes/recipients (Lambda, SQS, SNS, Step Functions)
- **Schema Registry** = A catalog of all letter formats
- **Archive** = Store a copy of every letter for replay later

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Event Bus** | Channel for events | Default (AWS events), custom, partner |
| **Event** | JSON payload with metadata | `{"source": "aws.ec2", "detail-type": "EC2 Instance State-change"}` |
| **Rule** | Pattern match + target routing | "When EC2 stops → send to SNS" |
| **Target** | Destination for matched events | Lambda, SQS, SNS, Step Functions, API Gateway |
| **Schema Registry** | Auto-discovered event schemas | Know the exact JSON structure of events |
| **Archive** | Store events for replay | Replay last 24 hours of events for debugging |
| **Pipe** | Point-to-point integration | SQS → transform → Lambda (no rule needed) |

---

## Real-Time Example 1: Automated Security Response

**Scenario:** Detect security events and auto-respond: unauthorized root login → lock account; security group opened to 0.0.0.0/0 → revert; IAM access key created → alert.

```
┌────────────────────────────────────────────────────────────────┐
│              Security Event Response Architecture              │
│                                                                │
│  CloudTrail ──▶ EventBridge ──▶ Rules                         │
│                                   │                            │
│                    ┌──────────────┼──────────────┐             │
│                    │              │              │             │
│              Root Login     SG Changed    Key Created          │
│                    │              │              │             │
│              ▼              ▼              ▼                   │
│         Lock Account   Revert SG     Alert Team               │
│         (Lambda)       (Lambda)      (SNS)                    │
│              │              │              │                   │
│              └──────────────┼──────────────┘                  │
│                             ▼                                  │
│                       Audit Log (S3)                           │
└────────────────────────────────────────────────────────────────┘
```

```bash
# Rule 1: Root console login → alert + lock
aws events put-rule --name "root-login-alert" \
    --event-pattern '{
        "source": ["aws.signin"],
        "detail-type": ["AWS Console Sign In via CloudTrail"],
        "detail": {
            "userIdentity": {"type": ["Root"]}
        }
    }'

aws events put-targets --rule "root-login-alert" \
    --targets '[
        {"Id": "sns-alert", "Arn": "arn:aws:sns:us-east-1:ACCT:security-alerts"},
        {"Id": "lambda-lock", "Arn": "arn:aws:lambda:us-east-1:ACCT:function:lock-root-account"}
    ]'

# Rule 2: Security group made public → auto-revert
aws events put-rule --name "sg-public-revert" \
    --event-pattern '{
        "source": ["aws.ec2"],
        "detail-type": ["AWS API Call via CloudTrail"],
        "detail": {
            "eventName": ["AuthorizeSecurityGroupIngress"],
            "requestParameters": {
                "ipPermissions": {
                    "items": {
                        "ipRanges": {
                            "items": {
                                "cidrIp": ["0.0.0.0/0"]
                            }
                        }
                    }
                }
            }
        }
    }'

aws events put-targets --rule "sg-public-revert" \
    --targets '[{"Id": "revert-sg", "Arn": "arn:aws:lambda:us-east-1:ACCT:function:revert-public-sg"}]'

# Rule 3: Any IAM access key creation → alert
aws events put-rule --name "iam-key-created" \
    --event-pattern '{
        "source": ["aws.iam"],
        "detail-type": ["AWS API Call via CloudTrail"],
        "detail": {"eventName": ["CreateAccessKey"]}
    }'

aws events put-targets --rule "iam-key-created" \
    --targets '[{"Id": "alert", "Arn": "arn:aws:sns:us-east-1:ACCT:security-alerts"}]'
```

---

## Real-Time Example 2: Scheduled Automation (Cron Jobs)

**Scenario:** Replace traditional cron jobs with serverless scheduled events.

```bash
# Daily: Clean up old EBS snapshots
aws events put-rule --name "daily-snapshot-cleanup" \
    --schedule-expression "cron(0 2 * * ? *)" \
    --description "Daily cleanup at 2 AM UTC"

aws events put-targets --rule "daily-snapshot-cleanup" \
    --targets '[{"Id": "cleanup", "Arn": "arn:aws:lambda:us-east-1:ACCT:function:cleanup-snapshots"}]'

# Every 5 minutes: Health check
aws events put-rule --name "health-check" \
    --schedule-expression "rate(5 minutes)"

aws events put-targets --rule "health-check" \
    --targets '[{"Id": "check", "Arn": "arn:aws:lambda:us-east-1:ACCT:function:health-monitor"}]'

# Monthly: Generate cost report
aws events put-rule --name "monthly-cost-report" \
    --schedule-expression "cron(0 8 1 * ? *)" \
    --description "First of month, 8 AM UTC"
```

---

## Real-Time Example 3: Event-Driven Microservices

**Scenario:** E-commerce platform where services communicate via events (loose coupling).

```
Order Service publishes "OrderPlaced" event:
                              │
                    EventBridge (custom bus)
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      Payment Service   Inventory Service  Email Service
      "Process payment"  "Reserve stock"   "Send confirmation"
              │               │               │
              ▼               ▼               ▼
      "PaymentCompleted"  "StockReserved"  "EmailSent"
```

```bash
# Create custom event bus
aws events create-event-bus --name ecommerce-bus

# Publish custom event
aws events put-events --entries '[{
    "Source": "ecommerce.orders",
    "DetailType": "OrderPlaced",
    "Detail": "{\"orderId\": \"ORD-001\", \"userId\": \"U-123\", \"total\": 99.99}",
    "EventBusName": "ecommerce-bus"
}]'

# Route OrderPlaced to multiple targets
aws events put-rule --name "order-placed" \
    --event-bus-name ecommerce-bus \
    --event-pattern '{
        "source": ["ecommerce.orders"],
        "detail-type": ["OrderPlaced"]
    }'

aws events put-targets --rule "order-placed" \
    --event-bus-name ecommerce-bus \
    --targets '[
        {"Id": "payment", "Arn": "arn:aws:sqs:us-east-1:ACCT:payment-queue"},
        {"Id": "inventory", "Arn": "arn:aws:sqs:us-east-1:ACCT:inventory-queue"},
        {"Id": "email", "Arn": "arn:aws:lambda:us-east-1:ACCT:function:send-order-email"}
    ]'
```

---

## EventBridge vs SNS vs SQS

| Feature | EventBridge | SNS | SQS |
|---------|------------|-----|-----|
| **Pattern** | Event router | Fan-out | Queue |
| **Filtering** | Rich content-based | Attribute-based | None |
| **Sources** | AWS, SaaS, custom | Custom only | Custom only |
| **Archive/Replay** | Yes | No | No (DLQ only) |
| **Schema** | Auto-discovery | No | No |
| **Scheduling** | Yes (cron/rate) | No | No (delay only) |
| **Best for** | Event-driven architecture | Simple notifications | Work queues |

---

## Labs

### Lab 1: EC2 State Change Alerts
```bash
aws events put-rule --name "ec2-state-change" \
    --event-pattern '{"source": ["aws.ec2"], "detail-type": ["EC2 Instance State-change Notification"]}'

aws events put-targets --rule "ec2-state-change" \
    --targets '[{"Id": "notify", "Arn": "arn:aws:sns:us-east-1:ACCT:ops-alerts"}]'
```

### Lab 2: Archive and Replay Events
```bash
# Create archive
aws events create-archive --archive-name "order-events-archive" \
    --event-source-arn arn:aws:events:us-east-1:ACCT:event-bus/ecommerce-bus \
    --event-pattern '{"source": ["ecommerce.orders"]}' \
    --retention-days 90

# Replay events (useful for debugging or reprocessing)
aws events start-replay --replay-name "replay-jan15" \
    --event-source-arn arn:aws:events:us-east-1:ACCT:event-bus/ecommerce-bus \
    --destination '{"Arn": "arn:aws:events:us-east-1:ACCT:event-bus/ecommerce-bus"}' \
    --event-start-time 2026-01-15T00:00:00Z \
    --event-end-time 2026-01-15T23:59:59Z
```

---

## Interview Questions

1. **What is EventBridge and when to use it?**
   > EventBridge is a serverless event bus for routing events between AWS services, SaaS apps, and custom code. Use when: building event-driven architecture, reacting to AWS service events (EC2 stopped, S3 uploaded), replacing cron jobs, integrating with SaaS (Stripe, Zendesk, Auth0), or decoupling microservices.

2. **EventBridge vs SNS — what's the difference?**
   > EventBridge: rich content-based filtering (match on any JSON field), receives native AWS events, supports schema registry & event replay, can route to 5 targets per rule. SNS: simple attribute filtering, fan-out to many subscribers, supports SMS/email/HTTP. Use EventBridge for complex routing, SNS for simple notifications.

3. **How does event pattern matching work?**
   > JSON-based pattern matching on event fields. Supports: exact match, prefix, numeric ranges, exists/not-exists, anything-but. Example: `{"source": ["aws.ec2"], "detail": {"state": ["stopped", "terminated"]}}`. Only events matching ALL specified fields trigger the rule.

4. **What is the archive and replay feature?**
   > Archive stores events for N days. Replay re-sends archived events to the same or different bus. Use for: debugging (replay yesterday's events against new code), disaster recovery (replay events after fixing a bug), testing (replay production events in dev).

5. **How to use EventBridge for cross-account events?**
   > Account A creates a rule sending events to Account B's event bus. Account B must have a resource policy allowing Account A. Or use AWS Organizations to share events across all accounts. Common pattern: central security account receives events from all accounts.

6. **What are EventBridge Pipes?**
   > Point-to-point integrations: source → optional filter → optional enrichment → target. Simpler than rules for 1:1 integrations. Sources: SQS, DynamoDB Streams, Kinesis, Kafka. Example: DynamoDB Stream → filter for inserts → enrich with API call → send to Step Functions.
