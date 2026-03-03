# RDS — Relational Database Service

> Managed relational databases. Focus on your application, not on patching, backing up, or managing database servers.

---

## Real-World Analogy

RDS is like hiring a **professional filing cabinet company** vs managing your own:
- **Self-managed DB (EC2):** You buy the cabinet, organize files, handle lock & key, repair when it breaks, create copies yourself
- **RDS:** The company gives you a cabinet. They handle maintenance, backups, security, disaster recovery — you just say "store this" and "find that"
- **Multi-AZ:** They keep an exact copy in a second building. If the first building burns down, you seamlessly switch to the second
- **Read Replicas:** They create read-only copies in libraries around the world so customers can read faster

---

## Supported Engines

| Engine | Description | Use Case |
|--------|-------------|----------|
| **Aurora** (MySQL/PostgreSQL) | AWS-built, 5x faster than MySQL | Primary choice for new apps |
| **PostgreSQL** | Advanced open-source | Complex queries, geospatial, JSON |
| **MySQL** | Most popular open-source | Web apps, WordPress, legacy |
| **MariaDB** | MySQL fork | MySQL alternative with extras |
| **Oracle** | Enterprise commercial | Legacy enterprise apps |
| **SQL Server** | Microsoft commercial | .NET applications |

---

## Key Features

| Feature | Description | Real-World Example |
|---------|-------------|-------------------|
| **Multi-AZ** | Synchronous standby replica for HA | Primary in AZ-1a, standby in AZ-1b. Failover in 60 seconds |
| **Read Replicas** | Async replicas for read scaling | 5 replicas handle reporting queries, primary handles writes only |
| **Automated Backups** | Daily snapshots + transaction logs | Restore to any second in the last 35 days |
| **Encryption** | At rest (KMS) and in transit (SSL) | HIPAA/PCI compliance requirement |
| **RDS Proxy** | Connection pooling | Lambda creates 1000 connections → Proxy multiplexes to 50 DB connections |
| **IAM Authentication** | Token-based auth | No passwords in code — Lambda uses IAM role to authenticate |
| **Performance Insights** | Visual DB performance monitoring | "Which query is consuming 80% of CPU?" — find and optimize it |
| **Blue/Green Deployments** | Zero-downtime version upgrades | Upgrade from PostgreSQL 14 → 16 with instant switchover |
| **RDS Custom** | OS-level access for Oracle/SQL Server | Install custom plugins, configure OS parameters |

---

## Multi-AZ vs Read Replicas — Deep Comparison

| Aspect | Multi-AZ | Read Replicas |
|--------|----------|---------------|
| **Purpose** | High availability (failover) | Read scaling (performance) |
| **Replication** | Synchronous (zero data loss) | Asynchronous (slight lag) |
| **Failover** | Automatic (60 sec) | Manual promotion |
| **Read traffic** | No (standby is idle) | Yes (offload reads) |
| **Cross-region** | No (same region, different AZ) | Yes (global read scaling) |
| **Endpoint** | Same endpoint after failover | Separate read endpoint |
| **Cost** | 2x primary cost | Per replica (same as primary) |
| **Use case** | Production HA (every prod DB) | Analytics, reporting, read-heavy apps |

---

## Real-Time Example 1: E-Commerce Database Architecture

**Scenario:** Your e-commerce app has 10,000 users. Reads (product browsing) are 90% of traffic, writes (orders) are 10%.

```
                     ┌──────────────────┐
                     │    Application    │
                     └────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
               Writes (10%)       Reads (90%)
                    │                   │
                    ▼                   ▼
            ┌──────────────┐   ┌──────────────┐
            │ RDS Primary   │   │ RDS Read      │ ← 3 read replicas
            │ (Multi-AZ)    │   │ Replicas      │    in different AZs
            │ us-east-1a    │   │ us-east-1a/b/c│
            └──────┬───────┘   └──────────────┘
                   │
            ┌──────┴───────┐
            │ RDS Standby   │ ← Synchronous copy (hidden)
            │ us-east-1b    │    Auto-failover if primary dies
            └──────────────┘
```

**Cost impact:**
- Without Read Replicas: 1 db.r6g.xlarge handling everything = CPU at 85% (overloaded)
- With 3 Read Replicas: Primary at 20% CPU, each replica at 30% CPU = smooth performance
- Replicas cost additional per-instance, but prevent needing a much larger primary

---

## Real-Time Example 2: Disaster Recovery with Cross-Region Replica

**Scenario:** Your company requires RPO < 1 minute and RTO < 5 minutes for regulatory compliance. Primary region: US-East-1, DR region: EU-West-1.

```
Normal operation:
App → RDS Primary (us-east-1) → Async replication → Read Replica (eu-west-1)

Disaster in US-East-1:
1. Promote EU-West-1 replica to standalone primary ← 2-3 minutes
2. Update DNS (Route53 failover) ← seconds
3. Application now writes to EU-West-1 ← total: ~5 minutes
```

```bash
# Create cross-region read replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier eu-dr-replica \
    --source-db-instance-identifier arn:aws:rds:us-east-1:ACCT:db:prod-db \
    --region eu-west-1 \
    --db-instance-class db.r6g.xlarge \
    --storage-encrypted

# During disaster — promote replica to primary
aws rds promote-read-replica \
    --db-instance-identifier eu-dr-replica \
    --region eu-west-1
```

---

## Real-Time Example 3: Lambda + RDS Proxy (Serverless Architecture)

**Scenario:** Your API runs on Lambda (1000 concurrent invocations). Each Lambda creates a database connection. RDS has a max of 100 connections. Without RDS Proxy, you get "Too many connections" errors.

```
Without RDS Proxy:
Lambda (1000 instances) → 1000 DB connections → RDS (max 100) → CRASH! 💥

With RDS Proxy:
Lambda (1000 instances) → RDS Proxy → 50 pooled connections → RDS ✅
                          (multiplexes and reuses connections)
```

```bash
# Create RDS Proxy
aws rds create-db-proxy \
    --db-proxy-name app-proxy \
    --engine-family POSTGRESQL \
    --auth '[{
        "Description": "IAM auth",
        "AuthScheme": "SECRETS",
        "SecretArn": "arn:aws:secretsmanager:us-east-1:ACCT:secret:rds-creds",
        "IAMAuth": "REQUIRED"
    }]' \
    --role-arn arn:aws:iam::ACCT:role/RDSProxyRole \
    --vpc-subnet-ids subnet-1 subnet-2 \
    --vpc-security-group-ids sg-proxy

# Register RDS instance as target
aws rds register-db-proxy-targets \
    --db-proxy-name app-proxy \
    --db-instance-identifiers prod-db
```

---

## Aurora — AWS's High-Performance Database

| Feature | Standard RDS | Aurora |
|---------|-------------|--------|
| **Performance** | Baseline | 5x MySQL, 3x PostgreSQL |
| **Storage** | You provision | Auto-scales up to 128 TB |
| **Replicas** | Up to 5 | Up to 15 (millisecond lag) |
| **Failover** | 60-120 seconds | 30 seconds |
| **Storage replication** | 2 copies (Multi-AZ) | 6 copies across 3 AZs |
| **Serverless** | No | Aurora Serverless v2 (auto-scales) |
| **Global Database** | Cross-region replica | < 1 second replication worldwide |

```bash
# Create Aurora Serverless v2 cluster
aws rds create-db-cluster \
    --db-cluster-identifier prod-aurora \
    --engine aurora-postgresql \
    --engine-version 15.4 \
    --master-username admin \
    --master-user-password SecurePass123! \
    --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=16 \
    --storage-encrypted

# Add Aurora instance
aws rds create-db-instance \
    --db-instance-identifier prod-aurora-instance-1 \
    --db-cluster-identifier prod-aurora \
    --engine aurora-postgresql \
    --db-instance-class db.serverless
```

---

## Labs

### Lab 1: Create Production-Grade RDS
```bash
# Create Multi-AZ PostgreSQL with encryption
aws rds create-db-instance \
    --db-instance-identifier prod-db \
    --db-instance-class db.t3.medium \
    --engine postgres --engine-version 15.4 \
    --master-username admin \
    --master-user-password SecurePass123! \
    --allocated-storage 100 --storage-type gp3 \
    --multi-az --storage-encrypted --kms-key-id alias/rds-key \
    --vpc-security-group-ids sg-db \
    --db-subnet-group-name prod-db-subnets \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --monitoring-interval 60 \
    --enable-performance-insights
```

### Lab 2: Create Read Replica
```bash
# In-region read replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier prod-db-read \
    --source-db-instance-identifier prod-db

# Cross-region read replica (DR)
aws rds create-db-instance-read-replica \
    --db-instance-identifier dr-read-replica \
    --source-db-instance-identifier arn:aws:rds:us-east-1:ACCT:db:prod-db \
    --region eu-west-1
```

### Lab 3: Enable IAM Authentication
```bash
# Enable IAM auth
aws rds modify-db-instance \
    --db-instance-identifier prod-db \
    --enable-iam-database-authentication

# Create database user for IAM
# (run inside PostgreSQL)
# CREATE USER iam_user WITH LOGIN;
# GRANT rds_iam TO iam_user;

# Connect using IAM token
TOKEN=$(aws rds generate-db-auth-token \
    --hostname prod-db.xxxx.us-east-1.rds.amazonaws.com \
    --port 5432 --username iam_user)

psql "host=prod-db.xxxx.us-east-1.rds.amazonaws.com port=5432 user=iam_user password=$TOKEN dbname=myapp sslmode=require"
```

### Lab 4: Blue/Green Deployment for Version Upgrade
```bash
# Create blue/green deployment (zero-downtime upgrade)
aws rds create-blue-green-deployment \
    --blue-green-deployment-name pg14-to-pg16 \
    --source arn:aws:rds:us-east-1:ACCT:db:prod-db \
    --target-engine-version 16.1

# Verify green environment, then switch
aws rds switchover-blue-green-deployment \
    --blue-green-deployment-identifier bgd-xxxx
```

---

## Interview Questions

1. **Multi-AZ vs Read Replicas — what's the difference?**
   > Multi-AZ: high availability with synchronous replication, automatic failover, standby is not readable. Read Replicas: read scaling with async replication, manual promotion, separate endpoints you can read from.

2. **How does RDS automated backup work?**
   > Daily snapshots during backup window + continuous transaction log backup to S3. Point-in-time recovery to any second in the retention period (1-35 days). Snapshots are incremental, stored in S3.

3. **What is RDS Proxy and when to use it?**
   > Connection pooling service. Use with Lambda/serverless where thousands of short-lived connections overwhelm the database. Proxy maintains a pool of long-lived connections to RDS. Also improves failover time by keeping connections warm.

4. **How to encrypt an existing unencrypted RDS instance?**
   > Cannot encrypt directly. Take a snapshot → copy snapshot with encryption → restore to new encrypted instance → update application to use new endpoint → delete old instance. Requires planned downtime.

5. **What is Aurora and how is it different from standard RDS?**
   > AWS-built database engine, 5x faster than MySQL. 6 copies of data across 3 AZs. Auto-scaling storage up to 128 TB. 15 read replicas with ms lag. 30-second failover. Aurora Serverless auto-scales compute. Costs 20% more but significantly better performance.

6. **How do you implement IAM database authentication?**
   > Enable IAM auth on RDS. Create DB user with `rds_iam` role. Application calls `generate-db-auth-token` to get temporary password. No passwords in code or config files. Token auto-rotates every 15 minutes.

7. **What is RDS Blue/Green Deployment?**
   > AWS creates a copy (green) of your database. Apply changes to green (version upgrade, parameter changes). Test green thoroughly. Switchover is near-instant — DNS changes to point to green. Rollback by switching back. Zero downtime upgrades.

8. **How would you handle database migrations in a multi-region architecture?**
   > Use Aurora Global Database (< 1 second cross-region replication) or RDS cross-region read replicas. During migration: promote replica in target region, update Route53 failover records. Use DMS (Database Migration Service) for cross-engine migrations.
