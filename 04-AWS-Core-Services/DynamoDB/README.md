# DynamoDB — Fully Managed NoSQL Database

> Single-digit millisecond latency at any scale. Serverless, auto-scaling, fully managed key-value and document database.

---

## Real-World Analogy

DynamoDB is like a **super-fast library card catalog**:
- **Table** = The catalog cabinet
- **Partition Key** = The drawer label (e.g., author name) — determines which drawer to look in
- **Sort Key** = The card position within the drawer (e.g., publication date) — allows range queries
- **Item** = Individual card (up to 400KB)
- **GSI** = A second catalog organized differently (e.g., by genre instead of author)
- **DynamoDB Streams** = A librarian who notifies you whenever a card is added/changed

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Partition Key (PK)** | Primary key — determines partition | `userId: "U-123"` |
| **Sort Key (SK)** | Optional — enables range queries | `orderDate: "2026-01-15"` |
| **Item** | A record (max 400KB) | `{userId, name, email, orders}` |
| **GSI** | Global Secondary Index — query on different key | Query by email instead of userId |
| **LSI** | Local Secondary Index — same PK, different SK | Same user, sort by product instead of date |
| **Streams** | Ordered log of item changes | Trigger Lambda on every change |
| **TTL** | Auto-delete items after expiry time | Session data expires after 24 hours |
| **DAX** | In-memory cache for DynamoDB | Microsecond latency (10x faster) |

## Capacity Modes

| Mode | How It Works | Cost | Best For |
|------|-------------|------|----------|
| **On-Demand** | Pay per request, auto-scales | ~$1.25 per million writes | Unpredictable traffic, new apps |
| **Provisioned** | Set Read/Write Capacity Units | ~$0.65 per million writes | Predictable traffic, cost optimization |
| **Provisioned + Auto-Scaling** | Set min/max, auto-adjusts | Same as provisioned | Steady with occasional spikes |

---

## Real-Time Example 1: E-Commerce Product Catalog

**Scenario:** Build a product catalog that handles 50,000 reads/sec during flash sales with <5ms latency.

```
Table: Products
┌──────────────┬──────────────┬───────────┬────────┬──────────┐
│ PK: category │ SK: productId│   name    │ price  │  stock   │
├──────────────┼──────────────┼───────────┼────────┼──────────┤
│ electronics  │ PROD-001     │ Laptop X  │ 999.00 │ 150      │
│ electronics  │ PROD-002     │ Phone Y   │ 699.00 │ 500      │
│ clothing     │ PROD-100     │ T-Shirt   │ 29.99  │ 10000    │
│ clothing     │ PROD-101     │ Jeans     │ 59.99  │ 5000     │
└──────────────┴──────────────┴───────────┴────────┴──────────┘

GSI: ProductsByPrice
PK: category, SK: price → "Show all electronics sorted by price"

GSI: ProductsByName  
PK: firstLetter, SK: name → "Search products starting with 'Lap'"

Access Patterns:
1. Get product by ID → GetItem(PK=category, SK=productId) → <5ms
2. List products in category → Query(PK=electronics) → <10ms
3. Price range in category → Query(PK=electronics, SK between 100-500)
4. Update stock (atomic) → UpdateItem with SET stock = stock - 1
```

```bash
# Create table
aws dynamodb create-table \
    --table-name Products \
    --attribute-definitions \
        AttributeName=category,AttributeType=S \
        AttributeName=productId,AttributeType=S \
        AttributeName=price,AttributeType=N \
    --key-schema \
        AttributeName=category,KeyType=HASH \
        AttributeName=productId,KeyType=RANGE \
    --global-secondary-indexes '[{
        "IndexName": "ProductsByPrice",
        "KeySchema": [
            {"AttributeName": "category", "KeyType": "HASH"},
            {"AttributeName": "price", "KeyType": "RANGE"}
        ],
        "Projection": {"ProjectionType": "ALL"}
    }]' \
    --billing-mode PAY_PER_REQUEST

# Put item
aws dynamodb put-item --table-name Products --item '{
    "category": {"S": "electronics"},
    "productId": {"S": "PROD-001"},
    "name": {"S": "Laptop Pro X"},
    "price": {"N": "999.00"},
    "stock": {"N": "150"},
    "rating": {"N": "4.8"}
}'

# Atomic stock decrement (prevents overselling)
aws dynamodb update-item --table-name Products \
    --key '{"category": {"S": "electronics"}, "productId": {"S": "PROD-001"}}' \
    --update-expression "SET stock = stock - :qty" \
    --condition-expression "stock >= :qty" \
    --expression-attribute-values '{":qty": {"N": "1"}}' \
    --return-values UPDATED_NEW
```

---

## Real-Time Example 2: User Session Store with TTL

**Scenario:** Store user sessions for a web application. Sessions should auto-expire after 24 hours without manual cleanup.

```bash
# Create sessions table with TTL
aws dynamodb create-table \
    --table-name UserSessions \
    --attribute-definitions AttributeName=sessionId,AttributeType=S \
    --key-schema AttributeName=sessionId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# Enable TTL on 'expiresAt' attribute
aws dynamodb update-time-to-live --table-name UserSessions \
    --time-to-live-specification Enabled=true,AttributeName=expiresAt

# Store session (expires in 24 hours)
EXPIRES=$(date -d '+24 hours' +%s)
aws dynamodb put-item --table-name UserSessions --item "{
    \"sessionId\": {\"S\": \"sess-abc-123\"},
    \"userId\": {\"S\": \"U-456\"},
    \"loginTime\": {\"S\": \"2026-01-15T10:00:00Z\"},
    \"ipAddress\": {\"S\": \"192.168.1.100\"},
    \"expiresAt\": {\"N\": \"$EXPIRES\"}
}"

# DynamoDB automatically deletes items when expiresAt < current time
# No cron jobs, no cleanup scripts needed!
```

---

## Real-Time Example 3: Real-Time Leaderboard with DynamoDB Streams

**Scenario:** Gaming platform needs a real-time leaderboard. When a player's score changes, the global rankings update instantly.

```
┌───────────────┐     ┌──────────────┐     ┌───────────────┐
│  Game Server  │────▶│  DynamoDB    │────▶│  DynamoDB     │
│  (update      │     │  (Scores     │     │  Stream       │
│   score)      │     │   table)     │     │  (captures    │
└───────────────┘     └──────────────┘     │   changes)    │
                                            └───────┬───────┘
                                                    │
                                            ┌───────▼───────┐
                                            │  Lambda       │
                                            │  (Aggregate   │
                                            │   rankings)   │
                                            └───────┬───────┘
                                                    │
                                            ┌───────▼───────┐
                                            │  Leaderboard  │
                                            │  Table (Top   │
                                            │   100 cached) │
                                            └───────────────┘
```

```bash
# Enable DynamoDB Streams
aws dynamodb update-table --table-name PlayerScores \
    --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES

# Create Lambda trigger on stream
aws lambda create-event-source-mapping \
    --function-name update-leaderboard \
    --event-source-arn arn:aws:dynamodb:us-east-1:ACCT:table/PlayerScores/stream/xxx \
    --starting-position LATEST \
    --batch-size 100
```

---

## DynamoDB vs RDS Comparison

| Feature | DynamoDB | RDS (PostgreSQL/MySQL) |
|---------|----------|----------------------|
| **Type** | NoSQL (key-value/document) | Relational (SQL) |
| **Schema** | Flexible (schemaless) | Fixed schema |
| **Latency** | Single-digit ms at any scale | Depends on query complexity |
| **Scaling** | Automatic, horizontal | Vertical (bigger instance) |
| **Joins** | Not supported | Full SQL joins |
| **Transactions** | Limited (25 items max) | Full ACID |
| **Cost at scale** | Can be expensive at high volume | More predictable |
| **Best for** | Session store, gaming, IoT | Complex queries, reporting |

---

## Labs

### Lab 1: CRUD Operations
```bash
# Create, Read, Update, Delete
aws dynamodb put-item --table-name Products --item '{"category":{"S":"books"},"productId":{"S":"B-001"},"title":{"S":"DevOps Handbook"}}'
aws dynamodb get-item --table-name Products --key '{"category":{"S":"books"},"productId":{"S":"B-001"}}'
aws dynamodb update-item --table-name Products --key '{"category":{"S":"books"},"productId":{"S":"B-001"}}' --update-expression "SET price = :p" --expression-attribute-values '{":p":{"N":"45.00"}}'
aws dynamodb delete-item --table-name Products --key '{"category":{"S":"books"},"productId":{"S":"B-001"}}'
```

### Lab 2: Query vs Scan
```bash
# Query (efficient — uses key, reads specific partition)
aws dynamodb query --table-name Products \
    --key-condition-expression "category = :cat" \
    --expression-attribute-values '{":cat": {"S": "electronics"}}'

# Scan (expensive — reads entire table, avoid in production!)
aws dynamodb scan --table-name Products \
    --filter-expression "price > :p" \
    --expression-attribute-values '{":p": {"N": "500"}}'
```

### Lab 3: Backup and Restore
```bash
# On-demand backup
aws dynamodb create-backup --table-name Products --backup-name prod-backup-$(date +%Y%m%d)

# Enable Point-in-Time Recovery (PITR)
aws dynamodb update-continuous-backups --table-name Products \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

# Restore to any point in last 35 days
aws dynamodb restore-table-to-point-in-time \
    --source-table-name Products \
    --target-table-name Products-Restored \
    --restore-date-time 2026-01-14T10:00:00Z
```

---

## Interview Questions

1. **When would you choose DynamoDB over RDS?**
   > DynamoDB for: consistent single-digit ms latency at any scale, simple key-value access patterns, session stores, gaming leaderboards, IoT sensor data, shopping carts. RDS for: complex queries with joins, reporting/analytics, ACID transactions across many tables, when you need SQL.

2. **What is a partition key and how does it affect performance?**
   > The partition key determines which physical partition stores the item. A good partition key has high cardinality (many unique values) and distributes evenly. Bad key example: `country` (most items in "US" = hot partition). Good key: `userId` (millions of unique values = even distribution).

3. **What are Global Secondary Indexes (GSI)?**
   > GSIs create a copy of your table with a different key schema. You can query the GSI instead of scanning the table. Example: main table PK=userId, GSI PK=email — now you can query by email efficiently. GSIs have their own capacity and can project all or some attributes. Max 20 GSIs per table.

4. **How does DynamoDB handle scaling?**
   > On-demand mode: auto-scales instantly to any traffic level, pay per request. Provisioned mode: you set RCU/WCU, use auto-scaling to adjust within min/max. DynamoDB partitions data across multiple servers automatically. Each partition handles 3,000 RCU + 1,000 WCU. More data/traffic = more partitions (transparent).

5. **What are DynamoDB Streams and use cases?**
   > Ordered log of every item change (insert/update/delete). Retained for 24 hours. Trigger Lambda for: replication to another table, aggregations (materialized views), sending notifications, syncing to Elasticsearch/OpenSearch. Stream records contain old and/or new item images based on configuration.

6. **What is DynamoDB TTL?**
   > Time-To-Live: auto-deletes items when a specified timestamp attribute passes. Free — no extra cost. Use for: session expiry, temporary data cleanup, log rotation. Items are typically deleted within 48 hours of expiry. Deleted items still appear in Streams (useful for cleanup triggers).

7. **How do DynamoDB transactions work?**
   > `TransactWriteItems` and `TransactGetItems` provide ACID across up to 100 items and 25 unique items. Example: transfer money — debit account A AND credit account B atomically. If either fails, both roll back. Cost: 2x the normal capacity units. Use sparingly.

8. **How to design a one-to-many relationship in DynamoDB?**
   > Use composite key: PK = parent entity, SK = child entity. Example: PK=`USER#123`, SK=`ORDER#001`, SK=`ORDER#002`. Query PK=`USER#123` gets the user AND all their orders. This is the "single table design" pattern — store multiple entity types in one table for efficient queries.
