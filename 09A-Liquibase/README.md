# Module 9A — Liquibase Database DevOps (1 Week)

> **Objective:** Manage database schema changes as code. Integrate Liquibase with CI/CD for zero-downtime database migrations.

---

## 🗄️ Real-World Analogy: Liquibase is Like a Building Renovation Logbook

Imagine a **building (database)** that needs renovations over time:

```
🙅 WITHOUT LIQUIBASE (Chaos!):

  Developer A: "I added a 'phone' column to the users table on staging"
  Developer B: "Wait, I renamed it to 'mobile' on production!"
  DBA:         "Which version is correct? Production is different from dev!" 😱

  ❌ No record of WHO changed WHAT and WHEN
  ❌ Dev database looks different from production
  ❌ Rollback? "Let me try to remember the old structure..."


📖 WITH LIQUIBASE (Renovation Logbook!):

  Think of it as a building renovation logbook:
  ┌─────────────────────────────────────────────┐
  │ Renovation #1 (Jan 2024, by Alice):       │
  │   "Add a new bathroom on floor 2"          │
  │   Undo: "Remove the bathroom"               │
  │                                             │
  │ Renovation #2 (Feb 2024, by Bob):          │
  │   "Widen the kitchen doorway"               │
  │   Undo: "Narrow it back to original size"   │
  │                                             │
  │ Renovation #3 (Mar 2024, by Alice):        │
  │   "Add electricity to the garage"           │
  │   Undo: "Remove garage wiring"              │
  └─────────────────────────────────────────────┘

  Now apply this logbook to any building:
  New building (new DB)  → Apply steps 1, 2, 3 in order → Identical!
  Production DB          → Already has 1 & 2, just apply 3
  Problem with step 3?   → Rollback: undo step 3 automatically!
```

### Database Concepts Mapped
| Renovation Term | Liquibase Term | Database Action |
|---|---|---|
| Renovation logbook | Changelog | Master file listing all changes |
| Single renovation task | Changeset | One atomic schema change |
| Apply renovation | `liquibase update` | Run pending migrations |
| Undo renovation | `liquibase rollback` | Revert a change |
| Renovation history | DATABASECHANGELOG table | Tracks what's been applied |
| Building inspector | `liquibase validate` | Check changelog for errors |

---

## Why Liquibase?
- Track schema changes in version control (just like application code)
- Rollback failed migrations
- Environment-specific changelogs
- Audit trail for every schema change
- Works with PostgreSQL, MySQL, Oracle, SQL Server

---

## Concepts

### Changelog Formats
| Format | Extension | Use Case |
|--------|-----------|----------|
| SQL | `.sql` | Familiar for DBAs, raw SQL statements |
| XML | `.xml` | Most feature-rich, Liquibase-native |
| YAML | `.yaml` | Readable, popular in DevOps teams |
| JSON | `.json` | Machine-parseable |

### Core Terminology
| Term | Description |
|------|------------|
| **Changelog** | Master file listing all changesets |
| **Changeset** | Atomic unit of change (author + id = unique) |
| **Precondition** | Guard — skip/fail changeset if not met |
| **Context** | Environment label (dev, staging, prod) |
| **Label** | Version label for selective deployment |
| **Tag** | Snapshot marker for rollback |
| **DATABASECHANGELOG** | Tracking table in target database |
| **DATABASECHANGELOGLOCK** | Lock table to prevent concurrent runs |

---

## Commands Cheat Sheet

```bash
# Core Commands
liquibase update                    # Apply pending changesets
liquibase rollback --tag=v1.0       # Rollback to a tag
liquibase rollback-count 1          # Rollback last N changesets
liquibase rollback-to-date 2025-01-01  # Rollback to date
liquibase status                    # Show pending changesets
liquibase validate                  # Validate changelog syntax
liquibase tag v1.0                  # Tag current state
liquibase changelog-sync            # Mark all as executed (catch-up)

# Diff & Documentation
liquibase diff                      # Compare two databases
liquibase diff-changelog            # Generate changelog from diff
liquibase generate-changelog        # Reverse-engineer existing DB
liquibase db-doc                    # Generate HTML documentation

# Quality Gates
liquibase checks run                # Run policy checks (Pro)
liquibase unexpected-changesets     # Find untracked changes

# Preview
liquibase update-sql                # Preview SQL without executing
liquibase rollback-sql --tag=v1.0   # Preview rollback SQL
```

---

## Hands-On Labs

### Lab 1: SQL Changelog
```sql
-- changelog/001-create-users.sql
-- liquibase formatted sql

-- changeset devops-user:001
-- comment: Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- rollback DROP TABLE users;

-- changeset devops-user:002
-- comment: Add phone column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
-- rollback ALTER TABLE users DROP COLUMN phone;

-- changeset devops-user:003 context:prod
-- comment: Create index for production performance
CREATE INDEX idx_users_email ON users(email);
-- rollback DROP INDEX idx_users_email;
```

### Lab 2: XML Changelog
```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <changeSet id="001" author="devops-user">
        <preConditions onFail="MARK_RAN">
            <not><tableExists tableName="orders"/></not>
        </preConditions>
        <createTable tableName="orders">
            <column name="id" type="SERIAL" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="user_id" type="INT">
                <constraints nullable="false" foreignKeyName="fk_orders_users"
                             references="users(id)"/>
            </column>
            <column name="total" type="DECIMAL(10,2)"/>
            <column name="status" type="VARCHAR(50)" defaultValue="pending"/>
        </createTable>
    </changeSet>

    <changeSet id="002" author="devops-user">
        <addColumn tableName="orders">
            <column name="shipped_at" type="TIMESTAMP"/>
        </addColumn>
        <rollback>
            <dropColumn tableName="orders" columnName="shipped_at"/>
        </rollback>
    </changeSet>
</databaseChangeLog>
```

### Lab 3: Master Changelog with Includes
```xml
<!-- changelog-master.xml -->
<databaseChangeLog>
    <include file="changelog/001-create-users.xml"/>
    <include file="changelog/002-create-orders.xml"/>
    <include file="changelog/003-seed-data.xml"/>
    <includeAll path="changelog/patches/" />
</databaseChangeLog>
```

---

## Liquibase Properties File
```properties
# liquibase.properties
changeLogFile=changelog-master.xml
url=jdbc:postgresql://localhost:5432/myapp
username=liquibase_user
password=${LB_PASSWORD}
driver=org.postgresql.Driver
defaultSchemaName=public
liquibase.hub.mode=off
```

---

## IAM Auth Token Flow (RDS)
```
App/Liquibase → STS/IAM → Generate Auth Token → RDS PostgreSQL
                                                     ↓
                                              Token valid 15 min
                                              No password stored!
```

```bash
# Generate IAM auth token for RDS
export PGPASSWORD=$(aws rds generate-db-auth-token \
  --hostname mydb.cluster-abc.us-east-1.rds.amazonaws.com \
  --port 5432 --region us-east-1 --username liquibase_iam_user)
```

---

## Real-Time Project: Liquibase CI/CD for RDS PostgreSQL

### Architecture
```
Developer → Git Push → GitHub Actions → Liquibase Update → RDS PostgreSQL
    │                      │                                      │
    │              ┌───────┴────────┐                   ┌────────┴────────┐
    │              │ update-sql     │                   │  DEV Database   │
    │              │ (preview only) │                   │  STG Database   │
    │              │ on PR          │                   │  PROD Database  │
    │              └────────────────┘                   └─────────────────┘
    └── Rollback via: liquibase rollback --tag=<release>
```

### Project Structure
```
db-migrations/
├── liquibase.properties          # Default config
├── changelog-master.xml          # Master changelog
├── changelog/
│   ├── v1.0/
│   │   ├── 001-create-users.sql
│   │   ├── 002-create-orders.sql
│   │   └── 003-seed-lookup-data.sql
│   ├── v1.1/
│   │   ├── 001-add-user-roles.sql
│   │   └── 002-create-audit-table.sql
│   └── v2.0/
│       └── 001-partition-orders.sql
└── .github/workflows/
    └── db-migrate.yml
```

### GitHub Actions Workflow
```yaml
name: Database Migration
on:
  pull_request:
    paths: ['db-migrations/**']
  push:
    branches: [main]
    paths: ['db-migrations/**']

env:
  LB_VERSION: "4.27.0"

jobs:
  preview:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Liquibase
        run: |
          wget -qO- "https://github.com/liquibase/liquibase/releases/download/v${LB_VERSION}/liquibase-${LB_VERSION}.tar.gz" | tar xz -C /opt/liquibase
          echo "/opt/liquibase" >> $GITHUB_PATH

      - name: Validate Changelog
        run: liquibase validate
        working-directory: db-migrations

      - name: Preview SQL (Dry Run)
        run: liquibase update-sql > migration-preview.sql
        working-directory: db-migrations

      - name: Comment PR with Preview
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const sql = fs.readFileSync('db-migrations/migration-preview.sql', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🗄️ Database Migration Preview\n\`\`\`sql\n${sql.slice(0, 3000)}\n\`\`\``
            });

  migrate:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Install Liquibase
        run: |
          wget -qO- "https://github.com/liquibase/liquibase/releases/download/v${LB_VERSION}/liquibase-${LB_VERSION}.tar.gz" | tar xz -C /opt/liquibase
          echo "/opt/liquibase" >> $GITHUB_PATH

      - name: Generate IAM Auth Token
        run: |
          export PGPASSWORD=$(aws rds generate-db-auth-token \
            --hostname ${{ vars.RDS_HOST }} \
            --port 5432 --region us-east-1 \
            --username liquibase_user)
          echo "PGPASSWORD=$PGPASSWORD" >> $GITHUB_ENV

      - name: Tag Before Migration
        run: liquibase tag "release-${{ github.sha }}"
        working-directory: db-migrations

      - name: Apply Migration
        run: liquibase update
        working-directory: db-migrations

      - name: Verify Status
        run: liquibase status
        working-directory: db-migrations
```

### Deliverables
- [ ] PostgreSQL RDS instance with Liquibase IAM user
- [ ] Versioned changelogs (SQL format, organized by release)
- [ ] Master changelog with ordered includes
- [ ] Preconditions for safe re-runs
- [ ] GitHub Actions: preview SQL on PR, apply on merge
- [ ] Rollback demonstrated (`rollback --tag`)
- [ ] Context-based changelogs (dev vs prod)
- [ ] IAM auth token integration (no passwords in config)
