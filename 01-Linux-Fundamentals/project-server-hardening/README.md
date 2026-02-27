# Real-Time Project: EC2 Server Hardening & Automation

> **Industry Context:** Every production server must be hardened before deploying applications. This project simulates a real DevOps task: take a fresh EC2 instance and make it production-ready.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Amazon Linux 2023 EC2 Instance          │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │  SSH Hardened │  │  Firewall   │  │  Fail2ban  │ │
│  │  Port 2222   │  │  iptables   │  │  3 retries │ │
│  │  Key-only    │  │  HTTP/HTTPS │  │  1hr ban   │ │
│  └─────────────┘  └─────────────┘  └────────────┘ │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │  Logrotate   │  │  Disk       │  │  Nginx     │ │
│  │  Daily/7days │  │  Monitoring │  │  Secured   │ │
│  │  Compressed  │  │  80% alert  │  │  Headers   │ │
│  └─────────────┘  └─────────────┘  └────────────┘ │
│                                                     │
│  Cron Jobs: Log cleanup, disk check, backup        │
│  SNS Alerts: Disk full, SSH brute-force            │
└─────────────────────────────────────────────────────┘
```

## Project Structure

```
project-server-hardening/
├── README.md                    # This file
├── scripts/
│   ├── 01-initial-setup.sh      # System updates, timezone, hostname
│   ├── 02-harden-ssh.sh         # SSH configuration hardening
│   ├── 03-setup-fail2ban.sh     # Brute-force protection
│   ├── 04-firewall-setup.sh     # iptables rules
│   ├── 05-log-rotation.sh       # Logrotate configuration
│   ├── 06-disk-monitor.sh       # Disk usage alerting
│   ├── 07-setup-nginx.sh        # Nginx install & secure config
│   └── 08-setup-cron-jobs.sh    # Automated scheduled tasks
├── configs/
│   ├── sshd-hardening.conf      # SSH hardened config
│   ├── fail2ban-jail.local      # Fail2ban jail config
│   ├── iptables.rules           # Firewall rules
│   ├── nginx-app.conf           # Nginx server block
│   └── logrotate-app.conf       # Log rotation config
└── docs/
    └── hardening-checklist.md   # Security audit checklist
```

## How to Run

```bash
# 1. Clone this repo on your EC2 instance
git clone <repo-url>
cd AWS-DevOps/01-Linux-Fundamentals/project-server-hardening

# 2. Run scripts in order (or run the master script)
chmod +x scripts/*.sh
sudo ./scripts/01-initial-setup.sh
sudo ./scripts/02-harden-ssh.sh
sudo ./scripts/03-setup-fail2ban.sh
sudo ./scripts/04-firewall-setup.sh
sudo ./scripts/05-log-rotation.sh
sudo ./scripts/06-disk-monitor.sh
sudo ./scripts/07-setup-nginx.sh
sudo ./scripts/08-setup-cron-jobs.sh

# 3. Verify hardening
sudo ./scripts/08-setup-cron-jobs.sh  # includes verification
```

## Key Learning Outcomes
- Linux server administration in a cloud environment
- SSH security best practices
- Firewall rule design and implementation
- Automated monitoring and alerting
- Production-ready server configuration
