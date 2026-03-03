# Elastic Beanstalk — PaaS Application Deployment

> Upload your code, Beanstalk handles the rest — provisioning, load balancing, auto scaling, monitoring. The fastest way to deploy web apps on AWS.

---

## Real-World Analogy

Elastic Beanstalk is like a **fully managed apartment building**:
- You (developer) just move in with your furniture (code)
- The building management (Beanstalk) handles electricity, plumbing, security, maintenance
- You don't need to know HOW the building works — just live in it
- But if you want, you can customize your apartment (advanced configuration)
- Behind the scenes: EC2, ALB, ASG, RDS, CloudWatch all working for you

---

## How Beanstalk Works

```
Developer                    Elastic Beanstalk                     AWS Resources
┌──────────┐    upload      ┌──────────────────┐    provisions    ┌──────────────┐
│          │  ──────────▶   │                  │  ──────────────▶ │ EC2 instances│
│  Code +  │    code        │  Beanstalk       │                  │ ALB          │
│  Config  │                │  Environment     │                  │ ASG          │
│          │  ◀──────────   │                  │  ◀────────────── │ RDS          │
└──────────┘    URL +       └──────────────────┘    health +      │ CloudWatch   │
                status                               metrics       │ S3 (versions)│
                                                                  └──────────────┘
```

### Supported Platforms

| Platform | Versions |
|----------|----------|
| **Java** | Java SE, Tomcat |
| **Node.js** | 18.x, 20.x |
| **Python** | 3.9, 3.11, 3.12 |
| **.NET** | .NET Core on Linux, .NET on Windows |
| **PHP** | 8.1, 8.2, 8.3 |
| **Ruby** | 3.1, 3.2, 3.3 |
| **Go** | 1.21+ |
| **Docker** | Single container, Multi-container (ECS), Compose |
| **Custom** | Any language via custom Docker image |

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Application** | Top-level container (like a project folder) |
| **Environment** | A running version of your app (dev, staging, prod) |
| **Application Version** | A labeled, deployable bundle (zip file in S3) |
| **Environment Tier** | Web Server (HTTP requests) or Worker (SQS background jobs) |
| **Platform** | OS + language runtime + web server + Beanstalk components |
| **Configuration** | Settings for instances, scaling, LB, database, etc. |

### Environment Tiers

```
Web Server Tier:                    Worker Tier:
┌─────────┐                        ┌──────────┐
│   ALB   │ ◀── HTTP requests      │   SQS    │ ◀── messages
└────┬────┘                        └────┬─────┘
     │                                  │
┌────▼────────┐                   ┌────▼────────┐
│ EC2 (ASG)   │                   │ EC2 (ASG)   │
│ Web Server  │                   │ Worker      │
│ Apache/Nginx│                   │ Daemon      │
└─────────────┘                   └─────────────┘
```

---

## Deployment Policies

| Policy | Downtime? | Speed | Risk | How It Works |
|--------|-----------|-------|------|-------------|
| **All at once** | Yes | Fastest | Highest | Deploy to all instances simultaneously |
| **Rolling** | No | Slow | Low | Deploy in batches (configurable batch size) |
| **Rolling with additional batch** | No | Slower | Lowest | Launch new batch first, then rolling |
| **Immutable** | No | Slowest | Lowest | New ASG → test → swap → delete old |
| **Traffic splitting** | No | Slow | Very low | Canary: shift % of traffic to new version |
| **Blue/Green** | No | Medium | Low | New environment → swap CNAME (manual) |

```
Rolling Deployment (batch size = 2, total = 6):

Time 1: [v2] [v2] [v1] [v1] [v1] [v1]   ← first batch updated
Time 2: [v2] [v2] [v2] [v2] [v1] [v1]   ← second batch updated
Time 3: [v2] [v2] [v2] [v2] [v2] [v2]   ← all updated

Immutable Deployment:

Step 1: [v1] [v1] [v1]  +  [v2] [v2] [v2]  (new ASG created)
Step 2: health check passes on v2
Step 3: [v1] [v1] [v1] terminated
Step 4: [v2] [v2] [v2] now serves all traffic
```

---

## Real-Time Example 1: Deploy a Node.js App

**Scenario:** Deploy a Node.js Express API with auto scaling and RDS PostgreSQL.

```bash
# Install EB CLI
pip install awsebcli

# Initialize Beanstalk app
cd my-node-app
eb init --platform "Node.js 20" --region us-east-1

# Create environment with RDS
eb create prod-env \
    --instance-type t3.small \
    --scale 2 \
    --elb-type application \
    --database \
    --database.engine postgres \
    --database.instance db.t3.micro \
    --database.size 20 \
    --database.username admin \
    --database.password SecureP@ss123 \
    --envvars NODE_ENV=production,PORT=8080

# Deploy new version
eb deploy

# Check status
eb status
eb health
eb logs
```

**Procfile** (tells Beanstalk how to run your app):
```
web: node server.js
```

**.ebextensions/01-packages.config** (customize environment):
```yaml
packages:
  yum:
    git: []
    ImageMagick: []

container_commands:
  01_migrate:
    command: "npx sequelize-cli db:migrate"
    leader_only: true
  02_seed:
    command: "npx sequelize-cli db:seed:all"
    leader_only: true
```

---

## Real-Time Example 2: Blue/Green Deployment

**Scenario:** Zero-downtime deployment with instant rollback capability.

```bash
# Current production: prod-env (v1)

# Create clone environment
eb clone prod-env --clone-name staging-env

# Deploy v2 to staging
eb deploy staging-env

# Test staging-env URL thoroughly
# https://staging-env.us-east-1.elasticbeanstalk.com

# Swap CNAMEs (instant switch)
eb swap prod-env --destination_name staging-env

# prod-env now serves v2, staging-env serves v1
# If issues: swap again to instant rollback

# After verification, terminate old environment
eb terminate staging-env
```

---

## Real-Time Example 3: Docker App on Beanstalk

**Scenario:** Deploy a Docker-based multi-container application using Docker Compose on Beanstalk.

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - api

  api:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=${RDS_HOSTNAME}
      - DB_NAME=${RDS_DB_NAME}
      - DB_USER=${RDS_USERNAME}
      - DB_PASS=${RDS_PASSWORD}

  worker:
    build: ./worker
    environment:
      - SQS_URL=${SQS_QUEUE_URL}
```

```bash
# Deploy multi-container app
eb init --platform "Docker" --region us-east-1
eb create docker-env --instance-type t3.medium --scale 2
```

---

## .ebextensions — Environment Customization

```yaml
# .ebextensions/02-scaling.config
option_settings:
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  aws:autoscaling:trigger:
    MeasureName: CPUUtilization
    UpperThreshold: 70
    LowerThreshold: 30
    BreachDuration: 5
  aws:elasticbeanstalk:environment:
    LoadBalancerType: application
  aws:elbv2:listener:443:
    Protocol: HTTPS
    SSLCertificateArns: arn:aws:acm:us-east-1:ACCT:certificate/xxxx
```

---

## Labs

### Lab 1: Deploy a Sample Web App
```bash
# Create a simple Python Flask app
mkdir flask-demo && cd flask-demo

cat > application.py << 'EOF'
from flask import Flask
application = Flask(__name__)

@application.route('/')
def home():
    return '<h1>Hello from Elastic Beanstalk!</h1>'

@application.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    application.run(host='0.0.0.0', port=5000)
EOF

cat > requirements.txt << 'EOF'
flask==3.0.0
EOF

# Initialize and create environment
eb init --platform "Python 3.11" --region us-east-1
eb create flask-demo-env --single  # single instance (free tier)
eb open  # opens in browser
```

### Lab 2: Practice Deployment Strategies
```bash
# Modify app, then deploy with different strategies:

# Strategy 1: All at once
eb deploy --staged

# Strategy 2: Rolling (via .ebextensions)
# Add configuration for rolling with batch size

# Strategy 3: Blue/Green
eb clone flask-demo-env --clone-name staging
eb deploy staging
eb swap flask-demo-env --destination_name staging

# Compare deployment times and observe behavior
eb events --follow
```

### Lab 3: Add RDS and Environment Variables
```bash
# Add RDS to existing environment
# Configure via .ebextensions
# Set environment variables
eb setenv DB_HOST=mydb.xxxx.rds.amazonaws.com DB_NAME=mydb
# Deploy app that connects to RDS
# Test database connectivity
# Clean up
eb terminate flask-demo-env --force
```

---

## Interview Questions

1. **What is Elastic Beanstalk and when would you use it?**
   → PaaS service for deploying web apps without managing infrastructure. Use when you want fast deployment with default best practices. Not for highly custom architectures.

2. **How is Beanstalk different from EC2 directly?**
   → Beanstalk abstracts infrastructure provisioning. You upload code, it creates EC2, ALB, ASG, CloudWatch automatically. You retain full access to underlying resources if needed.

3. **Explain the deployment policies.**
   → All-at-once (fast, downtime), Rolling (batches, no downtime), Rolling+batch (maintains capacity), Immutable (safest, new ASG), Traffic splitting (canary), Blue/Green (CNAME swap).

4. **What are .ebextensions?**
   → YAML/JSON config files in `.ebextensions/` folder that customize the environment: install packages, run commands, set options, configure services. Executed in alphabetical order.

5. **How does Blue/Green deployment work in Beanstalk?**
   → Create a clone environment, deploy new version to clone, test, then `eb swap` to exchange CNAMEs. Production URL now points to new environment. Instant rollback by swapping again.

6. **Web Server Tier vs Worker Tier?**
   → Web Server: handles HTTP requests via ALB → EC2. Worker: processes background jobs from SQS queue via daemon on EC2. Often used together.

7. **Can you use Docker with Beanstalk?**
   → Yes. Single container Docker, multi-container Docker (via ECS), or Docker Compose. Useful for custom runtimes or multi-service apps.

8. **How do you handle database migrations in Beanstalk?**
   → Use `container_commands` in `.ebextensions` with `leader_only: true`. Only one instance runs the migration. Or use a separate CI/CD step before deployment.
