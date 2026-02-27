#!/bin/bash
###############################################################################
# cost-optimizer.sh — AWS Cost Optimization Tool
# Identifies unused resources and generates savings report
###############################################################################
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
DATE=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="./reports/${DATE}"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN:-}"
DRY_RUN=true
CHECK_TYPE="all"
TOTAL_MONTHLY_SAVINGS=0

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)   CHECK_TYPE="$2"; shift 2 ;;
        --cleanup) DRY_RUN=false; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --region)  REGION="$2"; shift 2 ;;
        -h|--help) echo "Usage: $0 [--check ebs|eip|ec2|snapshots|all] [--cleanup] [--dry-run] [--region REGION]"; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$REPORT_DIR"

echo "╔═══════════════════════════════════════════════╗"
echo "║     AWS Cost Optimization Report              ║"
echo "║     Region: ${REGION}                          "
echo "║     Date:   $(date)                            "
echo "║     Mode:   $([ "$DRY_RUN" = true ] && echo 'SCAN ONLY' || echo 'CLEANUP')"
echo "╚═══════════════════════════════════════════════╝"

# --- Check 1: Unused EBS Volumes ---
check_ebs() {
    echo -e "\n💾 Checking for unused EBS volumes..."
    local volumes
    volumes=$(aws ec2 describe-volumes --region "$REGION" \
        --filters Name=status,Values=available \
        --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime,Tags[?Key==`Name`].Value|[0]]' \
        --output json)

    local count=$(echo "$volumes" | jq 'length')
    if [ "$count" -gt 0 ]; then
        echo "  Found ${count} unattached EBS volumes:"
        echo "VolumeId,Size(GB),Type,Created,Name" > "$REPORT_DIR/unused-ebs.csv"
        echo "$volumes" | jq -r '.[] | @csv' >> "$REPORT_DIR/unused-ebs.csv"
        echo "$volumes" | jq -r '.[] | "  \(.[0]) — \(.[1])GB \(.[2]) (created: \(.[3][:10]))"'

        # Estimate savings (gp3 at $0.08/GB/month)
        local total_gb=$(echo "$volumes" | jq '[.[][1]] | add')
        local savings=$(echo "$total_gb * 0.08" | bc 2>/dev/null || echo "N/A")
        echo "  💰 Estimated monthly savings: \$${savings} (${total_gb} GB total)"
        TOTAL_MONTHLY_SAVINGS=$(echo "$TOTAL_MONTHLY_SAVINGS + ${savings:-0}" | bc 2>/dev/null || echo "$TOTAL_MONTHLY_SAVINGS")

        if [ "$DRY_RUN" = false ]; then
            echo "  ⚠️  Deleting unused volumes..."
            echo "$volumes" | jq -r '.[][0]' | while read -r vol_id; do
                aws ec2 delete-volume --region "$REGION" --volume-id "$vol_id"
                echo "  Deleted: $vol_id"
            done
        fi
    else
        echo "  ✅ No unused EBS volumes found"
    fi
}

# --- Check 2: Unassociated Elastic IPs ---
check_eip() {
    echo -e "\n🌐 Checking for unassociated Elastic IPs..."
    local eips
    eips=$(aws ec2 describe-addresses --region "$REGION" \
        --query 'Addresses[?AssociationId==null].[AllocationId,PublicIp,Domain]' \
        --output json)

    local count=$(echo "$eips" | jq 'length')
    if [ "$count" -gt 0 ]; then
        echo "  Found ${count} unassociated EIPs:"
        echo "$eips" | jq -r '.[] | "  \(.[0]) — \(.[1])"'
        local savings=$(echo "$count * 3.65" | bc 2>/dev/null || echo "N/A")
        echo "  💰 Estimated monthly savings: \$${savings}"
        TOTAL_MONTHLY_SAVINGS=$(echo "$TOTAL_MONTHLY_SAVINGS + ${savings:-0}" | bc 2>/dev/null || echo "$TOTAL_MONTHLY_SAVINGS")

        if [ "$DRY_RUN" = false ]; then
            echo "$eips" | jq -r '.[][0]' | while read -r alloc_id; do
                aws ec2 release-address --region "$REGION" --allocation-id "$alloc_id"
                echo "  Released: $alloc_id"
            done
        fi
    else
        echo "  ✅ No unassociated Elastic IPs found"
    fi
}

# --- Check 3: Idle EC2 Instances ---
check_ec2() {
    echo -e "\n💤 Checking for idle EC2 instances (CPU < 5% avg over 7 days)..."
    local instances
    instances=$(aws ec2 describe-instances --region "$REGION" \
        --filters Name=instance-state-name,Values=running \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
        --output json | jq -r '.[][]')

    echo "$instances" | jq -r '.[0]' 2>/dev/null | while read -r instance_id; do
        [ -z "$instance_id" ] && continue
        local avg_cpu
        avg_cpu=$(aws cloudwatch get-metric-statistics --region "$REGION" \
            --namespace AWS/EC2 \
            --metric-name CPUUtilization \
            --dimensions "Name=InstanceId,Value=${instance_id}" \
            --start-time "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%S)" \
            --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
            --period 604800 \
            --statistics Average \
            --query 'Datapoints[0].Average' \
            --output text 2>/dev/null || echo "N/A")

        if [ "$avg_cpu" != "None" ] && [ "$avg_cpu" != "N/A" ]; then
            local is_idle=$(echo "$avg_cpu < 5" | bc 2>/dev/null || echo "0")
            if [ "$is_idle" = "1" ]; then
                echo "  ⚠️  ${instance_id} — Avg CPU: ${avg_cpu}% (IDLE)"
            fi
        fi
    done
}

# --- Check 4: Old EBS Snapshots ---
check_snapshots() {
    echo -e "\n📸 Checking for EBS snapshots older than 90 days..."
    local cutoff_date
    cutoff_date=$(date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-90d +%Y-%m-%dT%H:%M:%S)

    local owner_id
    owner_id=$(aws sts get-caller-identity --query 'Account' --output text)

    local old_snaps
    old_snaps=$(aws ec2 describe-snapshots --region "$REGION" \
        --owner-ids "$owner_id" \
        --query "Snapshots[?StartTime<='${cutoff_date}'].[SnapshotId,VolumeSize,StartTime,Description]" \
        --output json)

    local count=$(echo "$old_snaps" | jq 'length')
    echo "  Found ${count} snapshots older than 90 days"
    if [ "$count" -gt 0 ]; then
        local total_gb=$(echo "$old_snaps" | jq '[.[][1]] | add')
        local savings=$(echo "${total_gb:-0} * 0.05" | bc 2>/dev/null || echo "N/A")
        echo "  💰 Estimated monthly savings: \$${savings} (${total_gb} GB)"
    fi
}

# --- Execute Checks ---
case "$CHECK_TYPE" in
    ebs)       check_ebs ;;
    eip)       check_eip ;;
    ec2)       check_ec2 ;;
    snapshots) check_snapshots ;;
    all)       check_ebs; check_eip; check_ec2; check_snapshots ;;
    *)         echo "Unknown check: $CHECK_TYPE"; exit 1 ;;
esac

# --- Summary ---
echo -e "\n╔═══════════════════════════════════════════════╗"
echo "║  💰 TOTAL ESTIMATED MONTHLY SAVINGS: \$${TOTAL_MONTHLY_SAVINGS}"
echo "║  📁 Reports saved to: ${REPORT_DIR}/"
echo "╚═══════════════════════════════════════════════╝"

# --- Send SNS Notification ---
if [ -n "$SNS_TOPIC_ARN" ]; then
    aws sns publish \
        --topic-arn "$SNS_TOPIC_ARN" \
        --subject "AWS Cost Report — \$${TOTAL_MONTHLY_SAVINGS}/month savings found" \
        --message "Cost optimization scan completed. Estimated monthly savings: \$${TOTAL_MONTHLY_SAVINGS}. See detailed report in ${REPORT_DIR}/"
    echo "📧 SNS notification sent"
fi
