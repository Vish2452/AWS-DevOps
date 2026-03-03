# Puppet — Configuration Management

> Declarative configuration management tool. Define desired server state using Puppet manifests. Agent-master architecture for managing infrastructure at scale.

---

## Real-World Analogy

Puppet is like a **strict building inspector**:
- You declare building codes (manifests) — "every room must have a fire exit"
- The inspector (Puppet agent) visits every building (node) regularly
- If a building violates the code, the inspector fixes it automatically
- You don't say "install the fire exit" — you say "a fire exit MUST exist"
- This is **declarative** — you describe the desired state, not the steps

---

## Puppet vs Ansible

| Feature | Puppet | Ansible |
|---------|--------|---------|
| **Architecture** | Agent-Master (pull-based) | Agentless (push-based) |
| **Language** | Puppet DSL (Ruby-based) | YAML (playbooks) |
| **Configuration** | Declarative | Procedural + Declarative |
| **Communication** | SSL certificates (auto-signed) | SSH (no agent needed) |
| **Execution** | Agent polls master every 30 min | On-demand (ad-hoc or scheduled) |
| **Learning Curve** | Steeper (custom DSL) | Easier (YAML) |
| **Idempotent** | Yes (by design) | Yes (most modules) |
| **State Reporting** | PuppetDB + Dashboard | Ansible Tower/AWX |
| **Best For** | Large infrastructure, continuous enforcement | Quick automation, smaller teams |

---

## Puppet Architecture

```
                     ┌────────────────────┐
                     │   Puppet Master    │
                     │                    │
                     │  ┌──────────────┐  │
                     │  │  Manifests   │  │
                     │  │  (.pp files) │  │
                     │  ├──────────────┤  │
                     │  │   Modules    │  │
                     │  │  (reusable)  │  │
                     │  ├──────────────┤  │
                     │  │  Hiera Data  │  │
                     │  │  (config)    │  │
                     │  └──────────────┘  │
                     └─────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │ SSL (8140)     │ SSL (8140)      │ SSL (8140)
              ▼                ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ Puppet Agent │  │ Puppet Agent │  │ Puppet Agent │
    │  (Node 1)    │  │  (Node 2)    │  │  (Node 3)    │
    │  Web Server  │  │  App Server  │  │  DB Server   │
    └──────────────┘  └──────────────┘  └──────────────┘

    Every 30 minutes:
    1. Agent sends "facts" (system info) to Master
    2. Master compiles catalog (desired state) for that node
    3. Agent applies catalog (installs packages, configures files, etc.)
    4. Agent reports results back to Master
```

---

## Setting Up Puppet Master-Agent on AWS

### Master Setup (EC2 - Amazon Linux 2)
```bash
# Launch EC2 instance for Puppet Master (t3.medium minimum)
# Set hostname
sudo hostnamectl set-hostname puppet-master
echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) puppet-master puppet" | sudo tee -a /etc/hosts

# Install Puppet Server
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum install -y puppetserver

# Configure memory (default 2GB, adjust for t3.medium)
sudo sed -i 's/2g/1g/g' /etc/sysconfig/puppetserver

# Start Puppet Server
sudo systemctl start puppetserver
sudo systemctl enable puppetserver

# Verify
sudo /opt/puppetlabs/bin/puppetserver --version
sudo systemctl status puppetserver
```

### Agent Setup (EC2 - Nodes)
```bash
# Launch EC2 instance(s) for Puppet Agents
# Set hostname
sudo hostnamectl set-hostname web-server-01

# Add master to hosts file
echo "MASTER_PRIVATE_IP puppet-master puppet" | sudo tee -a /etc/hosts

# Install Puppet Agent
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum install -y puppet-agent

# Configure agent to point to master
sudo /opt/puppetlabs/bin/puppet config set server puppet-master --section main

# Start agent (sends certificate request to master)
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

# On MASTER: sign agent certificate
sudo /opt/puppetlabs/bin/puppetserver ca list            # List pending requests
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname web-server-01  # Sign

# Test connection (on agent)
sudo /opt/puppetlabs/bin/puppet agent --test
```

---

## Puppet Manifests

Manifests are `.pp` files that define the desired state of resources.

### Basic Manifest Syntax
```puppet
# /etc/puppetlabs/code/environments/production/manifests/site.pp

# Node classification
node 'web-server-01' {
  include role::webserver
}

node 'db-server-01' {
  include role::database
}

# Default node (applies to unclassified nodes)
node default {
  include role::base
}
```

### Resource Types
```puppet
# Package — install software
package { 'nginx':
  ensure => installed,
}

# Service — manage services
service { 'nginx':
  ensure => running,
  enable => true,
  require => Package['nginx'],
}

# File — manage files and directories
file { '/etc/nginx/nginx.conf':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  source  => 'puppet:///modules/nginx/nginx.conf',
  notify  => Service['nginx'],
  require => Package['nginx'],
}

# Directory
file { '/var/www/myapp':
  ensure  => directory,
  owner   => 'www-data',
  group   => 'www-data',
  mode    => '0755',
  recurse => true,
}

# User — manage users
user { 'deploy':
  ensure     => present,
  uid        => '1001',
  gid        => 'deploy',
  home       => '/home/deploy',
  managehome => true,
  shell      => '/bin/bash',
}

# Group
group { 'deploy':
  ensure => present,
  gid    => '1001',
}

# Exec — run commands (use sparingly)
exec { 'apt-update':
  command     => '/usr/bin/apt-get update',
  refreshonly => true,
}

# Cron — manage cron jobs
cron { 'backup':
  command => '/usr/local/bin/backup.sh',
  user    => 'root',
  hour    => '2',
  minute  => '0',
}
```

### Resource Relationships
```puppet
# require — A must exist before B
# before   — A is applied before B
# notify   — A notifies B to refresh (restart)
# subscribe — B subscribes to changes in A

package { 'nginx': ensure => installed }
  →  file { '/etc/nginx/nginx.conf': require => Package['nginx'], notify => Service['nginx'] }
      →  service { 'nginx': ensure => running, subscribe => File['/etc/nginx/nginx.conf'] }

# Arrow notation (ordering)
Package['nginx'] -> File['/etc/nginx/nginx.conf'] ~> Service['nginx']
#                ->  means "before"
#                ~>  means "notify" (triggers refresh)
```

---

## Puppet Modules

Modules are reusable units of Puppet code. Standard structure:

```
modules/
└── nginx/
    ├── manifests/
    │   ├── init.pp          # Main class (class nginx)
    │   ├── install.pp       # Package installation
    │   ├── config.pp        # Configuration
    │   └── service.pp       # Service management
    ├── files/
    │   └── nginx.conf       # Static files
    ├── templates/
    │   └── vhost.conf.erb   # ERB templates
    ├── lib/
    │   └── facter/          # Custom facts
    ├── examples/
    │   └── init.pp          # Usage examples
    └── metadata.json        # Module metadata
```

### Example Module: Nginx

```puppet
# modules/nginx/manifests/init.pp
class nginx (
  String $server_name = $facts['fqdn'],
  Integer $listen_port = 80,
  String $document_root = '/var/www/html',
) {
  contain nginx::install
  contain nginx::config
  contain nginx::service

  Class['nginx::install']
  -> Class['nginx::config']
  ~> Class['nginx::service']
}

# modules/nginx/manifests/install.pp
class nginx::install {
  package { 'nginx':
    ensure => installed,
  }
}

# modules/nginx/manifests/config.pp
class nginx::config {
  file { '/etc/nginx/sites-available/default':
    ensure  => file,
    content => template('nginx/vhost.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { $nginx::document_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }
}

# modules/nginx/manifests/service.pp
class nginx::service {
  service { 'nginx':
    ensure => running,
    enable => true,
  }
}
```

### ERB Template
```erb
# modules/nginx/templates/vhost.conf.erb
server {
    listen <%= @listen_port %>;
    server_name <%= @server_name %>;
    root <%= @document_root %>;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/<%= @server_name %>-access.log;
    error_log  /var/log/nginx/<%= @server_name %>-error.log;
}
```

---

## Puppet File Server

Puppet master includes a built-in file server for distributing files to agents.

```puppet
# Reference file from module's files/ directory
file { '/etc/app/config.yml':
  source => 'puppet:///modules/myapp/config.yml',
  # Puppet serves this from:
  # /etc/puppetlabs/code/environments/production/modules/myapp/files/config.yml
}

# Custom file server mount points
# /etc/puppetlabs/puppet/fileserver.conf
[custom_files]
  path /opt/puppet-files
  allow *

# Usage in manifest:
file { '/etc/app/data.dat':
  source => 'puppet:///custom_files/data.dat',
}
```

---

## Hiera — Data Separation

```yaml
# /etc/puppetlabs/puppet/hiera.yaml
---
version: 5
hierarchy:
  - name: "Per-node data"
    path: "nodes/%{trusted.certname}.yaml"
  - name: "Per-environment"
    path: "environments/%{environment}.yaml"
  - name: "Common data"
    path: "common.yaml"

# data/common.yaml
nginx::listen_port: 80
nginx::document_root: '/var/www/html'

# data/nodes/web-server-01.yaml
nginx::listen_port: 8080
nginx::server_name: 'production.myapp.com'
```

---

## Real-Time Example 1: Setting Up Master-Agent on AWS

**Scenario:** Configure Puppet master on one EC2 instance and 3 agent nodes for a web application.

```bash
# Master: runs Puppet Server
# Agents: web-01, web-02, app-01

# After setup, apply configuration:
# site.pp classifies nodes by name pattern
node /^web/ {
  class { 'nginx':
    server_name   => $facts['fqdn'],
    listen_port   => 80,
    document_root => '/var/www/myapp',
  }
}

node /^app/ {
  class { 'nodejs':
    version => '20.x',
  }
  class { 'myapp':
    port => 3000,
  }
}
```

---

## Real-Time Example 2: Deploy Software to Nodes Using Modules

**Scenario:** Create a module that installs monitoring agents on all servers.

```puppet
# modules/monitoring/manifests/init.pp
class monitoring (
  String $server_url = 'http://monitoring.internal:9090',
) {
  package { 'node-exporter':
    ensure   => '1.7.0',
    provider => 'rpm',
    source   => "puppet:///modules/monitoring/node_exporter-1.7.0.rpm",
  }

  file { '/etc/node_exporter/config.yml':
    ensure  => file,
    content => template('monitoring/config.yml.erb'),
    require => Package['node-exporter'],
    notify  => Service['node_exporter'],
  }

  service { 'node_exporter':
    ensure  => running,
    enable  => true,
    require => [Package['node-exporter'], File['/etc/node_exporter/config.yml']],
  }
}

# Apply to all nodes
node default {
  include monitoring
}
```

---

## Real-Time Example 3: Puppet File Server for Config Distribution

**Scenario:** Distribute application configuration files and SSL certificates to all web servers.

```puppet
# modules/ssl_certs/manifests/init.pp
class ssl_certs {
  file { '/etc/ssl/private':
    ensure  => directory,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0710',
  }

  file { '/etc/ssl/private/server.key':
    ensure  => file,
    source  => 'puppet:///modules/ssl_certs/server.key',
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
    require => File['/etc/ssl/private'],
  }

  file { '/etc/ssl/certs/server.crt':
    ensure => file,
    source => 'puppet:///modules/ssl_certs/server.crt',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
}
```

---

## Labs

### Lab 1: Set Up Puppet Master-Agent on AWS
```bash
# Launch 2 EC2 instances (1 master, 1 agent)
# Install Puppet Server on master
# Install Puppet Agent on node
# Sign certificate
# Run puppet agent --test on node
# Verify connection successful
```

### Lab 2: Create and Deploy a Manifest
```bash
# On master, create site.pp with:
#   - Install httpd package
#   - Create index.html file
#   - Ensure httpd service is running
# Run puppet agent --test on node
# Verify httpd is running and serving content
# Modify manifest → re-run → verify changes applied
```

### Lab 3: Create a Puppet Module
```bash
# Create module directory structure
# puppet module generate yourname-webapp
# Add manifests (init.pp, install.pp, config.pp, service.pp)
# Add templates and files
# Include module in site.pp for a node
# Apply and verify
```

### Lab 4: Deploy Software on Multiple Nodes Using Modules
```bash
# Launch 3 agent nodes
# Create module that installs nginx + custom config
# Classify nodes in site.pp
# Sign all certificates
# Run puppet on all agents
# Verify all 3 nodes have nginx running with custom config
```

### Lab 5: Implement Puppet File Server
```bash
# Create custom file server mount in fileserver.conf
# Add files to serve
# Create manifest that pulls files from file server
# Apply to nodes
# Verify files distributed correctly
```

---

## Key Commands

```bash
# Master commands
sudo /opt/puppetlabs/bin/puppetserver ca list         # List pending certs
sudo /opt/puppetlabs/bin/puppetserver ca sign --all    # Sign all pending
sudo /opt/puppetlabs/bin/puppetserver ca clean --certname NODE  # Revoke cert
sudo /opt/puppetlabs/bin/puppet module list            # List installed modules
sudo /opt/puppetlabs/bin/puppet module install MODULE  # Install from Forge

# Agent commands
sudo /opt/puppetlabs/bin/puppet agent --test           # One-time run (verbose)
sudo /opt/puppetlabs/bin/puppet agent --noop           # Dry run (no changes)
sudo /opt/puppetlabs/bin/puppet facts                  # Show system facts
sudo /opt/puppetlabs/bin/puppet resource user          # Query resource state
sudo /opt/puppetlabs/bin/puppet parser validate FILE   # Validate manifest syntax
```

---

## Interview Questions

1. **What is Puppet and how does it work?**
   → Declarative configuration management tool. Agent-master model: agents pull configuration from master every 30 min. You declare desired state; Puppet enforces it.

2. **Explain Puppet architecture.**
   → Master compiles catalogs from manifests + facts. Agents collect facts, request catalog via SSL, apply resources, report results. PuppetDB stores data. Hiera provides configuration data.

3. **What is a Puppet manifest?**
   → A `.pp` file containing Puppet DSL code that declares resources (packages, files, services). `site.pp` is the main entry point that classifies nodes.

4. **What are Puppet modules?**
   → Reusable, self-contained units of Puppet code. Standard structure with manifests/, files/, templates/, lib/. Can be shared via Puppet Forge.

5. **How do you handle configuration data in Puppet?**
   → Hiera — hierarchical data lookup. Separates data from code. Lookups follow a hierarchy: per-node → per-environment → common. Supports YAML, JSON, eyaml (encrypted).

6. **Puppet vs Ansible — which to choose?**
   → Puppet: continuous enforcement (agent-based), better for large static infrastructure. Ansible: agentless, easier to learn (YAML), better for ad-hoc tasks and smaller teams.

7. **What are Puppet facts?**
   → System information collected by Facter on each agent: OS, IP, memory, CPU, etc. Used in manifests for conditional logic. Custom facts can be defined.

8. **What is the Puppet File Server?**
   → Built-in file serving capability in Puppet master. Serves static files to agents using `puppet:///` URI scheme. Files stored in module's `files/` directory or custom mount points.
