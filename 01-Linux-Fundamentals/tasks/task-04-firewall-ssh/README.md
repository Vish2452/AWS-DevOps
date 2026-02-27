# Task 4 — Firewall Rules & SSH Hardening

## Objective
Configure firewall rules using iptables/firewalld and harden SSH access for production security.

## Steps

### 1. SSH Hardening
```bash
# Backup original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Edit SSH config
sudo tee -a /etc/ssh/sshd_config.d/hardening.conf << 'EOF'
# --- SSH Hardening ---
Port 2222                          # Non-default port
PermitRootLogin no                 # Disable root login
PasswordAuthentication no          # Key-only authentication
PubkeyAuthentication yes
MaxAuthTries 3                     # Limit attempts
LoginGraceTime 30                  # 30 second login window
ClientAliveInterval 300            # 5 min keepalive
ClientAliveCountMax 2              # Disconnect after 2 missed
AllowUsers ec2-user charlie        # Whitelist users
Protocol 2                         # SSH v2 only
X11Forwarding no                   # Disable X11
AllowTcpForwarding no              # Disable TCP forwarding
Banner /etc/ssh/banner.txt         # Custom banner
EOF

# Create SSH banner
sudo tee /etc/ssh/banner.txt << 'EOF'
*************************************************************
* WARNING: Unauthorized access to this system is prohibited. *
* All activities are monitored and logged.                   *
*************************************************************
EOF

# Validate and restart
sudo sshd -t
sudo systemctl restart sshd
```

### 2. Fail2Ban Setup
```bash
# Install fail2ban
sudo yum install -y fail2ban  # Amazon Linux
# sudo apt install -y fail2ban  # Ubuntu

# Configure
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600        # 1 hour ban
findtime = 600         # 10 minute window
maxretry = 3           # 3 failures = ban
banaction = iptables-multiport

[sshd]
enabled  = true
port     = 2222
filter   = sshd
logpath  = /var/log/secure
maxretry = 3
EOF

sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

### 3. Firewall Configuration (iptables)
```bash
# Flush existing rules
sudo iptables -F
sudo iptables -X

# Default policies — deny all incoming, allow outgoing
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH on custom port
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# Allow HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow ICMP (ping) — rate limited
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# Log dropped packets
sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES-DROP: " --log-level 4

# Save rules
sudo iptables-save > /etc/iptables.rules
sudo iptables -L -v -n
```

### 4. Firewalld (Alternative — RHEL/Amazon Linux)
```bash
sudo systemctl enable --now firewalld

# Configure zones
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --remove-service=ssh   # Remove default 22

# Rate-limit SSH
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" service name="ssh" limit value="3/m" accept'

sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

## Validation Checklist
- [ ] SSH runs on non-default port (2222)
- [ ] Root login disabled, key-only auth enforced
- [ ] Fail2ban bans after 3 failed attempts
- [ ] Firewall blocks all except SSH (2222), HTTP (80), HTTPS (443)
- [ ] Dropped packets are logged
- [ ] Can still connect via SSH on new port
