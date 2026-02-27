#!/bin/bash
###############################################################################
# 04-firewall-setup.sh — iptables firewall rules
###############################################################################
set -euo pipefail

echo "========================================="
echo "  EC2 Server Hardening — Firewall"
echo "========================================="

echo "[1/3] Flushing existing rules..."
sudo iptables -F
sudo iptables -X
sudo iptables -Z

echo "[2/3] Applying firewall rules..."

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH (custom port)
sudo iptables -A INPUT -p tcp --dport 2222 -m state --state NEW -m recent --set --name SSH
sudo iptables -A INPUT -p tcp --dport 2222 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# HTTP & HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# ICMP (ping) — rate limited
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 4 -j ACCEPT

# Logging dropped packets
sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES-DROP: " --log-level 4

# Drop everything else (already default, but explicit)
sudo iptables -A INPUT -j DROP

echo "[3/3] Saving rules..."
sudo iptables-save | sudo tee /etc/iptables.rules > /dev/null

# Persist across reboots
sudo tee /etc/systemd/system/iptables-restore.service << 'EOF'
[Unit]
Description=Restore iptables rules
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables.rules

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable iptables-restore

echo ""
echo "✅ Firewall configured!"
sudo iptables -L -v -n --line-numbers
