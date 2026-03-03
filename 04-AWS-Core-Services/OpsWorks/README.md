# OpsWorks — Configuration Management as a Service

> Managed Chef & Puppet service for automating server configuration, deployment, and management. AWS-managed infrastructure automation.

---

## Real-World Analogy

OpsWorks is like a **recipe book for your servers**:
- Chef recipes / Puppet manifests = instructions for setting up a server
- OpsWorks = the kitchen manager who follows the recipes automatically
- When you add a new server, the manager automatically applies all the right recipes
- Layers = different roles (web server layer, app server layer, database layer)

---

## OpsWorks Flavors

| Flavor | Engine | Status | Use Case |
|--------|--------|--------|----------|
| **OpsWorks for Chef Automate** | Chef Infra | Active | Full Chef workflow with Chef server |
| **OpsWorks for Puppet Enterprise** | Puppet Enterprise | Active | Full Puppet master-agent workflow |
| **OpsWorks Stacks** | Chef Solo (embedded) | Maintenance mode | Legacy, layered architecture |

```
OpsWorks Stacks Architecture:
┌─────────────────────────────────────────────┐
│                OpsWorks Stack                │
│                                             │
│  ┌─────────────┐  ┌─────────────┐           │
│  │  Web Layer  │  │  App Layer  │           │
│  │  (Nginx)    │  │  (Node.js)  │           │
│  │  EC2  EC2   │  │  EC2  EC2   │           │
│  └─────────────┘  └─────────────┘           │
│  ┌─────────────┐  ┌─────────────┐           │
│  │  DB Layer   │  │  Monitor    │           │
│  │  (MySQL)    │  │  (Custom)   │           │
│  │  EC2        │  │  EC2        │           │
│  └─────────────┘  └─────────────┘           │
│                                             │
│  Lifecycle Events: Setup → Configure →      │
│                    Deploy → Undeploy → Stop  │
└─────────────────────────────────────────────┘
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Stack** | Top-level container representing your application environment |
| **Layer** | A set of instances with a shared purpose (web, app, db) |
| **Instance** | EC2 instances managed by OpsWorks |
| **App** | Code deployed to instances (from Git, S3, or HTTP) |
| **Recipe/Cookbook** | Chef code that configures instances |
| **Lifecycle Events** | setup, configure, deploy, undeploy, shutdown |

### Lifecycle Events

```
Instance Launch:
  1. SETUP     → Install packages, configure base system
  2. CONFIGURE → Configure app, set environment vars, update config files
  3. DEPLOY    → Deploy application code from repository

Instance Termination:
  4. UNDEPLOY  → Remove application
  5. SHUTDOWN  → Cleanup before termination

Note: CONFIGURE runs on ALL instances whenever any instance 
      comes up or goes down (for service discovery)
```

### Instance Types

| Type | Description |
|------|-------------|
| **24/7** | Always running |
| **Time-based** | Start/stop on schedule (e.g., dev hours only) |
| **Load-based** | Scale based on metrics (CPU, memory, load) |

---

## OpsWorks for Chef Automate

```bash
# Create Chef Automate server
aws opsworks-cm create-server \
    --server-name my-chef-server \
    --instance-profile-arn arn:aws:iam::ACCT:instance-profile/aws-opsworks-cm-ec2-role \
    --instance-type m5.large \
    --engine "ChefAutomate" \
    --engine-version "2" \
    --engine-model "Single" \
    --service-role-arn arn:aws:iam::ACCT:role/aws-opsworks-cm-service-role

# After server ready: download starter kit
# Contains:
# - knife.rb (Chef CLI config)
# - Organization validator key
# - Chef server URL

# Upload cookbook
knife cookbook upload my-webapp

# Bootstrap a node (registers with Chef server)
knife bootstrap 10.0.1.50 \
    --ssh-user ec2-user \
    --ssh-identity-file ~/.ssh/key.pem \
    --node-name web-server-01 \
    --run-list "recipe[my-webapp]"
```

---

## OpsWorks for Puppet Enterprise

```bash
# Create Puppet Enterprise server
aws opsworks-cm create-server \
    --server-name my-puppet-server \
    --instance-profile-arn arn:aws:iam::ACCT:instance-profile/aws-opsworks-cm-ec2-role \
    --instance-type m5.large \
    --engine "Puppet" \
    --engine-version "2019" \
    --engine-model "Single" \
    --service-role-arn arn:aws:iam::ACCT:role/aws-opsworks-cm-service-role

# Puppet agent nodes automatically register via user-data
# OpsWorks handles certificate signing
# Puppet code deployed from r10k/Code Manager
```

---

## Real-Time Example 1: Multi-Tier Web App with OpsWorks Stacks

**Scenario:** Deploy a 3-tier web application using OpsWorks Stacks with automated scaling.

```bash
# Create stack
aws opsworks create-stack \
    --name "production-stack" \
    --region us-east-1 \
    --vpc-id vpc-12345 \
    --default-os "Amazon Linux 2" \
    --service-role-arn arn:aws:iam::ACCT:role/OpsWorksServiceRole \
    --default-instance-profile-arn arn:aws:iam::ACCT:instance-profile/OpsWorksInstanceProfile \
    --configuration-manager '{"Name":"Chef","Version":"12"}'

# Create web layer
aws opsworks create-layer \
    --stack-id STACK_ID \
    --type web \
    --name "Web Servers" \
    --shortname web \
    --custom-recipes '{"Setup":["nginx::install"],"Deploy":["myapp::deploy"]}'

# Create app layer
aws opsworks create-layer \
    --stack-id STACK_ID \
    --type custom \
    --name "App Servers" \
    --shortname app \
    --custom-recipes '{"Setup":["nodejs::install"],"Deploy":["myapp::backend"]}'

# Add instances
aws opsworks create-instance \
    --stack-id STACK_ID \
    --layer-ids LAYER_ID \
    --instance-type t3.medium \
    --auto-scaling-type load   # Scale based on load

# Deploy app from Git
aws opsworks create-app \
    --stack-id STACK_ID \
    --name "My Web App" \
    --type other \
    --app-source '{"Type":"git","Url":"https://github.com/company/webapp.git"}'

aws opsworks create-deployment \
    --stack-id STACK_ID \
    --app-id APP_ID \
    --command '{"Name":"deploy"}'
```

---

## Real-Time Example 2: Chef Cookbook for Web Server

**Scenario:** Write a Chef cookbook that installs and configures Nginx with a custom virtual host.

```ruby
# cookbooks/nginx-setup/recipes/default.rb

# Install Nginx
package 'nginx' do
  action :install
end

# Create web root
directory '/var/www/myapp' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  recursive true
end

# Deploy virtual host config
template '/etc/nginx/sites-available/myapp' do
  source 'myapp.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[nginx]'
end

# Enable site
link '/etc/nginx/sites-enabled/myapp' do
  to '/etc/nginx/sites-available/myapp'
end

# Ensure Nginx is running
service 'nginx' do
  action [:enable, :start]
end
```

```erb
# cookbooks/nginx-setup/templates/myapp.conf.erb
server {
    listen 80;
    server_name <%= node['myapp']['domain'] %>;
    root /var/www/myapp;

    location / {
        proxy_pass http://localhost:<%= node['myapp']['port'] %>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Real-Time Example 3: Auto-Healing with OpsWorks

**Scenario:** Configure OpsWorks to automatically replace failed instances and run health checks.

```bash
# OpsWorks auto-healing is built-in:
# 1. OpsWorks agent on each instance reports health every ~5 minutes
# 2. If instance stops reporting → marked as "connection lost"
# 3. OpsWorks stops the instance and starts a new one
# 4. New instance goes through setup → configure → deploy lifecycle

# Enable auto-healing per layer
aws opsworks update-layer \
    --layer-id LAYER_ID \
    --enable-auto-healing

# Custom health check recipe
# cookbooks/health/recipes/check.rb
execute 'health_check' do
  command 'curl -sf http://localhost/health || exit 1'
  retries 3
  retry_delay 10
end
```

---

## Labs

### Lab 1: Create OpsWorks Stack with Web Layer
```bash
# Create a simple OpsWorks Stack
# Add a custom layer for web servers
# Deploy instances with Chef recipes
# Access the web application
# Test auto-healing by stopping an instance
```

### Lab 2: Deploy Application from Git
```bash
# Create an app pointing to a GitHub repository
# Run deployment
# Modify code in Git → redeploy
# View deployment logs
# Roll back to previous version
```

### Lab 3: Configure Time-Based and Load-Based Scaling
```bash
# Set up time-based instances (on during business hours)
# Set up load-based instances (scale on CPU > 70%)
# Simulate load and watch scaling behavior
# Review CloudWatch metrics for the stack
```

---

## Interview Questions

1. **What is AWS OpsWorks and when would you use it?**
   → Managed Chef/Puppet service for configuration management. Use when you need Chef/Puppet automation without managing the infrastructure for Chef Server or Puppet Master.

2. **OpsWorks Stacks vs OpsWorks Chef Automate — difference?**
   → Stacks: simplified, uses embedded Chef Solo, layer-based. Chef Automate: full Chef Server (compliance, visibility, InSpec). Stacks is in maintenance mode; use Chef Automate for new deployments.

3. **What are OpsWorks lifecycle events?**
   → Setup (install), Configure (reconfig on topology changes), Deploy (app code), Undeploy (remove app), Shutdown (cleanup). CONFIGURE runs on ALL instances when any instance changes.

4. **How does auto-healing work in OpsWorks?**
   → Agent heartbeat every ~5 min. If missed, OpsWorks stops the instance and launches a replacement. New instance runs through full lifecycle events. Works for all instance types.

5. **What are OpsWorks Layers?**
   → Logical grouping of instances by function (web, app, db). Each layer has custom recipes for lifecycle events. Built-in layers exist for common patterns (HAProxy, MySQL, etc.).

6. **OpsWorks vs Elastic Beanstalk — which to choose?**
   → Beanstalk: PaaS, code-first, minimal config. OpsWorks: infrastructure-level control with Chef/Puppet. Use Beanstalk for simple apps; OpsWorks when you need granular server configuration.

7. **Can OpsWorks work with on-premise servers?**
   → Yes, OpsWorks Stacks supports registering on-premise instances. Install the OpsWorks agent on the server and register it with your stack.

8. **What is the difference between 24/7, time-based, and load-based instances?**
   → 24/7: always running. Time-based: scheduled start/stop (e.g., dev hours). Load-based: auto-scale based on CloudWatch metrics (CPU, memory).
