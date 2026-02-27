#!/bin/bash
###############################################################################
# 02-harden-ssh.sh — SSH Hardening for production EC2
###############################################################################
set -euo pipefail

echo "========================================="
echo "  EC2 Server Hardening — SSH"
echo "========================================="

SSH_PORT=2222

# Backup original config
echo "[1/4] Backing up SSH config..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Apply hardened config
echo "[2/4] Applying hardened SSH configuration..."
sudo tee /etc/ssh/sshd_config.d/hardening.conf << EOF
# ============================================
# SSH Hardening Configuration
# Generated: $(date)
# ============================================

# Network
Port ${SSH_PORT}
AddressFamily inet
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
LoginGraceTime 30
PermitEmptyPasswords no

# Session
ClientAliveInterval 300
ClientAliveCountMax 2
MaxSessions 3

# Security
Protocol 2
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Access Control
AllowUsers ec2-user

# Banner
Banner /etc/ssh/banner.txt
EOF

# Create warning banner
echo "[3/4] Creating SSH banner..."
sudo tee /etc/ssh/banner.txt << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║  UNAUTHORIZED ACCESS PROHIBITED                              ║
║  This system is for authorized users only.                   ║
║  All activities are monitored, logged, and subject to audit. ║
║  Disconnect IMMEDIATELY if you are not authorized.           ║
╚══════════════════════════════════════════════════════════════╝
EOF

# Validate and restart
echo "[4/4] Validating and restarting SSH..."
sudo sshd -t
sudo systemctl restart sshd

echo ""
echo "✅ SSH hardening complete!"
echo "   Port:              ${SSH_PORT}"
echo "   Root Login:        DISABLED"
echo "   Password Auth:     DISABLED"
echo "   Max Auth Tries:    3"
echo ""
echo "⚠️  IMPORTANT: Update your Security Group to allow port ${SSH_PORT}"
echo "   Connect with: ssh -i key.pem -p ${SSH_PORT} ec2-user@<ip>"
