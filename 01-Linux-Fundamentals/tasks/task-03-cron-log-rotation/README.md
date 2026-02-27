# Task 3 — Cron Jobs & Log Rotation

## Objective
Set up automated log rotation using logrotate and cron, configure disk monitoring with email alerts.

## Steps

### 1. Logrotate Configuration
```bash
# Create custom logrotate config for application logs
sudo tee /etc/logrotate.d/app-logs << 'EOF'
/opt/project/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root devops
    sharedscripts
    postrotate
        systemctl reload nginx 2>/dev/null || true
    endscript
}
EOF

# Test logrotate (dry run)
sudo logrotate -d /etc/logrotate.d/app-logs

# Force run
sudo logrotate -f /etc/logrotate.d/app-logs
```

### 2. Cron Job for Log Cleanup
```bash
# Edit crontab for root
sudo crontab -e

# Add: Clean logs older than 30 days at 2 AM daily
0 2 * * * find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null

# Add: Archive application logs weekly
0 3 * * 0 tar -czf /backup/logs/app-logs-$(date +\%Y\%m\%d).tar.gz /opt/project/logs/*.log

# List cron jobs
sudo crontab -l
```

### 3. Disk Monitoring Script with Alerts
```bash
cat > /opt/project/scripts/disk-monitor.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail

THRESHOLD=80
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

df -hP | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $6 }' | while read -r output; do
    usage=$(echo "$output" | awk '{ print $1 }' | tr -d '%')
    partition=$(echo "$output" | awk '{ print $2 }')
    mount=$(echo "$output" | awk '{ print $3 }')

    if [ "$usage" -ge "$THRESHOLD" ]; then
        echo "WARNING: ${HOSTNAME} — Disk usage on ${partition} (${mount}) is ${usage}% at ${DATE}"
        # Send to SNS (uncomment when configured)
        # aws sns publish --topic-arn arn:aws:sns:us-east-1:ACCOUNT:disk-alerts \
        #   --message "ALERT: ${HOSTNAME} disk ${partition} at ${usage}%"
    fi
done
SCRIPT

chmod +x /opt/project/scripts/disk-monitor.sh

# Add to cron — check every 15 minutes
echo "*/15 * * * * /opt/project/scripts/disk-monitor.sh >> /var/log/disk-monitor.log 2>&1" | sudo tee -a /var/spool/cron/root
```

### 4. Systemd Timer (Modern Alternative to Cron)
```bash
# Create service unit
sudo tee /etc/systemd/system/disk-monitor.service << 'EOF'
[Unit]
Description=Disk Usage Monitor

[Service]
Type=oneshot
ExecStart=/opt/project/scripts/disk-monitor.sh
StandardOutput=journal
StandardError=journal
EOF

# Create timer unit
sudo tee /etc/systemd/system/disk-monitor.timer << 'EOF'
[Unit]
Description=Run Disk Monitor every 15 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now disk-monitor.timer
sudo systemctl list-timers
```

## Validation Checklist
- [ ] Logrotate configured for application logs (daily, 7 rotations, compressed)
- [ ] Cron job cleans old logs automatically
- [ ] Disk monitoring script runs every 15 minutes
- [ ] Alerts trigger when disk usage exceeds 80%
- [ ] Both cron and systemd timer methods implemented
