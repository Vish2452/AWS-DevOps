#!/bin/bash
###############################################################################
# 02-log-analyzer.sh — Nginx/Apache Log Analyzer
# Concepts: awk, grep, sort, associative arrays, text processing
###############################################################################
set -euo pipefail

LOG_FILE="${1:-/var/log/nginx/access.log}"
OUTPUT_DIR="/tmp/log-analysis-$(date +%Y%m%d)"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    echo "Usage: $0 [log_file_path]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")

echo "============================================="
echo "  Log Analysis Report"
echo "  File: $LOG_FILE"
echo "  Total Requests: $TOTAL_REQUESTS"
echo "  Date: $(date)"
echo "============================================="

# --- Top 20 IP Addresses ---
echo -e "\n📊 Top 20 IP Addresses:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -20 | \
    awk '{printf "  %-18s %s requests\n", $2, $1}'

# --- HTTP Status Code Distribution ---
echo -e "\n📊 HTTP Status Codes:"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -rn | \
    awk '{
        status=$2;
        if (status ~ /^2/) color="✅";
        else if (status ~ /^3/) color="↪️";
        else if (status ~ /^4/) color="⚠️";
        else if (status ~ /^5/) color="🚨";
        else color="❓";
        printf "  %s %-6s %s requests\n", color, $2, $1
    }'

# --- Top 20 Requested URLs ---
echo -e "\n📊 Top 20 Requested URLs:"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -20 | \
    awk '{printf "  %6s  %s\n", $1, $2}'

# --- Requests per Hour ---
echo -e "\n📊 Requests per Hour:"
awk '{print $4}' "$LOG_FILE" | cut -d: -f2 | sort | uniq -c | \
    awk '{printf "  %02d:00  %s requests\n", $2, $1}'

# --- Top User Agents ---
echo -e "\n📊 Top 10 User Agents:"
awk -F'"' '{print $6}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10 | \
    awk '{$1=$1; printf "  %6s  %s\n", $1, substr($0, index($0,$2))}'

# --- 5xx Errors Summary ---
echo -e "\n🚨 5xx Errors (last 50):"
grep " 5[0-9][0-9] " "$LOG_FILE" | tail -50 | \
    awk '{printf "  %s %s %s → %s\n", $1, $4, $7, $9}'

# --- Bandwidth Usage ---
echo -e "\n📊 Total Bandwidth:"
awk '{sum+=$10} END {
    if (sum > 1073741824) printf "  %.2f GB\n", sum/1073741824;
    else if (sum > 1048576) printf "  %.2f MB\n", sum/1048576;
    else printf "  %.2f KB\n", sum/1024;
}' "$LOG_FILE"

# --- Save report ---
exec > >(tee "$OUTPUT_DIR/report.txt") 2>&1
echo -e "\n📁 Report saved to: $OUTPUT_DIR/report.txt"
