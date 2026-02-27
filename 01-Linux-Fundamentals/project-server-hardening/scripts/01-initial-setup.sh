#!/bin/bash
###############################################################################
# 01-initial-setup.sh — Initial server setup for Amazon Linux 2023
# Part of: EC2 Server Hardening & Automation Project
###############################################################################
set -euo pipefail

echo "========================================="
echo "  EC2 Server Hardening — Initial Setup"
echo "========================================="

# --- System Updates ---
echo "[1/5] Updating system packages..."
sudo yum update -y
sudo yum install -y \
  vim \
  tree \
  htop \
  curl \
  wget \
  git \
  unzip \
  jq \
  net-tools \
  bind-utils \
  lsof \
  tcpdump \
  tmux

# --- Timezone ---
echo "[2/5] Setting timezone to UTC..."
sudo timedatectl set-timezone UTC
timedatectl

# --- Hostname ---
echo "[3/5] Setting hostname..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
sudo hostnamectl set-hostname "prod-server-${INSTANCE_ID: -6}"
hostname

# --- Swap Configuration ---
echo "[4/5] Configuring swap (1GB)..."
if [ ! -f /swapfile ]; then
  sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
fi
free -h

# --- System Limits ---
echo "[5/5] Configuring system limits..."
sudo tee -a /etc/security/limits.conf << 'EOF'
# Custom limits for production
* soft nofile 65536
* hard nofile 65536
* soft nproc  65536
* hard nproc  65536
EOF

echo ""
echo "✅ Initial setup complete!"
echo "   Hostname: $(hostname)"
echo "   Timezone: $(timedatectl | grep 'Time zone')"
echo "   Swap:     $(free -h | grep Swap | awk '{print $2}')"
