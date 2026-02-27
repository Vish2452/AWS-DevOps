#!/bin/bash
###############################################################################
# 06-ec2-scheduler.sh — AWS EC2 Start/Stop Scheduler
# Concepts: aws ec2, jq, cron, tag-based filtering
###############################################################################
set -euo pipefail

ACTION="${1:-status}"
TAG_KEY="${TAG_KEY:-Schedule}"
TAG_VALUE="${TAG_VALUE:-office-hours}"
REGION="${AWS_REGION:-us-east-1}"

usage() {
    echo "Usage: $0 {start|stop|status}"
    echo "  Manages EC2 instances tagged with ${TAG_KEY}=${TAG_VALUE}"
    echo ""
    echo "Environment variables:"
    echo "  TAG_KEY    - Tag key to filter (default: Schedule)"
    echo "  TAG_VALUE  - Tag value to filter (default: office-hours)"
    echo "  AWS_REGION - AWS region (default: us-east-1)"
    exit 1
}

get_instances() {
    local state_filter="$1"
    aws ec2 describe-instances \
        --region "$REGION" \
        --filters \
            "Name=tag:${TAG_KEY},Values=${TAG_VALUE}" \
            "Name=instance-state-name,Values=${state_filter}" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0],State.Name]' \
        --output json | jq -r '.[][] | @tsv'
}

case "$ACTION" in
    start)
        echo "🟢 Starting instances tagged ${TAG_KEY}=${TAG_VALUE}..."
        INSTANCES=$(get_instances "stopped")
        if [ -z "$INSTANCES" ]; then
            echo "  No stopped instances found."
            exit 0
        fi
        INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}' | tr '\n' ' ')
        aws ec2 start-instances --region "$REGION" --instance-ids $INSTANCE_IDS
        echo "$INSTANCES" | while IFS=$'\t' read -r id type name state; do
            echo "  Started: ${id} (${name:-unnamed}) - ${type}"
        done
        ;;
    stop)
        echo "🔴 Stopping instances tagged ${TAG_KEY}=${TAG_VALUE}..."
        INSTANCES=$(get_instances "running")
        if [ -z "$INSTANCES" ]; then
            echo "  No running instances found."
            exit 0
        fi
        INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}' | tr '\n' ' ')
        aws ec2 stop-instances --region "$REGION" --instance-ids $INSTANCE_IDS
        echo "$INSTANCES" | while IFS=$'\t' read -r id type name state; do
            echo "  Stopped: ${id} (${name:-unnamed}) - ${type}"
        done
        ;;
    status)
        echo "📊 Instances tagged ${TAG_KEY}=${TAG_VALUE}:"
        for state in running stopped; do
            INSTANCES=$(get_instances "$state")
            if [ -n "$INSTANCES" ]; then
                echo "$INSTANCES" | while IFS=$'\t' read -r id type name state; do
                    printf "  %-20s %-15s %-12s %s\n" "${id}" "${name:-unnamed}" "${type}" "${state}"
                done
            fi
        done
        ;;
    *)
        usage
        ;;
esac

# Cron examples:
# Start at 8 AM EST (13:00 UTC): 0 13 * * 1-5 /opt/scripts/06-ec2-scheduler.sh start
# Stop at 7 PM EST (00:00 UTC):  0 0  * * 2-6 /opt/scripts/06-ec2-scheduler.sh stop
