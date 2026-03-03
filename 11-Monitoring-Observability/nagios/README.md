# Nagios — Continuous Monitoring# Nagios — Continuous Monitoring
























































































































































































































































































































































































































































































































































































































   → Nagios: traditional infrastructure, simple host/service monitoring. Prometheus: cloud-native, Kubernetes, pull-based metrics with powerful PromQL queries. Prometheus is the modern standard for containerized environments.8. **Nagios vs Prometheus — when to use which?**   → Any script (Bash, Python, Perl) that outputs a status line and exits with code 0-3. Format: "STATUS - message | performance_data". Place in plugins directory, register in NRPE config.7. **How do you write a custom Nagios plugin?**   → 0=OK (green), 1=WARNING (yellow), 2=CRITICAL (red), 3=UNKNOWN (grey). Plugins MUST return one of these. State changes trigger notifications.6. **What are the four Nagios return codes?**   → Define a host, define a service with a check_command, configure check intervals and thresholds. For remote services: install NRPE + plugin on host, add NRPE command definition.5. **How do you monitor a service in Nagios?**   → Active: Nagios initiates the check (pull model). Passive: external process sends results to Nagios (push model). Passive used for firewalled hosts or event-driven monitoring.4. **Active vs Passive checks — difference?**   → Nagios Remote Plugin Executor. Agent installed on monitored hosts that executes local check plugins on behalf of the Nagios server. Enables monitoring of local resources (CPU, memory, disk) from a central Nagios server.3. **What are NRPE plugins?**   → Nagios Core (scheduler) runs check plugins periodically. Plugins return exit codes (0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN). For remote checks, NRPE agent runs plugins locally and returns results.2. **Explain Nagios architecture.**   → Open-source infrastructure monitoring tool. Monitors hosts (servers) and services (CPU, disk, HTTP, etc.) using plugins. Sends notifications on state changes.1. **What is Nagios?**## Interview Questions---```echo "[$(date +%s)] SCHEDULE_HOST_DOWNTIME;web-01;$(date +%s);$(($(date +%s)+3600));1;0;0;admin;Maintenance window" > /usr/local/nagios/var/rw/nagios.cmd# Schedule a downtime (via web interface or external command)tail -f /usr/local/nagios/var/nagios.log# Tail Nagios logsudo systemctl status nagios# View Nagios status/usr/local/nagios/libexec/check_nrpe -H <HOST_IP> -c check_load# Run a remote check manually/usr/local/nagios/libexec/check_nrpe -H <HOST_IP># Check NRPE connectivitysudo systemctl restart nagios# Restart Nagios (after config changes)/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg# Verify configuration```bash## Important Nagios Commands---```# View alert history in Nagios web interface# Test notification by triggering a CRITICAL state# Configure email notifications# Add service definition on Nagios server# Register as NRPE command on remote host# Write a custom check script (e.g., check_app_health.sh)```bash### Lab 3: Create Custom Plugins and Notifications```# Trigger a WARNING (fill disk) and observe alerts# Verify remote checks appear in web interface# Add host and service definitions on Nagios server# Configure NRPE allowed_hosts and commands# Install NRPE + plugins on remote host# Launch second EC2 instance```bash### Lab 2: Monitor Remote Server with NRPE```# Explore default checks (HTTP, SSH, ping, disk, load)# Verify localhost monitoring works# Access web interface# Install Nagios Core + Plugins# Launch EC2 instance (t3.small, Ubuntu)```bash### Lab 1: Install Nagios on EC2## Labs---| **Best for** | Traditional infrastructure | Cloud-native/containers | AWS-centric || **Setup** | Complex | Moderate (Helm chart) | Easy (managed) || **Kubernetes** | Limited | Native support | Container Insights || **Cost** | Free (open source) | Free (open source) | Pay per metric/alarm || **Scale** | 100s of hosts | 1000s of hosts | Unlimited (managed) || **Visualization** | Basic web UI | Grafana dashboards | CW Dashboards || **Alerting** | Built-in notifications | AlertManager | CloudWatch Alarms || **Architecture** | Agent-based (NRPE) | Pull-based (exporters) | Agent (CW Agent) || **Type** | Infrastructure monitoring | Metrics + visualization | AWS-native monitoring ||---------|--------|---------------------|------------|| Feature | Nagios | Prometheus + Grafana | CloudWatch |## Nagios vs Modern Alternatives---```command[check_uptime]=/usr/lib/nagios/plugins/check_uptime -w 30 -c 7# Uptimecommand[check_connections]=/usr/lib/nagios/plugins/check_tcp -H localhost -p 80 -w 2 -c 5# Network connectionscommand[check_nginx_proc]=/usr/lib/nagios/plugins/check_procs -c 1: -C nginx# Specific process running (e.g., nginx)command[check_zombie]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z# Zombie processescommand[check_procs]=/usr/lib/nagios/plugins/check_procs -w 300 -c 500# Total processescommand[check_swap]=/usr/lib/nagios/plugins/check_swap -w 50% -c 80%# Swap (warning at 50% used, critical at 80%)command[check_disk_data]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /datacommand[check_disk_root]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /# Disk (warning at 80% used, critical at 90%)command[check_mem]=/usr/lib/nagios/plugins/check_mem.pl -w 80 -c 90# Memory (warning 80%, critical 90%)command[check_load]=/usr/lib/nagios/plugins/check_load -r -w 0.70,0.60,0.50 -c 0.90,0.80,0.70# CPU (per-CPU load: warning 70%, critical 90%)# On remote host (/etc/nagios/nrpe.cfg):```bash**Scenario:** Comprehensive system monitoring with custom thresholds.## Real-Time Example 3: Monitoring System Info Using NRPE Plugins---```}    check_command           check_nrpe!check_redis    service_description     Redis    host_name               cache-01    use                     generic-servicedefine service {# command[check_redis]=/usr/lib/nagios/plugins/check_tcp -H localhost -p 6379# Redis monitoring}    check_command           check_nrpe!check_mysql    service_description     MySQL Status    host_name               db-01    use                     generic-servicedefine service {# command[check_mysql]=/usr/lib/nagios/plugins/check_mysql -H localhost -u nagios -p pass# On remote host nrpe.cfg:# MySQL monitoring via NRPE}    check_command           check_http!-u /api/health -w 2 -c 5    service_description     HTTP Response Time    host_name               web-01    use                     generic-servicedefine service {# HTTP monitoring```cfg## Real-Time Example 2: Monitor Services (HTTP, MySQL, Redis)---```}    check_command           check_nrpe!check_disk    service_description     Disk Space    hostgroup_name          aws-web-servers    use                     generic-servicedefine service {}    check_command           check_nrpe!check_mem    service_description     Memory    hostgroup_name          aws-web-servers    use                     generic-servicedefine service {}    check_command           check_nrpe!check_load    service_description     CPU Load    hostgroup_name          aws-web-servers    use                     generic-servicedefine service {# Apply services to host group}    address     10.0.1.11    host_name   web-02    use         aws-ec2-hostdefine host {}    address     10.0.1.10    host_name   web-01    use         aws-ec2-hostdefine host {# Individual hosts inherit from template}    contact_groups          devops-team    notification_period     24x7    check_period            24x7    max_check_attempts      5    register                0           # template, don't register    use                     linux-server    name                    aws-ec2-hostdefine host {# Define all web servers using a template```cfg**Scenario:** Monitor 10 EC2 instances: CPU, memory, disk, and application health.## Real-Time Example 1: Monitor AWS EC2 Fleet---```fi    exit 3    echo "UNKNOWN - Unexpected response (HTTP $RESPONSE)"else    exit 2    echo "CRITICAL - Application not responding"elif [ -z "$RESPONSE" ] || [ "$RESPONSE" == "000" ]; then    exit 1    echo "WARNING - Application degraded (HTTP $RESPONSE)"elif [ "$RESPONSE" == "503" ]; then    exit 0    echo "OK - Application is healthy (HTTP $RESPONSE)"if [ "$RESPONSE" == "200" ]; thenRESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)# Custom plugin to check application health endpoint# /usr/lib/nagios/plugins/check_app_health.sh#!/bin/bash```bash### Custom Plugin (Bash Script)```/usr/lib/nagios/plugins/check_ping -H 10.0.1.50 -w 100.0,20% -c 500.0,60%# Check ping/usr/lib/nagios/plugins/check_ssh -H 10.0.1.50# Check SSH/usr/lib/nagios/plugins/check_tcp -H 10.0.1.50 -p 8080# Check TCP port/usr/lib/nagios/plugins/check_mysql -H localhost -u nagios -p password# Check MySQL/usr/lib/nagios/plugins/check_http -H www.example.com -u /health -e 200# Check HTTP response/usr/lib/nagios/plugins/check_procs -w 250 -c 400# Check running processes/usr/lib/nagios/plugins/check_load -r -w 0.70,0.60,0.50 -c 0.90,0.80,0.70# Check CPU load (1/5/15 min averages)/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /# Check disk space (warning at 20% free, critical at 10%)```bash### Standard Plugins## NRPE Plugins Deep Dive---```cfg_dir=/usr/local/nagios/etc/objects/servers# Or include directory:cfg_file=/usr/local/nagios/etc/objects/web-services.cfgcfg_file=/usr/local/nagios/etc/objects/web-servers.cfg# Add at the bottom:# /usr/local/nagios/etc/nagios.cfg```cfg### Include Config Files```}    members             nagiosadmin,devops-lead    alias               Nagios Administrators    contactgroup_name   adminsdefine contactgroup {}    host_notification_commands      notify-host-by-email    service_notification_commands   notify-service-by-email    email                           devops-lead@company.com    alias                           DevOps Team Lead    use                             generic-contact    contact_name                    devops-leaddefine contact {# /usr/local/nagios/etc/objects/contacts.cfg```cfg### Contact and Notification```}    max_check_attempts      3    retry_interval          1    check_interval          2    check_command           check_tcp!8080    service_description     App Port 8080    host_name               web-server-01    use                     generic-servicedefine service {# Custom port check}    max_check_attempts      3    retry_interval          1    check_interval          2    check_command           check_http    service_description     HTTP    host_name               web-server-01    use                     generic-servicedefine service {# HTTP Service (checked from Nagios server — no NRPE needed)}    max_check_attempts      3    retry_interval          1    check_interval          5    check_command           check_nrpe!check_mem    service_description     Memory Usage    host_name               web-server-01    use                     generic-servicedefine service {# Memory Usage}    max_check_attempts      3    retry_interval          5    check_interval          15    check_command           check_nrpe!check_disk    service_description     Disk Usage    host_name               web-server-01    use                     generic-servicedefine service {# Disk Usage}    contact_groups          admins    notification_interval   30    max_check_attempts      3    retry_interval          1    check_interval          5    check_command           check_nrpe!check_load    service_description     CPU Load    host_name               web-server-01    use                     generic-servicedefine service {# CPU Load# /usr/local/nagios/etc/objects/web-services.cfg```cfg### Service Definitions (via NRPE)```}    members         web-server-01,web-server-02    alias           Web Servers    hostgroup_name  web-serversdefine hostgroup {# Host Group}    contact_groups          admins    notification_period     24x7    notification_interval   30    check_period            24x7    max_check_attempts      5    address                 10.0.1.51    alias                   Production Web Server 2    host_name               web-server-02    use                     linux-serverdefine host {}    contact_groups          admins    notification_period     24x7    notification_interval   30    check_period            24x7    max_check_attempts      5    address                 10.0.1.50    alias                   Production Web Server 1    host_name               web-server-01    use                     linux-serverdefine host {# /usr/local/nagios/etc/objects/web-servers.cfg```cfg### Host Definition## Configuration Files---```# Should return: NRPE v4.1.0/usr/local/nagios/libexec/check_nrpe -H <REMOTE_HOST_IP># Test NRPE connectionsudo make install-pluginmake check_nrpe./configurecd nrpe-4.1.0tar xzf nrpe-4.1.0.tar.gzwget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gzcd /tmp# On Nagios server:```bash### Step 3: Install NRPE Plugin on Nagios Server```sudo systemctl enable nagios-nrpe-serversudo systemctl restart nagios-nrpe-server# Restart NRPEcommand[check_mem]=/usr/lib/nagios/plugins/check_mem.pl -w 80 -c 90command[check_procs]=/usr/lib/nagios/plugins/check_procs -w 250 -c 400command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /command[check_load]=/usr/lib/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10# Define local checksallowed_hosts=127.0.0.1,<NAGIOS_SERVER_IP># Allow Nagios server IPsudo nano /etc/nagios/nrpe.cfg# Configure NRPEsudo apt-get install -y nagios-nrpe-server nagios-plugins# On monitored server (agent):```bash### Step 2: Install NRPE on Remote Hosts```# Login: nagiosadmin / <password you set># Access: http://<EC2-PUBLIC-IP>/nagiossudo systemctl restart apache2sudo systemctl start nagiossudo systemctl enable nagios# Start Nagiossudo make installmake./configure --with-nagios-user=nagios --with-nagios-group=nagioscd nagios-plugins-2.4.8tar xzf nagios-plugins-2.4.8.tar.gzwget https://nagios-plugins.org/download/nagios-plugins-2.4.8.tar.gzcd /tmp# Install Nagios Pluginssudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin# Set Nagios web admin passwordsudo make install-webconfsudo make install-commandmodesudo make install-configsudo make install-initsudo make installmake all./configure --with-command-group=nagcmdcd nagios-4.5.0tar xzf nagios-4.5.0.tar.gzwget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.0/nagios-4.5.0.tar.gzcd /tmp# Download and compile Nagios Coresudo usermod -a -G nagcmd www-datasudo usermod -a -G nagcmd nagiossudo groupadd nagcmdsudo useradd nagios# Create Nagios user    unzip apache2 php libapache2-mod-php php-gdsudo apt-get install -y build-essential libgd-dev openssl libssl-dev \sudo apt-get update# ---- Ubuntu 22.04 ----# Launch EC2 (Amazon Linux 2 / Ubuntu, t3.small minimum)```bash### Step 1: Install Nagios Core## Installing Nagios on AWS---| 3 | **UNKNOWN** | Plugin error or invalid check || 2 | **CRITICAL** | Problem requires immediate attention || 1 | **WARNING** | Approaching threshold || 0 | **OK** | Everything is fine ||------|-------|---------|| Code | State | Meaning |### Check Return Codes| **Service Group** | Logical grouping of services (critical-services) || **Host Group** | Logical grouping of hosts (web-servers, db-servers) || **Time Period** | When checks run and notifications are sent || **Notification** | Alert sent when state changes (OK→WARNING→CRITICAL) || **Contact** | Person/group to notify when issues occur || **NRPE** | Agent on remote hosts that executes local plugins || **Plugin** | Script that performs the actual check (returns 0-3 exit code) || **Service** | A specific check on a host (CPU, disk, HTTP, MySQL) || **Host** | A device (server, router, printer) being monitored ||---------|-------------|| Concept | Description |## Key Concepts---```- check_http, check_tcp — network service checks (no agent)- SNMP — network device monitoring- SSH — run plugins over SSH (no agent needed)  - NRPE (Nagios Remote Plugin Executor) — agent on remote hostRemote checks via:2. PASSIVE: Hosts send results to Nagios (push)1. ACTIVE: Nagios server runs checks (pull)Two monitoring methods:└────────┘ └────────┘      └────────────┘│ Agent   │ │ Agent   │      │ Agent      ││ NRPE   │ │ NRPE   │ ... │ NRPE       ││        │ │        │      │            ││Host 1  │ │Host 2  │      │Host N      │┌────────┐ ┌────────┐      ┌────────────┐     ▼     ▼                      ▼     │     │                      │     ┌─────┼──────────────────────┐           │└──────────┼───────────────────────────────────────┘│          │           └────────────────┘           ││          │           │  Slack, PD)    │           ││  └───────┬───────┘  │ (email, SMS,   │           ││  │  (check_*)    │  │ Engine         │           ││  │  Plugins      │  │ Notification   │           ││  ┌───────▼───────┐  ┌────────────────┐           ││          │                                        ││  └───────┬───────┘  └────────────────┘           ││  │  (scheduler)   │  │ (Apache/PHP)   │           ││  │  Nagios Core   │  │ Web Interface  │           ││  ┌───────────────┐  ┌────────────────┐           ││                                                   ││                NAGIOS SERVER                      │┌─────────────────────────────────────────────────┐```## Nagios Architecture---- History is logged for trend analysis- Nurses (admins) are notified immediately- Alarms go off when thresholds are breached- Dashboard shows green (OK), yellow (WARNING), red (CRITICAL)- Sensors (plugins) continuously check vital signs (CPU, memory, disk, services)Nagios is like a **hospital patient monitor**:## Real-World Analogy---> Open-source infrastructure monitoring. Monitor servers, networks, services, and applications. Alert when things go wrong, notify when they're fixed.
> Open-source infrastructure monitoring. Monitor servers, networks, services, and applications. Alert when things go wrong. The "watchman" of your infrastructure.

---

## Real-World Analogy

Nagios is like a **security guard monitoring CCTV cameras**:
- Each camera (check/plugin) watches a specific area (server/service)
- The guard (Nagios core) watches all screens simultaneously
- If something suspicious happens (threshold breached), the guard raises an alarm (alert)
- NRPE (remote checks) = cameras in remote locations connected back to the control room
- You define what's "suspicious" (warning/critical thresholds)

---

## Nagios vs Prometheus/Grafana

| Feature | Nagios | Prometheus + Grafana |
|---------|--------|---------------------|
| **Architecture** | Agent-based (NRPE) or agentless (SNMP) | Pull-based (HTTP scrape) |
| **Configuration** | Config files (.cfg) | YAML (prometheus.yml) |
| **Alerting** | Built-in (email, SMS, scripts) | AlertManager (separate) |
| **Dashboards** | Basic (Nagios XI) | Rich (Grafana) |
| **Metrics storage** | RRD / flat files | Time-series DB (TSDB) |
| **Service discovery** | Static config | Dynamic (Kubernetes, EC2, etc.) |
| **Learning curve** | Moderate | Moderate-steep (PromQL) |
| **Best for** | Traditional infrastructure monitoring | Cloud-native, Kubernetes |
| **Cost** | Free (Core) / Paid (XI) | Free (both open-source) |

> **Note:** Nagios is widely used in traditional infrastructure. For cloud-native/Kubernetes environments, Prometheus + Grafana is the modern standard (covered in [11-Monitoring-Observability](../../11-Monitoring-Observability/README.md)).

---

## Nagios Architecture

```
                    ┌──────────────────────────────┐
                    │        Nagios Server          │
                    │                               │
                    │  ┌───────────┐  ┌──────────┐ │
                    │  │  Nagios   │  │ Web UI   │ │
                    │  │  Core     │  │ (CGI/    │ │
                    │  │  Engine   │  │  PHP)    │ │
                    │  └─────┬─────┘  └──────────┘ │
                    │        │                      │
                    │  ┌─────▼─────┐               │
                    │  │  Plugins  │               │
                    │  │  check_*  │               │
                    │  └─────┬─────┘               │
                    └────────┼──────────────────────┘
                             │
            ┌────────────────┼──────────────────┐
            │                │                  │
     Local Checks     NRPE (Remote)      SNMP / SSH
            │                │                  │
    ┌───────▼──────┐  ┌─────▼──────┐  ┌──────▼──────┐
    │ Nagios Server │  │ Linux Host │  │ Network     │
    │ (disk, CPU,  │  │ (NRPE      │  │ Device      │
    │  memory)     │  │  agent)    │  │ (router,    │
    └──────────────┘  └────────────┘  │  switch)    │
                                      └─────────────┘

    Check Cycle:
    1. Nagios runs check_* plugin every N minutes
    2. Plugin returns: 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
    3. If state changes → send notification (email/SMS/Slack)
    4. Log result for reporting
```

---

## Installing Nagios on AWS (Amazon Linux 2)

```bash
# Launch EC2 instance (t3.small minimum)
# Security Group: allow port 80 (HTTP), 22 (SSH)

# Install prerequisites
sudo yum install -y gcc glibc glibc-common make gettext automake autoconf \
    wget openssl-devel net-snmp net-snmp-utils epel-release \
    perl-Net-SNMP httpd php gd gd-devel unzip

# Create nagios user and group
sudo useradd nagios
sudo groupadd nagcmd
sudo usermod -aG nagcmd nagios
sudo usermod -aG nagcmd apache

# Download and compile Nagios Core
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.1.tar.gz
tar xzf nagios-4.5.1.tar.gz
cd nagios-4.5.1

./configure --with-command-group=nagcmd
make all
sudo make install
sudo make install-init
sudo make install-config
sudo make install-commandmode
sudo make install-webconf

# Set web admin password
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Install Nagios Plugins
cd /tmp
wget https://nagios-plugins.org/download/nagios-plugins-2.4.8.tar.gz
tar xzf nagios-plugins-2.4.8.tar.gz
cd nagios-plugins-2.4.8
./configure
make
sudo make install

# Start Nagios
sudo systemctl start nagios
sudo systemctl enable nagios
sudo systemctl start httpd
sudo systemctl enable httpd

# Verify configuration
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Access web UI: http://EC2_PUBLIC_IP/nagios
# Login: nagiosadmin / (password you set)
```

---

## Nagios Configuration Files

```
/usr/local/nagios/etc/
├── nagios.cfg              # Main config (what config files to load)
├── cgi.cfg                 # Web interface config
├── resource.cfg            # Macros ($USER1$ = plugin path)
├── objects/
│   ├── commands.cfg        # Command definitions (how to run checks)
│   ├── contacts.cfg        # Who to notify
│   ├── timeperiods.cfg     # When to monitor/notify
│   ├── templates.cfg       # Templates for hosts/services
│   ├── localhost.cfg       # Local host monitoring
│   └── servers/            # Remote host definitions (custom)
│       ├── web-server.cfg
│       └── db-server.cfg
```

### Define a Host
```cfg
# /usr/local/nagios/etc/objects/servers/web-server.cfg

define host {
    use                     linux-server        ; Template
    host_name               web-server-01
    alias                   Production Web Server
    address                 10.0.1.50
    max_check_attempts      5
    check_period            24x7
    notification_interval   30
    notification_period     24x7
    contact_groups          devops-team
}
```

### Define Services
```cfg
# Monitor HTTP
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     HTTP
    check_command           check_http
    check_interval          5          ; Every 5 minutes
    retry_interval          1          ; Retry every 1 minute on failure
    max_check_attempts      3
    notification_interval   30
    contact_groups          devops-team
}

# Monitor SSH
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     SSH
    check_command           check_ssh
    check_interval          5
}

# Monitor disk usage (via NRPE)
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     Disk Usage
    check_command           check_nrpe!check_disk
}

# Monitor CPU load (via NRPE)
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     CPU Load
    check_command           check_nrpe!check_load
}

# Monitor memory (via NRPE)
define service {
    use                     generic-service
    host_name               web-server-01
    service_description     Memory Usage
    check_command           check_nrpe!check_mem
}
```

### Define Commands
```cfg
# /usr/local/nagios/etc/objects/commands.cfg

# NRPE check command
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}

# HTTP with custom URL
define command {
    command_name    check_http_url
    command_line    $USER1$/check_http -H $HOSTADDRESS$ -u $ARG1$ -w $ARG2$ -c $ARG3$
}
```

### Define Contacts
```cfg
# /usr/local/nagios/etc/objects/contacts.cfg

define contact {
    contact_name            admin
    alias                   DevOps Admin
    email                   admin@company.com
    service_notification_period     24x7
    host_notification_period        24x7
    service_notification_options    w,u,c,r    ; Warning, Unknown, Critical, Recovery
    host_notification_options       d,u,r      ; Down, Unreachable, Recovery
    service_notification_commands   notify-service-by-email
    host_notification_commands      notify-host-by-email
}

define contactgroup {
    contactgroup_name       devops-team
    alias                   DevOps Team
    members                 admin
}
```

---

## NRPE — Nagios Remote Plugin Executor

NRPE runs plugins on remote hosts and returns results to the Nagios server.

```
Nagios Server                    Remote Host
┌──────────────┐    TCP 5666    ┌──────────────┐
│ check_nrpe   │───────────────▶│  NRPE Daemon │
│ plugin       │◀───────────────│  runs local  │
│              │    result      │  check_*     │
└──────────────┘                │  plugins     │
                                └──────────────┘
```

### Install NRPE on Remote Host (Agent)
```bash
# On the monitored server:
sudo yum install -y gcc glibc glibc-common openssl-devel
cd /tmp

# Install Nagios Plugins
wget https://nagios-plugins.org/download/nagios-plugins-2.4.8.tar.gz
tar xzf nagios-plugins-2.4.8.tar.gz
cd nagios-plugins-2.4.8 && ./configure && make && sudo make install

# Install NRPE
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gz
tar xzf nrpe-4.1.0.tar.gz
cd nrpe-4.1.0
./configure
make all
sudo make install
sudo make install-config
sudo make install-init

# Configure NRPE
sudo vi /usr/local/nagios/etc/nrpe.cfg
# Set: allowed_hosts=127.0.0.1,NAGIOS_SERVER_IP
# Define commands:
# command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10%
# command[check_load]=/usr/local/nagios/libexec/check_load -w 5.0,4.0,3.0 -c 10.0,6.0,4.0
# command[check_mem]=/usr/local/nagios/libexec/check_swap -w 20% -c 10%
# command[check_procs]=/usr/local/nagios/libexec/check_procs -w 250 -c 400

# Start NRPE
sudo systemctl start nrpe
sudo systemctl enable nrpe

# Test from Nagios server
/usr/local/nagios/libexec/check_nrpe -H REMOTE_HOST_IP
/usr/local/nagios/libexec/check_nrpe -H REMOTE_HOST_IP -c check_disk
```

---

## Monitoring System Info with NRPE Plugins

| Plugin | Checks | Warning | Critical |
|--------|--------|---------|----------|
| `check_disk` | Disk space usage | < 20% free | < 10% free |
| `check_load` | CPU load average | 5.0,4.0,3.0 | 10.0,6.0,4.0 |
| `check_swap` | Swap usage | > 20% used | > 50% used |
| `check_procs` | Running processes | > 250 | > 400 |
| `check_users` | Logged-in users | > 5 | > 10 |
| `check_http` | HTTP response | > 2s response | > 5s or down |
| `check_ssh` | SSH connectivity | — | Connection refused |
| `check_mysql` | MySQL connectivity | — | Connection failed |
| `check_tcp` | TCP port check | > 1s response | Port closed |

```bash
# Custom NRPE check examples
# Check if nginx is running
command[check_nginx]=/usr/local/nagios/libexec/check_procs -c 1: -C nginx

# Check application port
command[check_app_port]=/usr/local/nagios/libexec/check_tcp -H 127.0.0.1 -p 8080 -w 2 -c 5

# Check log file for errors (last 5 min)
command[check_app_errors]=/usr/local/nagios/libexec/check_log -F /var/log/myapp/error.log -O /tmp/old_error.log -q "ERROR"
```

---

## Real-Time Example 1: Monitor Production Web Server

**Scenario:** Monitor an Nginx web server for HTTP response, SSL certificate, disk space, CPU, and memory.

```cfg
define host {
    use                     linux-server
    host_name               prod-web-01
    address                 10.0.1.50
    contact_groups          devops-team
}

# HTTP check (response time)
define service {
    use                     generic-service
    host_name               prod-web-01
    service_description     HTTP Response
    check_command           check_http!-u /health -w 2 -c 5
}

# HTTPS + SSL certificate expiry
define service {
    use                     generic-service
    host_name               prod-web-01
    service_description     SSL Certificate
    check_command           check_http!-S -C 30,14
    ; Warn at 30 days, Critical at 14 days before expiry
}

# Disk, CPU, Memory via NRPE
define service {
    use                     generic-service
    host_name               prod-web-01
    service_description     Disk Usage
    check_command           check_nrpe!check_disk
}

define service {
    use                     generic-service
    host_name               prod-web-01
    service_description     CPU Load
    check_command           check_nrpe!check_load
}
```

---

## Real-Time Example 2: Multi-Server Monitoring Dashboard

**Scenario:** Monitor 5 servers: 2 web servers, 2 app servers, 1 database server.

```cfg
# Host group for organized viewing
define hostgroup {
    hostgroup_name      web-servers
    alias               Web Servers
    members             web-01,web-02
}

define hostgroup {
    hostgroup_name      app-servers
    alias               Application Servers
    members             app-01,app-02
}

define hostgroup {
    hostgroup_name      db-servers
    alias               Database Servers
    members             db-01
}

# Service group for cross-host service monitoring
define servicegroup {
    servicegroup_name   http-services
    alias               HTTP Services
    members             web-01,HTTP,web-02,HTTP
}

# Apply services to hostgroups
define service {
    use                     generic-service
    hostgroup_name          web-servers
    service_description     HTTP
    check_command           check_http
}

define service {
    use                     generic-service
    hostgroup_name          db-servers
    service_description     MySQL
    check_command           check_nrpe!check_mysql
}
```

---

## Labs

### Lab 1: Install Nagios on EC2
```bash
# Launch EC2 instance (Amazon Linux 2, t3.small)
# Install Nagios Core from source
# Install Nagios Plugins
# Set nagiosadmin password
# Start services (nagios + httpd)
# Access web UI at http://EC2_IP/nagios
# Verify localhost monitoring is working
```

### Lab 2: Monitor a Remote Server with NRPE
```bash
# Launch a second EC2 instance (the monitored server)
# Install NRPE + Nagios plugins on remote server
# Configure NRPE allowed_hosts to permit Nagios server
# Configure check commands (disk, load, procs)
# On Nagios server: add host and service definitions
# Restart Nagios, verify remote checks in web UI
```

### Lab 3: Set Up Alerts and Notifications
```bash
# Configure contact with email address
# Set up notification commands (email)
# Create host/service with notification enabled
# Simulate a failure (stop a service on remote host)
# Verify alert email received
# Fix the service → verify recovery notification
```

### Lab 4: Custom NRPE Plugins
```bash
# Write a custom check script on remote host
#!/bin/bash
# check_app_health.sh
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
if [ "$response" = "200" ]; then
    echo "OK - Application healthy"
    exit 0
elif [ "$response" = "503" ]; then
    echo "WARNING - Application degraded"
    exit 1
else
    echo "CRITICAL - Application down (HTTP $response)"
    exit 2
fi

# Register in NRPE config
# Add service definition on Nagios server
# Verify custom check works
```

---

## Interview Questions

1. **What is Nagios and what does it monitor?**
   → Open-source monitoring tool for servers, networks, services, and applications. Uses plugins to check host/service health. Alerts via email, SMS, or custom commands.

2. **Explain Nagios architecture.**
   → Nagios Core: scheduling engine + web UI. Plugins: check_* executables that test services. NRPE: runs plugins on remote hosts. Results: OK(0), WARNING(1), CRITICAL(2), UNKNOWN(3).

3. **What is NRPE?**
   → Nagios Remote Plugin Executor. An agent installed on monitored servers that runs check plugins locally and returns results to the Nagios server over TCP port 5666.

4. **How do Nagios plugins work?**
   → Plugins are executables that check a specific service/metric. They return an exit code (0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN) and a text message. Any script can be a plugin if it follows this convention.

5. **What is the difference between active and passive checks?**
   → Active: Nagios initiates the check on schedule. Passive: external process sends results to Nagios (useful for distributed monitoring, SNMP traps, or checks behind firewalls).

6. **How does Nagios handle notifications?**
   → When a service changes state (e.g., OK→CRITICAL), Nagios runs notification commands for contacts in the contact_groups. Can filter by time period, notification options, and escalation levels.

7. **Nagios vs Prometheus — when to use which?**
   → Nagios: traditional infrastructure (bare metal, VMs), simple OK/WARN/CRIT model. Prometheus: cloud-native, Kubernetes, time-series metrics, powerful queries (PromQL). Modern setups prefer Prometheus.

8. **How do you add a new host to Nagios monitoring?**
   → 1) Install NRPE + plugins on remote host. 2) Define host object in cfg file. 3) Define service checks. 4) Add to nagios.cfg. 5) Restart Nagios. Verify in web UI.
