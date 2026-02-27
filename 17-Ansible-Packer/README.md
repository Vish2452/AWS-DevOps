# Ansible & Packer — Configuration Management & Golden Images (1 Week)

> **Objective:** Automate server configuration with Ansible, build immutable golden images with Packer, and create a CI/CD pipeline for automated image builds.

---

## 🎮 Real-World Analogy: Ansible is a Universal Remote Control for Servers

```
🙅 WITHOUT ANSIBLE (Manual Configuration):

  You have 50 servers. Install nginx on all of them:
    SSH into server 1 → apt install nginx → configure → test
    SSH into server 2 → apt install nginx → configure → test
    SSH into server 3 → oops, typed wrong command! 💥
    ... repeat 47 more times ...
    Time: 2 days. Errors: guaranteed.


🎮 WITH ANSIBLE (Universal Remote):

  Write ONE playbook (instruction set):
  "On ALL 50 servers: install nginx, copy config, start service"
  
  Press PLAY → Ansible runs on all 50 servers simultaneously!
  Time: 5 minutes. Errors: zero.
  Run it again? Same result every time (idempotent)!
```

### Ansible Concepts = Teaching a Robot
```
  🤖 ANSIBLE TERMS mapped to real life:

  Inventory       = Your contact list (list of servers + their roles)
                    "web servers: 10.0.1.1, 10.0.1.2"
                    "database servers: 10.0.2.1"

  Playbook        = Instruction manual
                    "Step 1: Install nginx
                     Step 2: Copy config file
                     Step 3: Start the service"

  Role            = Reusable skill set
                    Like a job title: "web server role" includes
                    everything a web server needs.

  Template        = Fill-in-the-blank form
                    "server_name = {{ domain_name }}"
                    Dev: server_name = dev.example.com
                    Prod: server_name = www.example.com

  Vault           = Locked safe for secrets
                    Passwords encrypted, never stored in plain text.

  Facts           = Ansible inspects each server first
                    "This server runs Ubuntu 22.04, has 4 CPUs, 16GB RAM"
```

### Packer = Photo Booth for Servers
```
  📸 PACKER creates "Golden Images" (AMIs):

  Think of it as a PHOTO of a perfectly configured server:

  1. Start with a blank Ubuntu server
  2. Install ALL required software (nginx, monitoring agent, security tools)
  3. Configure everything perfectly
  4. Take a SNAPSHOT (AMI = Amazon Machine Image)
  5. Launch 100 servers from this snapshot → ALL identical!

  Like cloning a perfectly set up phone:
  Set up 1 phone perfectly → clone it → give to all employees.
  Every phone is identical, no manual setup needed!

  Pipeline:
  Code change → Packer builds new AMI → Terraform deploys it
  = Immutable infrastructure (servers are replaced, never modified)
```

---

## Part 1: Ansible

### Architecture
```
Control Node (your laptop / CI runner)
      │
      ├── Inventory (hosts)
      ├── Playbooks (tasks)
      ├── Roles (reusable units)
      ├── Templates (Jinja2)
      └── Vault (secrets)
      │
      ▼  (SSH / WinRM)
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Web Server │  │ App Server │  │ DB Server  │
│ (nginx)    │  │ (node.js)  │  │ (postgres) │
└────────────┘  └────────────┘  └────────────┘
```

### Inventory
```ini
# inventory/production.ini
[webservers]
web1 ansible_host=10.0.1.10
web2 ansible_host=10.0.1.11

[appservers]
app1 ansible_host=10.0.2.10
app2 ansible_host=10.0.2.11

[dbservers]
db1 ansible_host=10.0.3.10

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/production.pem
ansible_python_interpreter=/usr/bin/python3
```

### Dynamic Inventory (AWS)
```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:Environment: production
  instance-state-name: running
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: placement.availability_zone
    prefix: az
hostnames:
  - private-ip-address
compose:
  ansible_host: private_ip_address
```

### Playbook Example
```yaml
# playbooks/setup-webserver.yml
---
- name: Configure Web Servers
  hosts: webservers
  become: true
  vars:
    nginx_port: 80
    app_name: "{{ lookup('env', 'APP_NAME') | default('webapp') }}"

  pre_tasks:
    - name: Update package cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"

  roles:
    - role: common
    - role: nginx
      vars:
        server_name: "{{ app_name }}.example.com"
    - role: monitoring-agent

  post_tasks:
    - name: Verify nginx is running
      ansible.builtin.uri:
        url: "http://localhost:{{ nginx_port }}/health"
        status_code: 200
      register: health_check
      retries: 3
      delay: 5
```

### Roles Structure
```
roles/
├── common/
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   ├── templates/
│   ├── files/
│   ├── vars/main.yml
│   └── defaults/main.yml
├── nginx/
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   ├── templates/
│   │   └── nginx.conf.j2
│   ├── defaults/main.yml
│   └── meta/main.yml
└── monitoring-agent/
    ├── tasks/main.yml
    └── templates/
        └── node-exporter.service.j2
```

### Common Role
```yaml
# roles/common/tasks/main.yml
---
- name: Set timezone
  ansible.builtin.timezone:
    name: "{{ timezone | default('UTC') }}"

- name: Install essential packages
  ansible.builtin.package:
    name:
      - curl
      - wget
      - vim
      - htop
      - unzip
      - jq
      - git
      - net-tools
    state: present

- name: Configure SSH hardening
  ansible.builtin.template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    mode: '0600'
    validate: '/usr/sbin/sshd -t -f %s'
  notify: restart sshd

- name: Set up log rotation
  ansible.builtin.template:
    src: logrotate.conf.j2
    dest: /etc/logrotate.d/{{ app_name }}

- name: Configure NTP
  ansible.builtin.service:
    name: chronyd
    state: started
    enabled: true
```

### Nginx Role with Jinja2 Template
```yaml
# roles/nginx/tasks/main.yml
---
- name: Install Nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Deploy Nginx configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/{{ server_name }}
    owner: root
    mode: '0644'
  notify: reload nginx

- name: Enable site
  ansible.builtin.file:
    src: /etc/nginx/sites-available/{{ server_name }}
    dest: /etc/nginx/sites-enabled/{{ server_name }}
    state: link
  notify: reload nginx

- name: Ensure Nginx is running
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

```jinja2
{# roles/nginx/templates/nginx.conf.j2 #}
server {
    listen {{ nginx_port }};
    server_name {{ server_name }};

    access_log /var/log/nginx/{{ server_name }}_access.log;
    error_log /var/log/nginx/{{ server_name }}_error.log;

    location / {
        proxy_pass http://127.0.0.1:{{ app_port | default(3000) }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        access_log off;
        return 200 '{"status":"ok"}';
        add_header Content-Type application/json;
    }

{% if enable_ssl | default(false) %}
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/{{ server_name }}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{{ server_name }}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
{% endif %}
}
```

### Ansible Handlers
```yaml
# roles/nginx/handlers/main.yml
---
- name: reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded

- name: restart sshd
  ansible.builtin.service:
    name: sshd
    state: restarted
```

### Ansible Vault (Secrets)
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Encrypt existing file
ansible-vault encrypt vars/production.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

```yaml
# secrets.yml (encrypted at rest)
db_password: "SuperSecret123!"
api_key: "sk-abc123xyz"
ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
```

---

## Part 2: Packer — Golden Images

### What Are Golden Images?
Pre-baked AMIs with all dependencies, configurations, and security hardening already applied. Servers boot **ready to serve traffic** — no configuration drift.

```
Packer Build Process:
  Source AMI (Ubuntu 22.04) → Provisioners (Ansible/Shell) → Output AMI
       │                              │                           │
       │                    Install packages              Immutable image
       │                    Configure services            Version-tagged
       │                    Harden security               Ready to deploy
       │                    Bake app code
```

### Packer Template (HCL2)
```hcl
# golden-image.pkr.hcl

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "ami_name_prefix" {
  type    = string
  default = "golden-image"
}

variable "app_version" {
  type    = string
  default = "latest"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name_prefix}-${var.app_version}-{{timestamp}}"
  instance_type = "t3.medium"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical
  }
  ssh_username = "ubuntu"

  tags = {
    Name        = "${var.ami_name_prefix}-${var.app_version}"
    Version     = var.app_version
    BuildDate   = "{{timestamp}}"
    Builder     = "packer"
    OS          = "Ubuntu 22.04"
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  # Step 1: Shell provisioner for basic setup
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y python3 python3-pip ansible"
    ]
  }

  # Step 2: Ansible provisioner for configuration
  provisioner "ansible" {
    playbook_file = "./ansible/playbooks/golden-image.yml"
    extra_arguments = [
      "--extra-vars", "app_version=${var.app_version}"
    ]
  }

  # Step 3: Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo truncate -s 0 /var/log/*.log",
      "history -c"
    ]
  }

  # Post-processor: generate manifest
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
```

### Ansible Playbook for Golden Image
```yaml
# ansible/playbooks/golden-image.yml
---
- name: Configure Golden Image
  hosts: all
  become: true

  roles:
    - common           # Base packages, timezone, NTP
    - security         # SSH hardening, fail2ban, firewall
    - monitoring-agent # Node exporter, CloudWatch agent
    - docker           # Docker CE, docker-compose
    - app-runtime      # Node.js / Python / Java runtime
```

---

## CI/CD Pipeline: Automated Golden Image Builds

### GitHub Actions Workflow
```yaml
name: Build Golden Image
on:
  push:
    branches: [main]
    paths: ['packer/**', 'ansible/**']
  schedule:
    - cron: '0 2 * * 1'  # Weekly Monday 2AM (security patches)

env:
  PACKER_VERSION: "1.11.0"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}
      - name: Packer Init
        run: packer init golden-image.pkr.hcl
        working-directory: packer
      - name: Packer Validate
        run: packer validate golden-image.pkr.hcl
        working-directory: packer
      - name: Ansible Lint
        run: |
          pip install ansible-lint
          ansible-lint ansible/

  build:
    needs: validate
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Packer Init
        run: packer init golden-image.pkr.hcl
        working-directory: packer

      - name: Packer Build
        run: |
          packer build \
            -var "app_version=${{ github.sha }}" \
            golden-image.pkr.hcl
        working-directory: packer

      - name: Extract AMI ID
        id: ami
        run: |
          AMI_ID=$(jq -r '.builds[-1].artifact_id | split(":")[1]' packer/manifest.json)
          echo "ami_id=$AMI_ID" >> $GITHUB_OUTPUT
          echo "Built AMI: $AMI_ID"

      - name: Update SSM Parameter
        run: |
          aws ssm put-parameter \
            --name "/golden-image/latest-ami-id" \
            --value "${{ steps.ami.outputs.ami_id }}" \
            --type String --overwrite

      - name: Notify Slack
        if: always()
        run: |
          curl -X POST "${{ secrets.SLACK_WEBHOOK }}" \
            -H 'Content-Type: application/json' \
            -d '{"text": "Golden Image Build: ${{ job.status }} — AMI: ${{ steps.ami.outputs.ami_id }}"}'
```

### Using Golden Image in Terraform
```hcl
# Fetch latest golden AMI from SSM
data "aws_ssm_parameter" "golden_ami" {
  name = "/golden-image/latest-ami-id"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-"
  image_id      = data.aws_ssm_parameter.golden_ami.value
  instance_type = var.instance_type
  # ... No user_data needed! Image is pre-baked.
}
```

---

## Project Structure
```
golden-image-pipeline/
├── packer/
│   ├── golden-image.pkr.hcl     # Packer template
│   └── variables.pkrvars.hcl    # Variable values
├── ansible/
│   ├── ansible.cfg
│   ├── playbooks/
│   │   └── golden-image.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── security/
│   │   ├── docker/
│   │   ├── monitoring-agent/
│   │   └── app-runtime/
│   └── inventory/
│       ├── production.ini
│       └── aws_ec2.yml
├── terraform/
│   └── launch-template.tf       # Uses golden AMI
├── .github/workflows/
│   └── build-golden-image.yml
└── README.md
```

## Deliverables
- [ ] Ansible roles: common, security, nginx, monitoring, docker
- [ ] Dynamic AWS inventory with tag-based grouping
- [ ] Ansible Vault for secrets management
- [ ] Packer template building golden AMI with Ansible provisioner
- [ ] GitHub Actions pipeline: validate → build → store AMI ID in SSM
- [ ] Weekly scheduled builds for security patch updates
- [ ] Terraform launch template consuming golden AMI
- [ ] Ansible lint + Packer validate in CI
- [ ] Jinja2 templates for nginx, systemd services
