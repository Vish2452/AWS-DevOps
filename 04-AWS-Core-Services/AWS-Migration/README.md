# AWS Migration — Cloud Migration Services

> Move applications, databases, and data to AWS. Plan, execute, and track migrations at scale. The "moving company" for your cloud journey.

---

## Real-World Analogy

AWS Migration is like **moving to a new city**:
- **Assessment** (Migration Hub) = surveying your current home, making inventory
- **Planning** (6 Rs) = deciding what to move, sell, or buy new
- **Moving** (DMS, SMS, Snowball) = the actual trucks carrying your stuff
- **Setting up** (CloudFormation/Terraform) = arranging furniture in the new home
- **Validation** = checking everything arrived and works

---

## Cloud Adoption Stages

```
Stage 1          Stage 2          Stage 3          Stage 4
PROJECT          FOUNDATION       MIGRATION        REINVENTION
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Run a few │───▶│ Build    │───▶│ Migrate  │───▶│ Innovate │
│ workloads │    │ landing  │    │ at scale │    │ with     │
│ in AWS    │    │ zone &   │    │ (apps,   │    │ cloud-   │
│           │    │ baseline │    │ servers, │    │ native   │
│           │    │ security │    │ data)    │    │ services │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

---

## The 6 Rs of Migration (7 Rs)

| Strategy | Description | When to Use | Example |
|----------|-------------|-------------|---------|
| **Rehost** (Lift & Shift) | Move as-is to EC2 | Quick migration, minimal changes | VM → EC2 instance |
| **Replatform** (Lift & Reshape) | Minor optimizations during move | Easy wins without code changes | MySQL on-prem → RDS MySQL |
| **Repurchase** (Drop & Shop) | Switch to SaaS/managed service | When commercial SaaS is better | On-prem CRM → Salesforce |
| **Refactor** (Re-architect) | Redesign for cloud-native | Performance, scalability needs | Monolith → microservices on EKS |
| **Retire** | Decommission, no longer needed | Redundant or unused apps | Legacy reporting tool |
| **Retain** | Keep on-premises (for now) | Compliance, not ready to move | Mainframe LOB apps |
| **Relocate** | VMware Cloud on AWS | VMware-based environments | vSphere → VMware Cloud on AWS |

```
Migration Decision Tree:
                    ┌─────────────────┐
                    │ Is app needed?  │
                    └───────┬─────────┘
                      Yes   │   No → RETIRE
                    ┌───────▼─────────┐
                    │ Can it be       │
                    │ replaced by SaaS?│
                    └───────┬─────────┘
                      No    │   Yes → REPURCHASE
                    ┌───────▼─────────┐
                    │ Does it need    │
                    │ redesign?       │
                    └───────┬─────────┘
                      No    │   Yes → REFACTOR
                    ┌───────▼─────────┐
                    │ Easy platform   │
                    │ optimizations?  │
                    └───────┬─────────┘
                      No    │   Yes → REPLATFORM
                            │
                         REHOST
```

---

## AWS Migration Services

| Service | Purpose | Source → Target |
|---------|---------|----------------|
| **Migration Hub** | Central dashboard to track all migrations | N/A (tracking) |
| **Application Discovery Service** | Inventory on-prem servers and dependencies | On-prem → inventory |
| **Server Migration Service (MGN)** | Lift-and-shift server migration | On-prem servers → EC2 |
| **Database Migration Service (DMS)** | Migrate databases with minimal downtime | Any DB → RDS/Aurora/DynamoDB |
| **Schema Conversion Tool (SCT)** | Convert DB schema between engines | Oracle → PostgreSQL, etc. |
| **DataSync** | Online data transfer (NFS/SMB → S3/EFS/FSx) | On-prem storage → AWS storage |
| **Snow Family** | Physical data transfer (Snowball/Snowmobile) | On-prem → S3 (physical) |
| **Transfer Family** | SFTP/FTPS/FTP → S3/EFS | File transfer → AWS storage |

---

## AWS Migration Hub

```bash
# Enable Migration Hub
aws migrationhub home-region \
    --home-region us-east-1

# View discovered servers
aws discovery describe-configurations \
    --configuration-ids server-001

# Track migration progress
aws migrationhub notify-migration-task-state \
    --progress-update-stream SMS \
    --migration-task-name "WebServer-001" \
    --task '{"Status":"IN_PROGRESS","StatusDetail":"70% complete"}' \
    --update-date-time 2025-12-01T10:00:00Z
```

---

## Database Migration Service (DMS)

### Architecture
```
Source Database              DMS Replication Instance            Target Database
┌──────────────┐           ┌─────────────────────┐           ┌──────────────┐
│ Oracle       │──────────▶│  DMS                │──────────▶│ Aurora       │
│ On-Premise   │  CDC      │  - Full load        │  writes   │ PostgreSQL   │
│              │  (Change  │  - Ongoing repl     │           │              │
│              │  Data     │  - Schema mapping   │           │              │
│              │  Capture) │                     │           │              │
└──────────────┘           └─────────────────────┘           └──────────────┘
                                                              
Supported:                                                    Supported:
Oracle, SQL Server,                                          RDS (all engines),
PostgreSQL, MySQL,                                           Aurora, Redshift,
MariaDB, MongoDB,                                            DynamoDB, S3,
SAP, DB2, Azure SQL                                          Kinesis, OpenSearch
```

### Migration Types

| Type | Description |
|------|-------------|
| **Full Load** | Copy entire dataset once |
| **Full Load + CDC** | Copy all data, then replicate ongoing changes |
| **CDC Only** | Only replicate changes (source must have existing data in target) |

```bash
# Create replication instance
aws dms create-replication-instance \
    --replication-instance-identifier my-dms \
    --replication-instance-class dms.r5.large \
    --allocated-storage 100 \
    --vpc-security-group-ids sg-dms \
    --replication-subnet-group-identifier dms-subnets

# Create source endpoint (Oracle on-prem)
aws dms create-endpoint \
    --endpoint-identifier oracle-source \
    --endpoint-type source \
    --engine-name oracle \
    --server-name 192.168.1.100 \
    --port 1521 \
    --username admin \
    --password 'SecurePass' \
    --database-name ORCL

# Create target endpoint (Aurora PostgreSQL)
aws dms create-endpoint \
    --endpoint-identifier aurora-target \
    --endpoint-type target \
    --engine-name aurora-postgresql \
    --server-name mydb.cluster-xxxx.us-east-1.rds.amazonaws.com \
    --port 5432 \
    --username admin \
    --password 'SecurePass' \
    --database-name myapp

# Test connections
aws dms test-connection \
    --replication-instance-arn arn:aws:dms:us-east-1:ACCT:rep:my-dms \
    --endpoint-arn arn:aws:dms:us-east-1:ACCT:endpoint:oracle-source

# Create replication task (Full Load + CDC)
aws dms create-replication-task \
    --replication-task-identifier oracle-to-aurora \
    --source-endpoint-arn arn:aws:dms:us-east-1:ACCT:endpoint:oracle-source \
    --target-endpoint-arn arn:aws:dms:us-east-1:ACCT:endpoint:aurora-target \
    --replication-instance-arn arn:aws:dms:us-east-1:ACCT:rep:my-dms \
    --migration-type full-load-and-cdc \
    --table-mappings '{
      "rules": [{
        "rule-type": "selection",
        "rule-id": "1",
        "rule-name": "all-tables",
        "object-locator": {
          "schema-name": "APP_SCHEMA",
          "table-name": "%"
        },
        "rule-action": "include"
      }]
    }'

# Start migration
aws dms start-replication-task \
    --replication-task-arn arn:aws:dms:us-east-1:ACCT:task:oracle-to-aurora \
    --start-replication-task-type start-replication
```

---

## Application Migration Service (MGN)

> Formerly CloudEndure Migration. Automated lift-and-shift for servers.

```bash
# Install MGN agent on source server
wget -O ./aws-replication-installer-init.py \
    https://aws-application-migration-service-us-east-1.s3.amazonaws.com/latest/linux/aws-replication-installer-init.py

sudo python3 aws-replication-installer-init.py \
    --region us-east-1 \
    --aws-access-key-id AKIA... \
    --aws-secret-access-key xxxxxx

# Agent continuously replicates disk blocks to AWS
# Source server keeps running (no downtime during replication)

# Launch test instance
aws mgn start-test --source-server-id s-12345

# Launch cutover (production migration)
aws mgn start-cutover --source-server-id s-12345

# Process:
# 1. Agent installed on source → continuous replication
# 2. Test launch → verify in AWS (non-disruptive)
# 3. Cutover → final sync → launch production instance
# 4. Verify → update DNS → decommission source
```

---

## Real-Time Example 1: Enterprise Database Migration (Oracle → Aurora)

**Scenario:** Migrate 2 TB Oracle database to Aurora PostgreSQL with <1 hour downtime.

```bash
# Phase 1: Schema Conversion (SCT)
# Download and install AWS SCT
# Connect to source Oracle and target Aurora
# Convert schema (SCT handles data type mappings)
# Review conversion report → fix incompatibilities manually

# Phase 2: Full Load (DMS) — done during business hours
# DMS copies all data: ~8 hours for 2 TB

# Phase 3: CDC (Change Data Capture) — ongoing
# DMS replicates changes in near-real-time
# Source Oracle continues serving production traffic

# Phase 4: Cutover (maintenance window)
# Stop application writes to Oracle
# Wait for CDC to catch up (5-15 minutes)
# Point application to Aurora
# Total downtime: 15-45 minutes

# Phase 5: Validation
# Run data validation queries
# Compare row counts, checksums
# Monitor Aurora performance
```

---

## Real-Time Example 2: Lift-and-Shift 50 Servers with MGN

**Scenario:** Migrate 50 on-premise Linux/Windows servers to EC2 with minimal downtime.

```bash
# Step 1: Install MGN agent on all 50 servers (automated)
for server in $(cat server-list.txt); do
    ssh ec2-user@$server "wget -O installer.py https://...; sudo python3 installer.py --region us-east-1"
done

# Step 2: Monitor replication in Migration Hub
# Each server shows: Not Ready → Ready for Testing → Ready for Cutover

# Step 3: Configure launch settings per server
# Instance type, subnet, security groups, IAM role

# Step 4: Test launch (non-disruptive)
aws mgn start-test --source-server-id s-12345

# Step 5: Validate test instances
# Run smoke tests, check connectivity, verify applications

# Step 6: Cutover in waves (10 servers at a time)
# Wave 1: Non-critical servers (verify process)
# Wave 2-5: Remaining servers by dependency groups

# Step 7: DNS/Route53 updates, decommission source servers
```

---

## Real-Time Example 3: Hybrid DataSync for Storage Migration

**Scenario:** Continuously sync 10 TB NFS file share to S3 while users keep accessing files.

```bash
# Deploy DataSync agent (VM on-premise)
# Activate agent in AWS Console

# Create source location (NFS)
aws datasync create-location-nfs \
    --server-hostname 192.168.1.100 \
    --subdirectory /shared/data \
    --on-prem-config '{"AgentArns":["arn:aws:datasync:us-east-1:ACCT:agent/agent-12345"]}'

# Create destination location (S3)
aws datasync create-location-s3 \
    --s3-bucket-arn arn:aws:s3:::migration-data \
    --s3-config '{"BucketAccessRoleArn":"arn:aws:iam::ACCT:role/DataSyncS3Role"}' \
    --s3-storage-class INTELLIGENT_TIERING

# Create and run task
aws datasync create-task \
    --source-location-arn arn:aws:datasync:us-east-1:ACCT:location/loc-src \
    --destination-location-arn arn:aws:datasync:us-east-1:ACCT:location/loc-dst \
    --options '{
      "VerifyMode": "ONLY_FILES_TRANSFERRED",
      "OverwriteMode": "ALWAYS",
      "TransferMode": "CHANGED",
      "PreserveDeletedFiles": "PRESERVE",
      "LogLevel": "TRANSFER"
    }' \
    --schedule '{"ScheduleExpression":"cron(0 */6 * * ? *)"}'
    # Sync every 6 hours

# Monitor transfer
aws datasync describe-task-execution --task-execution-arn TASK_EXEC_ARN
```

---

## Migration Tools Decision Guide

| Scenario | Tool |
|----------|------|
| Move VMs as-is to EC2 | **Application Migration Service (MGN)** |
| Migrate databases (same or different engine) | **DMS + SCT** |
| Convert DB schema (Oracle → PostgreSQL) | **Schema Conversion Tool (SCT)** |
| Move file shares (NFS/SMB) to S3/EFS | **DataSync** |
| Transfer > 10 TB physically | **Snow Family (Snowball)** |
| Transfer files via SFTP/FTP | **Transfer Family** |
| Track all migrations centrally | **Migration Hub** |
| Discover on-prem server inventory | **Application Discovery Service** |
| Move VMware VMs to AWS | **VMware Cloud on AWS** (Relocate) |
| Move containers to ECS/EKS | **App2Container** |

---

## Labs

### Lab 1: Set Up DMS Replication (RDS MySQL → RDS PostgreSQL)
```bash
# Create source RDS MySQL with sample data
# Create target RDS PostgreSQL (empty)
# Create DMS replication instance
# Create source and target endpoints
# Test connections
# Create replication task (full-load + CDC)
# Run migration
# Verify data in target
# Insert new rows in source → verify CDC replication
```

### Lab 2: Simulate Server Migration with MGN
```bash
# Launch an EC2 "source" instance (simulating on-prem)
# Install MGN agent
# Monitor replication progress
# Launch test instance
# Verify test instance has same data
# Perform cutover
```

### Lab 3: DataSync from EFS to S3
```bash
# Create EFS with sample files
# Create S3 bucket
# Create DataSync task (EFS → S3)
# Run task and monitor progress
# Verify files in S3
# Add new files to EFS → run incremental sync
```

---

## Interview Questions

1. **What are the 6 Rs of migration?**
   → Rehost (lift & shift), Replatform (lift & reshape), Repurchase (SaaS), Refactor (re-architect), Retire (decommission), Retain (keep on-prem). Plus Relocate (VMware).

2. **What is AWS DMS?**
   → Database Migration Service. Migrates databases to AWS with minimal downtime using continuous replication (CDC). Supports homogeneous and heterogeneous migrations.

3. **DMS Full Load vs CDC — when to use each?**
   → Full Load: initial bulk copy. CDC: ongoing replication of changes. Full Load + CDC: used together for zero-downtime migration (bulk copy, then sync changes until cutover).

4. **What is the Schema Conversion Tool (SCT)?**
   → Converts database schema between different engines (e.g., Oracle → PostgreSQL). Highlights incompatibilities, provides code fixes, and generates assessment reports.

5. **How does Application Migration Service (MGN) work?**
   → Install agent on source server → continuous block-level replication to AWS → test launch → cutover. Source server stays running during replication. Supports Linux and Windows.

6. **What is AWS Migration Hub?**
   → Central dashboard to plan and track migrations from multiple tools (DMS, MGN, etc.). Shows progress, status, and dependencies across all migration workloads.

7. **When would you use DataSync vs Snowball?**
   → DataSync: online, incremental sync over network. Snowball: offline, physical device for >10 TB when network is too slow. DataSync for ongoing sync; Snowball for one-time bulk.

8. **How do you minimize downtime during database migration?**
   → Use DMS Full Load + CDC. Full load runs while source is live. CDC keeps target in sync. Cutover window: stop writes → wait for CDC to catch up (minutes) → switch connections.
