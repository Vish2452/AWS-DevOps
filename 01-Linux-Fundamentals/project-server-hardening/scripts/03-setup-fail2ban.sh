#!/bin/bash
###############################################################################
# 03-setup-fail2ban.sh — Brute-force protection
###############################################################################
set -euo pipefail

echo "========================================="
echo "  EC2 Server Hardening — Fail2ban"
echo "========================================="

echo "[1/3] Installing fail2ban..."
sudo yum install -y fail2ban || sudo amazon-linux-extras install -y epel && sudo yum install -y fail2ban

echo "[2/3] Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
banaction = iptables-multiport
action = %(action_mwl)s

[sshd]
enabled  = true
port     = 2222
filter   = sshd
logpath  = /var/log/secure
maxretry = 3
bantime  = 7200
EOF

echo "[3/3] Starting fail2ban..."
sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd

echo ""
echo "✅ Fail2ban configured!"
echo "   Max retries: 3"
echo "   Ban time:    2 hours (SSH)"
