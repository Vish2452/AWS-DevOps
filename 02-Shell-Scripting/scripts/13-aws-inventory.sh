#!/bin/bash
###############################################################################
# 13-aws-inventory.sh — AWS Resource Inventory Report
# Concepts: aws ec2 describe-*, jq, CSV output, multiple services
###############################################################################
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
DATE=$(date +%Y%m%d)
OUTPUT_DIR="/tmp/aws-inventory-${DATE}"
mkdir -p "$OUTPUT_DIR"

echo "============================================="
echo "  AWS Resource Inventory — ${REGION}"
echo "  Date: $(date)"
echo "============================================="

# --- EC2 Instances ---
echo -e "\n📦 EC2 Instances..."
echo "InstanceId,Name,Type,State,PrivateIP,PublicIP,LaunchTime" > "$OUTPUT_DIR/ec2-instances.csv"
aws ec2 describe-instances --region "$REGION" \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,PrivateIpAddress,PublicIpAddress,LaunchTime]' \
    --output json | jq -r '.[][] | @csv' >> "$OUTPUT_DIR/ec2-instances.csv"
EC2_COUNT=$(tail -n +2 "$OUTPUT_DIR/ec2-instances.csv" | wc -l)
echo "  Found: ${EC2_COUNT} instances"

# --- EBS Volumes ---
echo -e "\n💾 EBS Volumes..."
echo "VolumeId,Size(GB),State,Type,Encrypted,AttachedTo" > "$OUTPUT_DIR/ebs-volumes.csv"
aws ec2 describe-volumes --region "$REGION" \
    --query 'Volumes[*].[VolumeId,Size,State,VolumeType,Encrypted,Attachments[0].InstanceId]' \
    --output json | jq -r '.[] | @csv' >> "$OUTPUT_DIR/ebs-volumes.csv"
UNATTACHED=$(aws ec2 describe-volumes --region "$REGION" --filters Name=status,Values=available --query 'Volumes[*].VolumeId' --output text | wc -w)
echo "  Unattached volumes: ${UNATTACHED} (💰 potential savings)"

# --- Elastic IPs ---
echo -e "\n🌐 Elastic IPs..."
echo "AllocationId,PublicIP,AssociatedInstanceId,Domain" > "$OUTPUT_DIR/elastic-ips.csv"
aws ec2 describe-addresses --region "$REGION" \
    --query 'Addresses[*].[AllocationId,PublicIp,InstanceId,Domain]' \
    --output json | jq -r '.[] | @csv' >> "$OUTPUT_DIR/elastic-ips.csv"
UNASSOCIATED=$(aws ec2 describe-addresses --region "$REGION" --query 'Addresses[?AssociationId==null].AllocationId' --output text | wc -w)
echo "  Unassociated EIPs: ${UNASSOCIATED} (💰 \$3.65/month each)"

# --- Security Groups ---
echo -e "\n🔒 Security Groups..."
echo "GroupId,GroupName,VpcId,Description" > "$OUTPUT_DIR/security-groups.csv"
aws ec2 describe-security-groups --region "$REGION" \
    --query 'SecurityGroups[*].[GroupId,GroupName,VpcId,Description]' \
    --output json | jq -r '.[] | @csv' >> "$OUTPUT_DIR/security-groups.csv"

# --- S3 Buckets ---
echo -e "\n🪣 S3 Buckets..."
echo "BucketName,CreationDate" > "$OUTPUT_DIR/s3-buckets.csv"
aws s3api list-buckets --query 'Buckets[*].[Name,CreationDate]' \
    --output json | jq -r '.[] | @csv' >> "$OUTPUT_DIR/s3-buckets.csv"
S3_COUNT=$(tail -n +2 "$OUTPUT_DIR/s3-buckets.csv" | wc -l)
echo "  Found: ${S3_COUNT} buckets"

# --- RDS Instances ---
echo -e "\n🗄️ RDS Instances..."
echo "DBInstanceId,Engine,Class,Status,MultiAZ,StorageType" > "$OUTPUT_DIR/rds-instances.csv"
aws rds describe-db-instances --region "$REGION" \
    --query 'DBInstances[*].[DBInstanceIdentifier,Engine,DBInstanceClass,DBInstanceStatus,MultiAZ,StorageType]' \
    --output json | jq -r '.[] | @csv' >> "$OUTPUT_DIR/rds-instances.csv" 2>/dev/null || echo "  No RDS instances"

# --- Summary ---
echo -e "\n============================================="
echo "  📁 Reports saved to: ${OUTPUT_DIR}/"
ls -la "$OUTPUT_DIR/"
echo "============================================="
