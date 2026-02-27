# Module 2 — Shell Scripting (1 Week)

> **Objective:** Master Bash scripting with 15 production-grade scripts. Build an AWS cost optimization tool.

---

## 🌍 Real-World Analogy: Shell Scripts are Like Recipe Books

Imagine you run a **restaurant kitchen**:

```
🍳 WITHOUT SCRIPTS (Manual Work):
   Every morning, the chef must remember:
   1. Turn on the oven → 2. Check ingredients → 3. Prep vegetables
   4. Start the soup → 5. Check fridge temperature → 6. Order missing items
   
   If the chef forgets step 3, lunch is ruined!

📖 WITH SCRIPTS (Automation):
   You write a "Morning Prep Recipe Book" (shell script).
   The kitchen assistant follows it EXACTLY every morning.
   Never forgets. Never makes mistakes. Works even on holidays.
   
   That's what a shell script does for servers!
```

### Real-World Examples Everyone Understands

| Task | Without Script (Manual) | With Script (Automated) |
|------|------------------------|------------------------|
| **Backup** | Employee copies files to USB every night | Script runs at 2AM, zips files, uploads to S3 |
| **Monitoring** | Someone checks disk space every hour | Script checks every 5 min, sends SMS if disk > 80% |
| **New Employee** | IT person manually creates account, email, VPN | Script creates everything in 10 seconds |
| **Cost Saving** | Manager reviews AWS bill monthly | Script stops dev servers at 7PM, starts at 8AM daily |

> **Real Example:** A company was paying $3,000/month for dev servers running 24/7. A simple shell script to stop them at night saved **$2,000/month** — that's the power of automation!

```
📊 Before Script:  Dev servers run 24/7  = 720 hrs × $4/hr = $2,880/month
📊 After Script:   Run only 8AM-7PM M-F = 220 hrs × $4/hr = $880/month
💰 Savings: $2,000/month = $24,000/year from ONE script!
```

---

## Topics

### Bash Fundamentals
- Variables, data types, quoting (`'single'` vs `"double"` vs `` `backtick` ``)
- Control structures: `if/elif/else`, `case`, `for`, `while`, `until`
- Functions, return values, local variables
- Arrays, associative arrays
- String manipulation, parameter expansion
- Regex with `grep`/`sed`/`awk`
- Exit codes, error handling, `set -euo pipefail`
- Input: `read`, positional parameters, `getopts`
- File descriptors, redirection (`>`, `>>`, `2>&1`, `&>`)
- Pipes, process substitution `<()`, subshells `$()`
- Debugging: `set -x`, `trap`, `shellcheck`
- Here documents (`<<EOF`) and here strings (`<<<`)

---

## 15 Production Shell Scripts

| # | Script | Concepts Covered | File |
|---|--------|-----------------|------|
| 1 | Automated Backup to S3 | `aws cli`, `tar`, cron, date | [scripts/01-backup-s3.sh](scripts/01-backup-s3.sh) |
| 2 | Log Analyzer | `awk`, `grep`, `sort`, associative arrays | [scripts/02-log-analyzer.sh](scripts/02-log-analyzer.sh) |
| 3 | Disk Usage Alert | `df`, `mail`, conditionals | [scripts/03-disk-alert.sh](scripts/03-disk-alert.sh) |
| 4 | User Account Manager | `useradd`, functions, validation | [scripts/04-user-manager.sh](scripts/04-user-manager.sh) |
| 5 | Service Health Checker | `systemctl`, loops, exit codes | [scripts/05-health-checker.sh](scripts/05-health-checker.sh) |
| 6 | AWS EC2 Start/Stop Scheduler | `aws ec2`, `jq`, cron | [scripts/06-ec2-scheduler.sh](scripts/06-ec2-scheduler.sh) |
| 7 | Deployment Script | `git pull`, `rsync`, rollback, locks | [scripts/07-deploy.sh](scripts/07-deploy.sh) |
| 8 | SSL Certificate Expiry | `openssl`, date arithmetic | [scripts/08-ssl-checker.sh](scripts/08-ssl-checker.sh) |
| 9 | Docker Cleanup | `docker system prune`, images | [scripts/09-docker-cleanup.sh](scripts/09-docker-cleanup.sh) |
| 10 | DB Backup & Restore | `pg_dump`, `mysqldump`, compression | [scripts/10-db-backup.sh](scripts/10-db-backup.sh) |
| 11 | Password Generator | `/dev/urandom`, `tr`, slicing | [scripts/11-password-gen.sh](scripts/11-password-gen.sh) |
| 12 | Bulk File Renamer | `mv`, regex, parameter expansion | [scripts/12-bulk-rename.sh](scripts/12-bulk-rename.sh) |
| 13 | AWS Resource Inventory | `aws ec2 describe-*`, `jq`, CSV | [scripts/13-aws-inventory.sh](scripts/13-aws-inventory.sh) |
| 14 | Terraform Wrapper | `getopts`, env switching, `terraform` | [scripts/14-terraform-wrapper.sh](scripts/14-terraform-wrapper.sh) |
| 15 | CI/CD Pipeline Trigger | `curl`, GitHub API, webhooks, JSON | [scripts/15-cicd-trigger.sh](scripts/15-cicd-trigger.sh) |

---

## Real-Time Project: Automated AWS Cost Optimization Script

**[📁 Project Folder →](project-aws-cost-optimization/)**

### What It Does
- Identifies unused EBS volumes
- Finds unattached Elastic IPs
- Detects idle EC2 instances (low CPU)
- Finds unused NAT Gateways
- Generates a daily cost report
- Emails report via SNS
- Runs as a cron job or Lambda function

### Deliverables
- Production-grade cost optimization script
- Automated daily report via SNS
- Documented savings recommendations

---

## Interview Questions
1. What does `set -euo pipefail` do?
2. Difference between `$@` and `$*`?
3. How to handle errors in a bash script?
4. What is a here document?
5. How to debug a shell script?
6. Difference between `[` and `[[`?
7. How to process CSV files in bash?
8. What is `trap` and when to use it?
9. How to make a script idempotent?
10. Explain process substitution `<()`.
