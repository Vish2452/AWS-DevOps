# Server Hardening — Security Audit Checklist

## SSH Security
- [ ] SSH runs on non-default port (not 22)
- [ ] Root login is disabled (`PermitRootLogin no`)
- [ ] Password authentication is disabled
- [ ] Public key authentication is the only method
- [ ] Max authentication attempts limited to 3
- [ ] Login grace time set to 30 seconds
- [ ] Idle timeout configured (ClientAliveInterval)
- [ ] SSH banner displays warning message
- [ ] Only authorized users whitelisted (AllowUsers)
- [ ] X11 and TCP forwarding disabled

## Firewall
- [ ] Default INPUT policy is DROP
- [ ] Default FORWARD policy is DROP
- [ ] Only required ports are open (SSH, HTTP, HTTPS)
- [ ] SSH has rate limiting (max 4 attempts per minute)
- [ ] ICMP is rate-limited
- [ ] Dropped packets are logged
- [ ] Rules persist across reboots

## Brute-Force Protection
- [ ] Fail2ban is installed and running
- [ ] SSH jail configured (3 retries, 2-hour ban)
- [ ] Log monitoring path is correct

## Logging & Monitoring
- [ ] Logrotate configured for application logs
- [ ] Disk usage monitored (threshold: 80%)
- [ ] Alerts configured (SNS or email)
- [ ] Cron jobs scheduled for automated tasks
- [ ] System logs are being captured (/var/log/secure, /var/log/messages)

## System Hardening
- [ ] System packages updated to latest versions
- [ ] Unnecessary services disabled
- [ ] File system limits configured (nofile, nproc)
- [ ] Swap configured
- [ ] Timezone set to UTC

## Web Server (Nginx)
- [ ] Security headers configured (X-Frame-Options, X-Content-Type-Options)
- [ ] Hidden files access denied
- [ ] Access and error logs configured
- [ ] Server tokens hidden (`server_tokens off`)

## AWS-Specific
- [ ] Security Group allows only required ports
- [ ] IAM role attached (no access keys on instance)
- [ ] EBS volumes encrypted
- [ ] Instance metadata v2 enforced (IMDSv2)
