# Redshift — Cloud Data Warehousing

> Petabyte-scale data warehouse. Columnar storage with massively parallel processing (MPP). Run complex analytics queries across billions of rows in seconds.

---

## Real-World Analogy

Redshift is like a **massive library with a brilliant research team**:
- Regular database (RDS) = a bookshelf you search one book at a time
- Redshift = a research team that splits the library into sections, each person searches their section simultaneously (MPP)
- Columnar storage = instead of reading entire books, you only read the chapters (columns) you need
- Result: what takes RDS minutes takes Redshift seconds

---

## Redshift vs RDS vs DynamoDB

| Feature | Redshift | RDS | DynamoDB |
|---------|----------|-----|----------|
| **Type** | Data warehouse (OLAP) | Relational DB (OLTP) | NoSQL (key-value) |
| **Best for** | Analytics, BI, reporting | Transactions, CRUD | High throughput, low latency |
| **Data size** | Petabytes | Terabytes | Unlimited (item-level) |
| **Query type** | Complex aggregations, joins | Simple CRUD, joins | Key lookups, scans |
| **Latency** | Seconds (complex queries) | Milliseconds | Single-digit milliseconds |
| **Storage** | Columnar (compressed) | Row-based | Document / key-value |
| **Scaling** | Add nodes (resize cluster) | Vertical (instance size) | Auto (on-demand) |
| **Cost model** | Per node-hour | Per instance-hour | Per request + storage |
| **SQL** | PostgreSQL-compatible | MySQL/PostgreSQL/etc. | PartiQL (limited SQL) |

---

## Key Concepts

### Architecture
```
                     ┌─────────────────────────────────────┐
                     │         Redshift Cluster             │
                     │                                      │
  SQL Client ───────▶│  ┌──────────┐    ┌──────────────┐   │
  (BI Tool /         │  │  Leader   │───▶│ Compute Node │   │
   Application)      │  │   Node    │    │   (Slice 1)  │   │
                     │  │           │    │   (Slice 2)  │   │
                     │  │ (Parses,  │    ├──────────────┤   │
                     │  │  plans,   │    │ Compute Node │   │
                     │  │  coords)  │    │   (Slice 3)  │   │
                     │  └──────────┘    │   (Slice 4)  │   │
                     │                   └──────────────┘   │
                     └─────────────────────────────────────┘
```

### Node Types

| Node Type | Description | Use Case |
|-----------|-------------|----------|
| **RA3 (Managed Storage)** | Compute & storage scale independently, data on S3 | Recommended for most workloads |
| **DC2 (Dense Compute)** | SSD-based, fixed local storage | <1 TB, lowest latency |
| **DS2 (Dense Storage)** | HDD-based, large local storage | Legacy (use RA3 instead) |

### Key Features

| Feature | Description |
|---------|-------------|
| **Columnar Storage** | Stores data by column, not row — reads only needed columns |
| **Compression** | Automatic column encoding reduces storage by 3-4x |
| **Distribution Styles** | KEY, EVEN, ALL, AUTO — controls how data spreads across nodes |
| **Sort Keys** | Compound or Interleaved — speeds up range-filtered queries |
| **Materialized Views** | Pre-computed query results for faster dashboards |
| **Concurrency Scaling** | Auto-adds clusters for burst read queries |
| **Redshift Spectrum** | Query S3 data directly without loading into Redshift |
| **Redshift Serverless** | No cluster management, pay per query |
| **Workload Management (WLM)** | Queue and prioritize queries by user/group |
| **Federated Query** | Query RDS/Aurora directly from Redshift |

---

## Distribution Styles

```
KEY Distribution:    Rows with same key → same node (good for JOIN columns)
EVEN Distribution:   Round-robin across nodes (default, balanced load)
ALL Distribution:    Full copy on every node (for small dimension tables)
AUTO Distribution:   Redshift picks based on table size

Choosing correctly is CRITICAL for JOIN performance:
┌────────────────────────────────────────────────┐
│  orders (DIST KEY: customer_id)                │
│  customers (DIST KEY: customer_id)             │
│                                                │
│  Node 1: customer 1-1000 orders + customers    │
│  Node 2: customer 1001-2000 orders + customers │
│  Node 3: customer 2001-3000 orders + customers │
│                                                │
│  JOIN happens LOCAL on each node = FAST        │
└────────────────────────────────────────────────┘
```

---

## Real-Time Example 1: E-Commerce Analytics Platform

**Scenario:** You have 500 million order records across 3 years. Business needs daily dashboards showing revenue by product, region, and time period with sub-10-second response.

```sql
-- Create optimized fact table
CREATE TABLE orders (
    order_id        BIGINT          IDENTITY(1,1),
    customer_id     INTEGER         NOT NULL,
    product_id      INTEGER         NOT NULL,
    order_date      DATE            NOT NULL SORTKEY,
    region          VARCHAR(50)     ENCODE zstd,
    quantity        INTEGER         ENCODE az64,
    unit_price      DECIMAL(10,2)   ENCODE az64,
    total_amount    DECIMAL(12,2)   ENCODE az64
)
DISTSTYLE KEY
DISTKEY (customer_id);

-- Create small dimension table (ALL distribution)
CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    VARCHAR(200),
    category        VARCHAR(100),
    brand           VARCHAR(100)
)
DISTSTYLE ALL;  -- Copied to every node for fast JOINs

-- Fast analytics query (runs in seconds on 500M rows)
SELECT 
    p.category,
    DATE_TRUNC('month', o.order_date) AS month,
    o.region,
    SUM(o.total_amount) AS revenue,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_date >= '2025-01-01'
GROUP BY 1, 2, 3
ORDER BY revenue DESC;
```

```bash
# Create Redshift Serverless workgroup
aws redshift-serverless create-namespace \
    --namespace-name analytics-ns \
    --admin-username admin \
    --admin-user-password 'SecureP@ss123!' \
    --db-name analytics

aws redshift-serverless create-workgroup \
    --workgroup-name analytics-wg \
    --namespace-name analytics-ns \
    --base-capacity 32
```

---

## Real-Time Example 2: S3 Data Lake Querying with Spectrum

**Scenario:** You have 10 TB of historical log data in S3 (Parquet format). Query it directly from Redshift without loading.

```sql
-- Create external schema pointing to AWS Glue Data Catalog
CREATE EXTERNAL SCHEMA spectrum_logs
FROM DATA CATALOG
DATABASE 'logs_db'
IAM_ROLE 'arn:aws:iam::ACCT:role/RedshiftSpectrumRole'
CREATE EXTERNAL DATABASE IF NOT EXISTS;

-- Create external table on S3 data
CREATE EXTERNAL TABLE spectrum_logs.app_logs (
    timestamp    TIMESTAMP,
    user_id      BIGINT,
    action       VARCHAR(100),
    status_code  INTEGER,
    response_ms  INTEGER,
    ip_address   VARCHAR(45)
)
STORED AS PARQUET
LOCATION 's3://my-data-lake/logs/year=2025/';

-- Query S3 data directly (no ETL needed!)
SELECT 
    DATE_TRUNC('hour', timestamp) AS hour,
    action,
    COUNT(*) AS request_count,
    AVG(response_ms) AS avg_response_ms,
    SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS errors
FROM spectrum_logs.app_logs
WHERE timestamp >= '2025-12-01'
GROUP BY 1, 2
ORDER BY request_count DESC;

-- JOIN S3 data with Redshift local tables
SELECT c.customer_name, COUNT(*) AS actions
FROM spectrum_logs.app_logs l
JOIN customers c ON l.user_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 100;
```

---

## Real-Time Example 3: ETL Pipeline with COPY Command

**Scenario:** Load daily sales CSVs from S3 into Redshift, transform, and populate dashboards.

```bash
# Upload daily CSV to S3
aws s3 cp daily-sales-2025-12-01.csv s3://etl-bucket/raw/sales/

# Inside Redshift:
```

```sql
-- Stage raw data
COPY staging_sales
FROM 's3://etl-bucket/raw/sales/daily-sales-2025-12-01.csv'
IAM_ROLE 'arn:aws:iam::ACCT:role/RedshiftLoadRole'
CSV
IGNOREHEADER 1
TIMEFORMAT 'auto'
COMPUPDATE ON;

-- Transform and insert (upsert pattern)
BEGIN TRANSACTION;

DELETE FROM sales_fact
USING staging_sales
WHERE sales_fact.order_id = staging_sales.order_id;

INSERT INTO sales_fact
SELECT * FROM staging_sales;

END TRANSACTION;

-- Analyze and vacuum for performance
ANALYZE sales_fact;
VACUUM sales_fact;

-- Check load errors
SELECT * FROM stl_load_errors ORDER BY starttime DESC LIMIT 10;
```

---

## Labs

### Lab 1: Create Redshift Serverless & Run Queries
```bash
# Create namespace
aws redshift-serverless create-namespace \
    --namespace-name lab-ns \
    --admin-username admin \
    --admin-user-password 'LabP@ss2025!' \
    --db-name labdb

# Create workgroup
aws redshift-serverless create-workgroup \
    --workgroup-name lab-wg \
    --namespace-name lab-ns \
    --base-capacity 8 \
    --publicly-accessible

# Connect using psql or Query Editor v2
# psql -h lab-wg.xxxx.us-east-1.redshift-serverless.amazonaws.com -U admin -d labdb -p 5439

# Create sample table and run analytics queries
# Test columnar performance vs row-based queries
```

### Lab 2: Load Data from S3 with COPY
```bash
# Create sample data
cat << 'EOF' > sample-orders.csv
order_id,customer_id,product,quantity,amount,order_date
1,101,Widget-A,5,49.95,2025-01-15
2,102,Widget-B,2,29.98,2025-01-15
3,101,Widget-C,1,99.99,2025-01-16
EOF

# Upload to S3
aws s3 cp sample-orders.csv s3://your-bucket/redshift-lab/

# In Redshift: Use COPY command
# Test different distribution styles and compare query performance
# Monitor queries in STL_QUERY and STL_QUERY_METRICS
```

### Lab 3: Query S3 Data with Spectrum
```bash
# Create IAM role for Spectrum
# Associate role with Redshift
# Create external schema and tables
# Query Parquet/CSV data on S3 without loading
# Join external tables with local Redshift tables
# Compare performance: Spectrum vs loaded data
```

---

## Interview Questions

1. **When would you choose Redshift over RDS?**
   → OLAP workloads: large-scale analytics, reporting, BI dashboards on billions of rows. RDS is for OLTP (transactions). Redshift uses columnar storage + MPP for analytical query performance.

2. **Explain distribution styles and when to use each.**
   → KEY: co-locate join columns. EVEN: default balanced. ALL: small dimension tables. AUTO: let Redshift decide. Wrong choice → expensive data shuffling during JOINs.

3. **What is Redshift Spectrum?**
   → Query data directly in S3 without loading into Redshift. Uses external tables via Glue Data Catalog. Great for infrequently queried historical data.

4. **How does Redshift achieve fast query performance?**
   → Columnar storage (read only needed columns), compression (3-4x reduction), MPP (parallel across nodes), sort keys (skip blocks), zone maps, compiled code, result caching.

5. **Redshift Serverless vs Provisioned — when to use which?**
   → Serverless: variable/unpredictable workloads, no cluster management. Provisioned: steady-state workloads, need fine-grained tuning, cost predictability.

6. **How do you optimize COPY command performance?**
   → Split files to match slice count, use compressed formats (Parquet, gzip), use manifest files, match column order, use appropriate data types.

7. **What is concurrency scaling?**
   → Automatically provisions additional cluster capacity during read spikes. Up to 10 additional clusters. First hour/day free, then per-second billing.

8. **How do you handle slowly changing dimensions in Redshift?**
   → Type 1 (overwrite), Type 2 (add version rows with effective dates), or use staging table + merge/upsert pattern with BEGIN/END TRANSACTION.
