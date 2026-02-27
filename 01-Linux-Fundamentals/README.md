# Module 1 — Linux Fundamentals (1 Week)

> **Objective:** Master Linux administration on AWS EC2. Build a hardened, production-ready server from scratch.

---

## 🌍 Real-World Analogy: Linux is Like a Building

Think of a Linux server as a **commercial building**:

```
🏢 THE BUILDING (Linux Server)
│
├── 🧠 Foundation & Structure = KERNEL
│   The kernel is the building's foundation, walls, electricity, plumbing.
│   You don't see it, but nothing works without it.
│
├── 🚪 Reception Desk = SHELL (Bash)
│   You talk to the receptionist (shell) to get things done.
│   You don't go fix the plumbing yourself — you ask.
│   "Can you turn on AC in room 5?" = "systemctl start nginx"
│
├── 🗄️ Rooms & Floors = FILE SYSTEM (FHS)
│   /home     = Individual offices (each employee has their own)
│   /etc      = Admin office (all rules and configurations)
│   /var/log  = Security camera recordings (system logs)
│   /tmp      = Shared meeting room (temporary, cleaned daily)
│   /opt      = Storage room for extra equipment (optional software)
│
├── 🔑 Permissions = KEY CARD SYSTEM
│   Owner (rwx)  = The room's assigned employee (full access)
│   Group (r-x)  = The department team (can enter, can't modify)
│   Others (---)  = Visitors (no access at all)
│   "chmod 750" = "Give full access to owner, read+enter to team, none to visitors"
│
├── 👷 Processes = EMPLOYEES WORKING
│   Each running program is like an employee doing a task.
│   "ps aux" = Check who's currently working
│   "kill PID" = Fire an employee (stop a process)
│   "top" = Watch the office activity board in real-time
│
└── 🔥 Firewall = BUILDING SECURITY GUARD
    Controls who can enter (inbound) and leave (outbound).
    "Allow port 443" = "Let HTTPS visitors in through the front door"
    "Deny port 22 from 0.0.0.0" = "Don't let strangers use the back door"
```

### Why Linux for DevOps?
> **Real Example:** Netflix, Google, Amazon, Facebook — all run on Linux servers.
> When you open Netflix, your request hits a Linux server. That server needs someone to manage it — that's a DevOps engineer!

---

## Topics

### Linux Architecture
- Kernel, shell, file system hierarchy (FHS)
- Boot process: BIOS/UEFI → GRUB → Kernel → systemd
- Runlevels vs systemd targets

### 200 Essential Commands (Grouped by Category)

| Category | Commands |
|----------|----------|
| **File & Directory** | `ls, cd, cp, mv, rm, mkdir, find, locate, stat, file, tree, touch, ln, readlink, basename, dirname, realpath` |
| **Permissions** | `chmod, chown, chgrp, umask, getfacl, setfacl` |
| **Text Processing** | `cat, less, head, tail, grep, awk, sed, cut, sort, uniq, wc, tr, diff, tee, xargs, column, paste, join` |
| **Process Management** | `ps, top, htop, kill, killall, nice, renice, nohup, bg, fg, jobs, systemctl, journalctl, pgrep, pkill` |
| **Disk & Storage** | `df, du, mount, umount, lsblk, fdisk, mkfs, blkid, parted, tune2fs, e2fsck, xfs_repair` |
| **Networking** | `ip, ss, netstat, curl, wget, ping, traceroute, nslookup, dig, scp, rsync, nc, tcpdump, nmap` |
| **User Management** | `useradd, usermod, userdel, passwd, groupadd, groupdel, id, who, w, last, whoami, su, sudo, visudo` |
| **Package Management** | `apt, yum, dnf, rpm, dpkg, snap, pip` |
| **Archives** | `tar, gzip, gunzip, zip, unzip, bzip2, xz, zcat` |
| **System Info** | `uname, hostname, uptime, free, vmstat, iostat, dmesg, lscpu, lsof, strace, sar` |
| **Cron & Scheduling** | `crontab, at, batch, systemd timers` |
| **SSH & Security** | `ssh, ssh-keygen, ssh-copy-id, sshd_config, iptables, ufw, firewalld, fail2ban` |

---

## Practical Tasks

| # | Task | Description | Folder |
|---|------|-------------|--------|
| 1 | EC2 Setup & Exploration | Provision EC2, SSH in, explore FHS | [tasks/task-01-ec2-setup/](tasks/task-01-ec2-setup/) |
| 2 | Users & Permissions | Create users, groups, ACLs | [tasks/task-02-users-permissions/](tasks/task-02-users-permissions/) |
| 3 | Cron & Log Rotation | Automate log rotation + email alerts | [tasks/task-03-cron-log-rotation/](tasks/task-03-cron-log-rotation/) |
| 4 | Firewall & SSH Hardening | Configure iptables/ufw, harden SSH | [tasks/task-04-firewall-ssh/](tasks/task-04-firewall-ssh/) |
| 5 | Nginx & Troubleshooting | Install Nginx, troubleshoot via logs | [tasks/task-05-nginx-troubleshoot/](tasks/task-05-nginx-troubleshoot/) |

---

## Real-Time Project: EC2 Server Hardening & Automation

**[📁 Project Folder →](project-server-hardening/)**

### Architecture
```
Amazon Linux 2023 EC2 Instance
├── SSH hardened (key-only, non-default port, fail2ban)
├── Automated log rotation (logrotate + cron)
├── Disk monitoring with alerts (cron + SNS)
├── Firewall rules (iptables / firewalld)
└── Nginx configured & secured
```

### Deliverables
- Documented hardened server ready for application deployment
- Automation scripts for repeatable setup
- Security audit checklist (passed)

---

## Interview Questions
1. Explain the Linux boot process
2. Difference between hard link and soft link
3. How does `chmod 755` differ from `chmod 644`?
4. What is the difference between `ps aux` and `top`?
5. How to find files larger than 100MB modified in the last 7 days?
6. Explain iptables chains: INPUT, OUTPUT, FORWARD
7. How to troubleshoot a service that won't start?
8. What is the difference between `/etc/passwd` and `/etc/shadow`?
9. How does SSH key-based authentication work?
10. What is the sticky bit and when would you use it?
