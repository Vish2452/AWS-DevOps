#!/bin/bash
###############################################################################
# 06-disk-monitor.sh — Disk usage monitoring with SNS alerts
###############################################################################
set -euo pipefail

THRESHOLD=${DISK_THRESHOLD:-80}
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
SNS_TOPIC_ARN="${SNS_TOPIC_ARN:-}"
LOG_FILE="/var/log/disk-monitor.log"
ALERT_SENT=false

echo "[${DATE}] Disk monitor check started (threshold: ${THRESHOLD}%)" | tee -a "$LOG_FILE"

df -hP | grep -vE '^Filesystem|tmpfs|cdrom|devtmpfs' | while read -r line; do
    usage=$(echo "$line" | awk '{ print $5 }' | tr -d '%')
    partition=$(echo "$line" | awk '{ print $1 }')
    mount=$(echo "$line" | awk '{ print $6 }')
    size=$(echo "$line" | awk '{ print $2 }')
    used=$(echo "$line" | awk '{ print $3 }')
    avail=$(echo "$line" | awk '{ print $4 }')

    if [ "$usage" -ge "$THRESHOLD" ]; then
        MESSAGE="🚨 DISK ALERT: ${HOSTNAME}
Partition: ${partition}
Mount:     ${mount}
Usage:     ${usage}%
Size:      ${size}
Used:      ${used}
Available: ${avail}
Time:      ${DATE}"

        echo "$MESSAGE" | tee -a "$LOG_FILE"

        # Send to SNS if configured
        if [ -n "$SNS_TOPIC_ARN" ]; then
            aws sns publish \
                --topic-arn "$SNS_TOPIC_ARN" \
                --subject "DISK ALERT: ${HOSTNAME} — ${partition} at ${usage}%" \
                --message "$MESSAGE" 2>/dev/null || echo "Failed to send SNS alert"
        fi
    else
        echo "[${DATE}] OK: ${partition} (${mount}) at ${usage}%" >> "$LOG_FILE"
    fi
done
