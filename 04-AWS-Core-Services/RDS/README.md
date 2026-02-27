# RDS — Relational Database Service

> Managed relational databases. Focus on architecture, not server maintenance.

## Supported Engines
MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, **Aurora** (MySQL/PostgreSQL compatible)

## Key Features
| Feature | Description |
|---------|------------|
| **Multi-AZ** | Synchronous standby replica for HA (automatic failover) |
| **Read Replicas** | Async replicas for read scaling (up to 15 for Aurora) |
| **Automated Backups** | Daily snapshots + transaction logs (point-in-time recovery) |
| **Encryption** | At rest (KMS) and in transit (SSL/TLS) |
| **RDS Proxy** | Connection pooling for Lambda/serverless |
| **IAM Authentication** | Token-based auth (no password in code) |
| **Performance Insights** | Database performance monitoring |

## Multi-AZ vs Read Replicas
| | Multi-AZ | Read Replicas |
|---|---------|---------------|
| Purpose | High availability | Read scaling |
| Replication | Synchronous | Asynchronous |
| Failover | Automatic | Manual promotion |
| Cross-region | No | Yes |
| Read traffic | No (standby only) | Yes |

## Labs
```bash
# Create RDS PostgreSQL with Multi-AZ
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
    --preferred-backup-window "03:00-04:00"

# Create read replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier prod-db-read \
    --source-db-instance-identifier prod-db

# Enable IAM authentication
aws rds modify-db-instance \
    --db-instance-identifier prod-db \
    --enable-iam-database-authentication
```

## Interview Questions
1. Multi-AZ vs Read Replicas — differences?
2. How does RDS automated backup work?
3. What is RDS Proxy and when to use it?
4. How to encrypt an existing unencrypted RDS instance?
5. What is Aurora and how is it different from standard RDS?
6. How to implement IAM database authentication?
