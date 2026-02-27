# Task 5 — Install Nginx & Troubleshoot Service Issues

## Objective
Install and configure Nginx web server. Practice troubleshooting using logs, systemctl, and common debugging commands.

## Steps

### 1. Install Nginx
```bash
# Amazon Linux 2023
sudo yum install -y nginx

# Ubuntu
# sudo apt update && sudo apt install -y nginx

# Start and enable
sudo systemctl enable --now nginx
sudo systemctl status nginx

# Verify
curl -I http://localhost
```

### 2. Configure Nginx
```bash
# Create application config
sudo tee /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name app.example.com;

    root /var/www/app;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/app-access.log;
    error_log /var/log/nginx/app-error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Create web root
sudo mkdir -p /var/www/app
echo "<h1>Hello from hardened EC2</h1>" | sudo tee /var/www/app/index.html

# Test config and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Troubleshooting Scenarios

#### Scenario A: Nginx won't start
```bash
# Check status and journal
sudo systemctl status nginx
sudo journalctl -u nginx --no-pager -n 50

# Check for config errors
sudo nginx -t

# Check for port conflicts
sudo ss -tlnp | grep -E ':80|:443'
sudo lsof -i :80

# Check permissions
ls -la /var/www/app/
namei -l /var/www/app/index.html
```

#### Scenario B: 502 Bad Gateway
```bash
# Check if backend is running
sudo ss -tlnp | grep :3000

# Check error logs
sudo tail -f /var/log/nginx/app-error.log

# Check SELinux (if enabled)
sudo getenforce
sudo setsebool -P httpd_can_network_connect 1
```

#### Scenario C: Permission Denied (403)
```bash
# Check file ownership and permissions
ls -la /var/www/app/
sudo chown -R nginx:nginx /var/www/app/
sudo chmod -R 755 /var/www/app/

# Check nginx user in config
grep -i "^user" /etc/nginx/nginx.conf
```

#### Scenario D: High CPU / Memory Usage
```bash
# Monitor Nginx processes
top -p $(pgrep -d',' nginx)
ps aux | grep nginx

# Check connections
sudo ss -s
sudo ss -tlnp | grep nginx

# Check Nginx status (requires stub_status module)
curl http://localhost/nginx_status
```

### 4. Log Analysis
```bash
# Real-time log monitoring
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Top 10 IPs hitting the server
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# HTTP status code distribution
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Find 5xx errors
grep " 5[0-9][0-9] " /var/log/nginx/access.log

# Requests per minute
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f1-3 | sort | uniq -c | sort -rn | head -10
```

## Validation Checklist
- [ ] Nginx installed and running on port 80
- [ ] Custom server block configured with security headers
- [ ] Proxy pass configured for backend API
- [ ] Can identify and fix config syntax errors
- [ ] Can troubleshoot 502, 403, and port conflict issues
- [ ] Can analyze access logs for traffic patterns
