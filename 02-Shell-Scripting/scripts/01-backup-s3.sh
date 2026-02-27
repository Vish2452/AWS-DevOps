#!/bin/bash
###############################################################################
# 01-backup-s3.sh — Automated Backup to S3
# Concepts: aws cli, tar, cron, date formatting, error handling
###############################################################################
set -euo pipefail

# --- Configuration ---
BACKUP_DIRS=("/var/www/app" "/etc/nginx" "/opt/project")
S3_BUCKET="${S3_BACKUP_BUCKET:-my-backups-bucket}"
S3_PREFIX="backups/$(hostname)"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backup-${DATE}"
ARCHIVE_NAME="backup-${DATE}.tar.gz"
LOG_FILE="/var/log/backup.log"

# --- Functions ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
cleanup() { rm -rf "$BACKUP_DIR" "/tmp/${ARCHIVE_NAME}"; }
trap cleanup EXIT

# --- Main ---
log "Starting backup..."
mkdir -p "$BACKUP_DIR"

# Copy directories
for dir in "${BACKUP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        cp -r "$dir" "$BACKUP_DIR/"
        log "  Copied: $dir"
    else
        log "  WARNING: $dir does not exist, skipping"
    fi
done

# Create archive
log "Creating archive..."
tar -czf "/tmp/${ARCHIVE_NAME}" -C "$BACKUP_DIR" .
ARCHIVE_SIZE=$(du -h "/tmp/${ARCHIVE_NAME}" | cut -f1)
log "  Archive size: ${ARCHIVE_SIZE}"

# Upload to S3
log "Uploading to S3..."
aws s3 cp "/tmp/${ARCHIVE_NAME}" "s3://${S3_BUCKET}/${S3_PREFIX}/${ARCHIVE_NAME}" \
    --storage-class STANDARD_IA \
    --sse aws:kms

# Cleanup old backups from S3
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
CUTOFF_DATE=$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y-%m-%d)
aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" | while read -r line; do
    file_date=$(echo "$line" | awk '{print $1}')
    file_name=$(echo "$line" | awk '{print $4}')
    if [[ "$file_date" < "$CUTOFF_DATE" ]] && [ -n "$file_name" ]; then
        aws s3 rm "s3://${S3_BUCKET}/${S3_PREFIX}/${file_name}"
        log "  Deleted old backup: $file_name"
    fi
done

log "✅ Backup complete: s3://${S3_BUCKET}/${S3_PREFIX}/${ARCHIVE_NAME}"

# --- Cron Installation ---
# Add to crontab: 0 2 * * * /opt/scripts/01-backup-s3.sh >> /var/log/backup.log 2>&1
