# Module 12 — Security & DevSecOps (2 Weeks)

> **Objective:** Embed security into every stage of the CI/CD pipeline. Master SAST, SCA, container scanning, IaC scanning, secrets management, DAST, AND AWS-native security services — Security Hub, GuardDuty, CloudTrail, SCPs, IAM policies, Inspector, Macie, Detective, and CloudWatch security monitoring.

---

## 🛡️ Real-World Analogy: DevSecOps is Like Airport Security

Imagine your code is a **passenger flying from Development City to Production Airport**:

```
✈️ THE FLIGHT (CI/CD Pipeline)
│
├── 🏠 STEP 1: Packing at Home (Writing Code)
│   Security scanner at your door:
│   "You can't pack a knife!" = git-secrets catches hardcoded passwords
│   "Remove that liquid bottle" = pre-commit hooks catch API keys
│   🛠️ Tool: git-secrets, pre-commit hooks
│
├── 🧳 STEP 2: Luggage Screening (Building Code)
│   X-ray machine scans your suitcase contents:
│   SAST = "This jacket has a hidden pocket (SQL injection vulnerability)"
│   SCA  = "This perfume bottle is recalled (vulnerable dependency)"
│   🛠️ Tools: SonarQube (SAST), Snyk/Trivy (SCA)
│
├── 🛂 STEP 3: Passport Control (Container Scanning)
│   Check identity and background:
│   "This Docker image has known criminals (CVEs) inside!"
│   "Base image ubuntu:latest has 47 vulnerabilities!"
│   🛠️ Tools: Trivy, Snyk Container
│
├── 🏗️ STEP 4: Building Inspection (IaC Scanning)
│   Check if the destination building is safe:
│   "S3 bucket is PUBLIC — anyone can read your data!"
│   "Security group allows 0.0.0.0/0 SSH — entire internet can connect!"
│   🛠️ Tools: Checkov, tfsec, KICS
│
├── 🔐 STEP 5: Boarding (Secrets Management)
│   Don't carry sensitive items openly:
│   "Don't write your PIN on your luggage tag!"
│   Instead: use a secure vault (like a hotel safe)
│   🛠️ Tools: HashiCorp Vault, AWS Secrets Manager
│
└── 🛑 STEP 6: In-Flight Security (Runtime Protection)
    Air marshals watching for threats during flight:
    "Unusual activity detected — container trying to access /etc/shadow!"
    "New process spawned that wasn't in the original image!"
    🛠️ Tools: OWASP ZAP (DAST), Falco (runtime)
```

### Shift-Left Security = Catch Problems Early
```
  💰 Cost to fix a bug:

  During coding:     $10        ← Developer fixes it in 5 minutes
  During testing:    $100       ← Testers find it, developers rework
  During staging:    $1,000     ← Delays release, multiple teams involved
  In production:     $10,000    ← Users impacted, emergency fix, PR damage
  After data breach: $1,000,000 ← Legal, fines, customer trust lost

  DevSecOps = Fix at $10, not $1,000,000!
  "Shift Left" = Move security checks to the LEFT (earlier) in the pipeline.
```

### Real-World Examples
| Company | What Happened | DevSecOps Could Have Prevented It |
|---------|--------------|-----------------------------------|
| Capital One (2019) | Misconfigured WAF exposed 100M records | IaC scanning (Checkov) would flag misconfigured firewall |
| Equifax (2017) | Unpatched Apache Struts | SCA scanning (Snyk) would detect vulnerable dependency |
| Uber (2016) | AWS keys hardcoded in GitHub repo | git-secrets pre-commit hook would block the commit |
| SolarWinds (2020) | Compromised build pipeline | Container signing + SBOM verification |

---

## DevSecOps Pipeline
```
Code → Build → Test → Deploy → Monitor
  │      │       │       │         │
 SAST   SCA   DAST   Secrets    RASP
 Lint  Image   Pen    Vault    Runtime
       Scan   Test   Rotation  Defense

Tools at each stage:
  Code    → SonarQube (SAST), git-secrets, pre-commit hooks
  Build   → Trivy (image scan), Snyk (dependencies)
  IaC     → Checkov, tfsec, KICS (Terraform/CloudFormation)
  Deploy  → HashiCorp Vault (secrets), OPA (policy)
  Runtime → OWASP ZAP (DAST), Falco (runtime security)
```

---

## Tool 1: SonarQube (SAST — Static Analysis)

### Docker Setup
```yaml
# docker-compose.yml
services:
  sonarqube:
    image: sonarqube:community
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonar
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_logs:
  postgresql_data:
```

### GitHub Actions Integration
```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarqube-scan-action@v2
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}

- name: Quality Gate Check
  uses: SonarSource/sonarqube-quality-gate-action@v1
  timeout-minutes: 5
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Quality Gate Criteria
| Metric | Threshold | Action |
|--------|-----------|--------|
| Code Coverage | > 80% | Block merge |
| Duplicated Lines | < 3% | Warning |
| Security Hotspots | 0 reviewed | Block merge |
| Bugs | 0 new | Block merge |
| Vulnerabilities | 0 new | Block merge |
| Code Smells | < 10 new | Warning |

---

## Tool 2: Trivy (Container & IaC Scanning)

### Container Image Scanning
```bash
# Scan Docker image
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan with exit code for CI/CD gate
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# Scan ECR image
trivy image --severity HIGH,CRITICAL \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

# Generate SARIF report
trivy image --format sarif --output trivy-results.sarif myapp:latest

# Scan filesystem (source code)
trivy fs --severity HIGH,CRITICAL .

# Scan Kubernetes cluster
trivy k8s --report summary cluster
```

### GitHub Actions Integration
```yaml
- name: Build Image
  run: docker build -t myapp:${{ github.sha }} .

- name: Trivy Vulnerability Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'

- name: Upload Trivy Results
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: 'trivy-results.sarif'
```

---

## Tool 3: Checkov (IaC Security Scanner)

```bash
# Scan Terraform directory
checkov -d terraform/ --framework terraform

# Scan specific file
checkov -f main.tf

# Scan with custom policy
checkov -d terraform/ --check CKV_AWS_18,CKV_AWS_19

# Skip specific checks
checkov -d terraform/ --skip-check CKV_AWS_145

# Output JUnit XML for CI
checkov -d terraform/ -o junitxml > checkov-results.xml
```

### Common Checks
| Check ID | Description |
|----------|------------|
| CKV_AWS_18 | S3 bucket logging enabled |
| CKV_AWS_19 | S3 bucket encryption enabled |
| CKV_AWS_23 | Security group no unrestricted ingress |
| CKV_AWS_24 | VPC flow logging enabled |
| CKV_AWS_145 | RDS encryption at rest |
| CKV_AWS_337 | EKS control plane logging |

### GitHub Actions
```yaml
- name: Checkov IaC Scan
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: terraform/
    framework: terraform
    soft_fail: false
    output_format: sarif
    output_file_path: checkov-results.sarif
```

---

## Tool 4: HashiCorp Vault (Secrets Management)

### Architecture
```
Apps / CI/CD   →   Vault Server   →   Backends
                        │
              ┌─────────┼─────────┐
              │         │         │
         KV Secrets  AWS STS   Database
         (static)   (dynamic)  (dynamic)
                    IAM creds  DB creds
                    (15 min)   (1 hour)
```

### Setup & Usage
```bash
# Start Vault in dev mode
vault server -dev

# Enable KV secrets engine
vault secrets enable -version=2 kv

# Write a secret
vault kv put kv/myapp/prod db_password="SuperSecret123" api_key="abc123"

# Read a secret
vault kv get kv/myapp/prod

# Enable AWS secrets engine (dynamic IAM creds)
vault secrets enable aws
vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY

vault write aws/roles/deploy-role \
  credential_type=iam_user \
  policy_arns=arn:aws:iam::aws:policy/AmazonS3FullAccess

# Get temporary AWS credentials
vault read aws/creds/deploy-role
```

### Kubernetes Integration
```yaml
# Vault Agent Injector — auto-inject secrets into pods
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "webapp"
        vault.hashicorp.com/agent-inject-secret-db-creds: "kv/data/myapp/prod"
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{- with secret "kv/data/myapp/prod" -}}
          DB_HOST={{ .Data.data.db_host }}
          DB_PASSWORD={{ .Data.data.db_password }}
          {{- end }}
    spec:
      serviceAccountName: webapp
      containers:
      - name: webapp
        image: myapp:latest
        # Secret available at /vault/secrets/db-creds
```

---

## Tool 5: OWASP ZAP (DAST — Dynamic Scanning)

```bash
# Quick scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://staging.example.com

# Full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://staging.example.com \
  -r zap-report.html

# API scan
docker run -t owasp/zap2docker-stable zap-api-scan.py \
  -t https://staging.example.com/openapi.json \
  -f openapi
```

### GitHub Actions
```yaml
- name: OWASP ZAP Scan
  uses: zaproxy/action-baseline@v0.10.0
  with:
    target: 'https://staging.example.com'
    rules_file_name: '.zap/rules.tsv'
    fail_action: true
```

---

## Real-Time Project: DevSecOps Pipeline

### Full Pipeline Architecture
```yaml
name: DevSecOps Pipeline
on:
  pull_request:
  push:
    branches: [main]

jobs:
  # Stage 1: Code Quality & SAST
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@v2
      - name: Quality Gate
        uses: SonarSource/sonarqube-quality-gate-action@v1

  # Stage 2: Dependency & Secret Scanning
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Trivy FS Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
      - name: git-secrets check
        run: |
          git secrets --install
          git secrets --register-aws
          git secrets --scan

  # Stage 3: Build & Image Scan
  build-scan:
    needs: [code-quality, dependency-scan]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Image
        run: docker build -t myapp:${{ github.sha }} .
      - name: Trivy Image Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          exit-code: '1'
          severity: CRITICAL

  # Stage 4: IaC Security
  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Checkov Terraform Scan
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/
          soft_fail: false

  # Stage 5: Deploy to Staging + DAST
  deploy-staging:
    needs: [build-scan, iac-scan]
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to Staging
        run: echo "Deploy steps here"
      - name: OWASP ZAP Baseline
        uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'https://staging.example.com'

  # Stage 6: Production (manual approval)
  deploy-production:
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    environment: production  # requires approval
    steps:
      - name: Deploy to Production
        run: echo "Production deploy"
```

### Deliverables
- [ ] SonarQube running with quality gates (coverage > 80%, 0 vulns)
- [ ] Trivy scanning images AND Terraform code
- [ ] Checkov IaC scan with custom policy baseline
- [ ] HashiCorp Vault for secrets (KV + dynamic AWS creds)
- [ ] OWASP ZAP scanning staging environment
- [ ] git-secrets pre-commit hooks preventing AWS key leaks
- [ ] SARIF reports uploaded to GitHub Security tab
- [ ] Pipeline blocks on CRITICAL findings
- [ ] Security dashboard in Grafana
- [ ] Documented exception/bypass process for false positives

---

# Part 2 — AWS-Native Security Services

> The tools above (SonarQube, Trivy, Checkov, Vault, ZAP) handle **pipeline security**. Now we cover **AWS-native services** that protect your cloud infrastructure 24/7.

---

## AWS Security Services Map

```
🛡️ AWS SECURITY ECOSYSTEM

┌──────────────────────────────────────────────────────────────────┐
│                    GOVERNANCE & COMPLIANCE                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ AWS Org SCPs │  │  AWS Config  │  │  AWS Security Hub    │   │
│  │ "Guardrails" │  │ "Compliance  │  │ "Single Pane of      │   │
│  │ Block actions│  │  Auditor"    │  │  Glass for Security"  │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                    THREAT DETECTION                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  GuardDuty   │  │  Inspector   │  │     Macie            │   │
│  │ "24/7 Guard" │  │ "Vulnerability│  │ "Sensitive Data      │   │
│  │ Network+API  │  │  Scanner"    │  │  Discovery"          │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                    INVESTIGATION & RESPONSE                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  CloudTrail  │  │  Detective   │  │  CloudWatch +        │   │
│  │ "CCTV Logs"  │  │ "Forensics   │  │  EventBridge         │   │
│  │ Who did what │  │  Investigator"│  │ "Auto-Remediation"   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                    ACCESS CONTROL                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  IAM Policies│  │  SCP Policies│  │  IAM Access          │   │
│  │ "Who can do  │  │ "Org-wide    │  │  Analyzer            │   │
│  │  what"       │  │  guardrails" │  │ "Find overpermission" │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### How They Work Together (Real-Time Flow)
```
1. GuardDuty detects: "Unusual API call from IP 185.xx.xx.xx"
      │
2. Security Hub aggregates: Finding appears in central dashboard
      │
3. EventBridge triggers: Lambda auto-remediation
      │
4. Lambda executes: Revoke IAM keys + Isolate EC2 + Send SNS alert
      │
5. CloudTrail provides: Full audit trail — who, what, when, from where
      │
6. Detective investigates: Visual graph of the attack chain
      │
7. CloudWatch Dashboard: Real-time security posture visible to SOC team
```

---

## AWS Service 1: AWS Security Hub (Central Security Dashboard)

### Real-World Analogy
Security Hub is like a **security operations center (SOC) control room** with screens showing feeds from every camera (GuardDuty), door sensor (Config), fire alarm (Inspector), and vault monitor (Macie) — all in one place.

### How It Works
```
┌─────────────────────────────────────────────────────┐
│                 AWS SECURITY HUB                      │
│                                                       │
│   Findings from:              Standards:              │
│   ├── GuardDuty               ├── CIS AWS Benchmark  │
│   ├── Inspector               ├── AWS Foundational    │
│   ├── Macie                   ├── PCI DSS             │
│   ├── Config                  └── NIST 800-53         │
│   ├── Firewall Manager                                │
│   ├── IAM Access Analyzer     Severity Scoring:       │
│   └── 3rd Party (Snyk, etc.)  ├── CRITICAL (90-100)  │
│                                ├── HIGH (70-89)       │
│   Outputs:                     ├── MEDIUM (40-69)     │
│   ├── CloudWatch Dashboards    └── LOW (1-39)         │
│   ├── EventBridge Rules                               │
│   ├── S3 Export                                       │
│   └── SIEM Integration                                │
└─────────────────────────────────────────────────────┘
```

### Enable Security Hub
```bash
# Enable Security Hub
aws securityhub enable-security-hub \
    --enable-default-standards \
    --tags Environment=Production

# Enable specific security standard (CIS AWS Benchmark)
aws securityhub batch-enable-standards \
    --standards-subscription-requests '[
        {"StandardsArn": "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"},
        {"StandardsArn": "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"}
    ]'

# List enabled standards
aws securityhub get-enabled-standards

# Get findings (CRITICAL severity)
aws securityhub get-findings \
    --filters '{
        "SeverityLabel": [{"Value": "CRITICAL", "Comparison": "EQUALS"}],
        "WorkflowStatus": [{"Value": "NEW", "Comparison": "EQUALS"}]
    }' \
    --max-items 10

# Get security score
aws securityhub get-security-control-definition \
    --security-control-id "IAM.1"

# Import findings from custom source
aws securityhub batch-import-findings --findings '[{
    "SchemaVersion": "2018-10-08",
    "Id": "custom-finding-001",
    "ProductArn": "arn:aws:securityhub:us-east-1:ACCOUNT:product/ACCOUNT/default",
    "GeneratorId": "custom-scanner",
    "AwsAccountId": "123456789012",
    "Types": ["Software and Configuration Checks"],
    "Title": "S3 bucket has public read access",
    "Description": "Bucket customer-data allows public read",
    "Severity": {"Label": "CRITICAL"},
    "Resources": [{"Type": "AwsS3Bucket", "Id": "arn:aws:s3:::customer-data"}],
    "CreatedAt": "2026-03-03T00:00:00Z",
    "UpdatedAt": "2026-03-03T00:00:00Z"
}]'
```

### Real-Time Example: Multi-Account Security Hub
```
                    ┌──────────────────────────┐
                    │ MANAGEMENT ACCOUNT        │
                    │  Security Hub Admin       │
                    │  - Aggregated dashboard   │
                    │  - Cross-account findings │
                    │  - Central remediation    │
                    └───────────┬──────────────┘
                       ┌────────┼────────┐
                       │        │        │
                 ┌─────┴──┐ ┌──┴─────┐ ┌┴────────┐
                 │ DEV    │ │ STAGING│ │ PROD    │
                 │Account │ │Account │ │Account  │
                 │GuardDuty│ │GuardDuty│ │GuardDuty│
                 │Inspector│ │Inspector│ │Inspector│
                 │Config   │ │Config   │ │Config   │
                 └────────┘ └────────┘ └─────────┘
```

```bash
# Designate admin account (from Org management account)
aws securityhub enable-organization-admin-account \
    --admin-account-id 111111111111

# From admin account — enable for all org members
aws securityhub create-members \
    --account-details '[
        {"AccountId": "222222222222"},
        {"AccountId": "333333333333"}
    ]'

# Create aggregation region
aws securityhub create-finding-aggregator \
    --region-linking-mode ALL_REGIONS
```

---

## AWS Service 2: Amazon GuardDuty (Threat Detection)

### Real-World Analogy
GuardDuty is a **24/7 security guard with AI-powered cameras** that watches your VPC flow logs, DNS logs, CloudTrail events, and EKS audit logs — and alerts you when something suspicious happens.

### What GuardDuty Monitors
```
DATA SOURCES                    THREAT TYPES DETECTED
┌────────────────┐
│ VPC Flow Logs  │──→  Port scanning, unusual traffic, crypto mining
│ DNS Logs       │──→  C&C communication, DNS exfiltration
│ CloudTrail     │──→  Unusual API calls, credential compromise
│ S3 Data Events │──→  Suspicious bucket access patterns
│ EKS Audit Logs │──→  Rogue containers, privilege escalation
│ Lambda Network │──→  Malicious function behavior
│ RDS Login      │──→  Brute force, anomalous DB access
└────────────────┘

FINDING TYPES (200+):
├── Recon:   Port probe, API enumeration
├── UnauthorizedAccess:  Console login from unusual IP
├── Trojan:  EC2 communicating with known malware server
├── CryptoCurrency:  EC2 mining Bitcoin
├── Exfiltration:  Unusual S3 data transfer
├── Impact:  Denial of Service attempts
└── Stealth:  CloudTrail logging disabled
```

### Enable & Configure GuardDuty
```bash
# Enable GuardDuty
aws guardduty create-detector \
    --enable \
    --data-sources '{
        "S3Logs": {"Enable": true},
        "Kubernetes": {"AuditLogs": {"Enable": true}},
        "MalwareProtection": {"ScanEc2InstanceWithFindings": {"EbsVolumes": true}}
    }'

# Get detector ID
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)

# List findings (sorted by severity)
aws guardduty list-findings \
    --detector-id $DETECTOR_ID \
    --finding-criteria '{
        "Criterion": {
            "severity": {"Gte": 7}
        }
    }' \
    --sort-criteria '{"AttributeName": "severity", "OrderBy": "DESC"}'

# Get finding details
aws guardduty get-findings \
    --detector-id $DETECTOR_ID \
    --finding-ids "finding-id-here"

# Create threat intel set (custom IPs to watch)
aws guardduty create-threat-intel-set \
    --detector-id $DETECTOR_ID \
    --name "blocked-ips" \
    --format TXT \
    --location s3://my-threat-intel/blocked-ips.txt \
    --activate

# Create IP set (trusted IPs to ignore)
aws guardduty create-ip-set \
    --detector-id $DETECTOR_ID \
    --name "office-ips" \
    --format TXT \
    --location s3://my-threat-intel/trusted-ips.txt \
    --activate

# Suppress low-value findings (reduce noise)
aws guardduty create-filter \
    --detector-id $DETECTOR_ID \
    --name "suppress-port-scan-from-scanners" \
    --action ARCHIVE \
    --finding-criteria '{
        "Criterion": {
            "type": {"Eq": ["Recon:EC2/PortProbeUnprotectedPort"]},
            "service.action.portProbeAction.portProbeDetails.remoteIpDetails.ipAddressV4": {
                "Eq": ["203.0.113.0/24"]
            }
        }
    }'
```

### Real-Time Example: Crypto Mining Detection & Auto-Remediation
```
SCENARIO: An attacker compromises an EC2 instance and starts Bitcoin mining.

TIMELINE:
  00:00 — Attacker exploits unpatched vulnerability on EC2
  00:05 — Attacker installs crypto miner, connects to mining pool
  00:06 — GuardDuty detects: CryptoCurrency:EC2/BitcoinTool.B!DNS
  00:06 — EventBridge rule triggers Lambda function
  00:07 — Lambda: Isolates EC2 (replace SG with no-egress SG)
  00:07 — Lambda: Creates EBS snapshot (forensic evidence)
  00:07 — Lambda: Sends PagerDuty alert to on-call engineer
  00:08 — Lambda: Notifies Security Hub (finding updated)
  00:10 — Engineer reviews in Detective (visual attack graph)
```

```bash
# EventBridge rule for GuardDuty cryptocurrency findings
aws events put-rule \
    --name "guardduty-crypto-mining" \
    --event-pattern '{
        "source": ["aws.guardduty"],
        "detail-type": ["GuardDuty Finding"],
        "detail": {
            "type": [{"prefix": "CryptoCurrency:"}],
            "severity": [{"numeric": [">=", 7]}]
        }
    }'
```

### Auto-Remediation Lambda
```python
# lambda_function.py — GuardDuty Auto-Remediation
import boto3
import json
import os

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

ISOLATION_SG = os.environ['ISOLATION_SG_ID']       # SG with no ingress/egress
SNS_TOPIC = os.environ['SECURITY_SNS_TOPIC_ARN']

def lambda_handler(event, context):
    finding = event['detail']
    finding_type = finding['type']
    severity = finding['severity']
    
    # Extract instance ID from finding
    instance_id = finding['resource']['instanceDetails']['instanceId']
    account_id = finding['accountId']
    region = finding['region']
    
    print(f"[ALERT] {finding_type} on {instance_id} (severity: {severity})")
    
    actions_taken = []
    
    # Step 1: Isolate the instance (replace security groups)
    try:
        ec2.modify_instance_attribute(
            InstanceId=instance_id,
            Groups=[ISOLATION_SG]
        )
        actions_taken.append(f"Isolated {instance_id} with SG {ISOLATION_SG}")
    except Exception as e:
        actions_taken.append(f"FAILED to isolate: {str(e)}")
    
    # Step 2: Tag instance as compromised
    try:
        ec2.create_tags(
            Resources=[instance_id],
            Tags=[
                {'Key': 'SecurityStatus', 'Value': 'COMPROMISED'},
                {'Key': 'GuardDutyFinding', 'Value': finding_type},
                {'Key': 'IsolatedAt', 'Value': context.invoked_function_arn}
            ]
        )
        actions_taken.append("Tagged instance as COMPROMISED")
    except Exception as e:
        actions_taken.append(f"FAILED to tag: {str(e)}")
    
    # Step 3: Snapshot EBS volumes (forensic evidence)
    try:
        volumes = ec2.describe_instances(
            InstanceIds=[instance_id]
        )['Reservations'][0]['Instances'][0]['BlockDeviceMappings']
        
        for vol in volumes:
            vol_id = vol['Ebs']['VolumeId']
            snap = ec2.create_snapshot(
                VolumeId=vol_id,
                Description=f"Forensic snapshot - GuardDuty {finding_type}",
                TagSpecifications=[{
                    'ResourceType': 'snapshot',
                    'Tags': [{'Key': 'Purpose', 'Value': 'Forensics'}]
                }]
            )
            actions_taken.append(f"Snapshot created: {snap['SnapshotId']}")
    except Exception as e:
        actions_taken.append(f"FAILED to snapshot: {str(e)}")
    
    # Step 4: Send SNS alert
    message = {
        'finding_type': finding_type,
        'severity': severity,
        'instance_id': instance_id,
        'account': account_id,
        'region': region,
        'actions_taken': actions_taken,
        'next_steps': [
            'Review in AWS Detective for attack chain',
            'Check CloudTrail for attacker activity',
            'Determine root cause (patch missing?)',
            'Decide: terminate or investigate further'
        ]
    }
    
    sns.publish(
        TopicArn=SNS_TOPIC,
        Subject=f"[CRITICAL] GuardDuty: {finding_type} on {instance_id}",
        Message=json.dumps(message, indent=2)
    )
    actions_taken.append("SNS alert sent")
    
    return {
        'statusCode': 200,
        'body': json.dumps({'actions': actions_taken})
    }
```

---

## AWS Service 3: CloudTrail (Security Audit & Forensics)

### Real-World Analogy
CloudTrail is the **CCTV recording system** for your AWS account — every API call is logged with who, what, when, from where, and whether it succeeded or failed.

### Trail Configuration for Security
```bash
# Create organization-wide trail with all features
aws cloudtrail create-trail \
    --name security-audit-trail \
    --s3-bucket-name security-cloudtrail-logs-ACCT \
    --is-multi-region-trail \
    --enable-log-file-validation \
    --include-global-service-events \
    --is-organization-trail \
    --kms-key-id arn:aws:kms:us-east-1:ACCT:key/KEY-ID \
    --cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:ACCT:log-group:CloudTrail:* \
    --cloud-watch-logs-role-arn arn:aws:iam::ACCT:role/CloudTrailCWLRole

# Start logging
aws cloudtrail start-logging --name security-audit-trail

# Enable data events (S3 + Lambda)
aws cloudtrail put-event-selectors \
    --trail-name security-audit-trail \
    --advanced-event-selectors '[
        {
            "Name": "Log all S3 data events",
            "FieldSelectors": [
                {"Field": "eventCategory", "Equals": ["Data"]},
                {"Field": "resources.type", "Equals": ["AWS::S3::Object"]}
            ]
        },
        {
            "Name": "Log all Lambda invocations",
            "FieldSelectors": [
                {"Field": "eventCategory", "Equals": ["Data"]},
                {"Field": "resources.type", "Equals": ["AWS::Lambda::Function"]}
            ]
        }
    ]'

# Enable CloudTrail Insights (anomaly detection)
aws cloudtrail put-insight-selectors \
    --trail-name security-audit-trail \
    --insight-selectors '[
        {"InsightType": "ApiCallRateInsight"},
        {"InsightType": "ApiErrorRateInsight"}
    ]'
```

### Real-Time Example: Security Incident Investigation
```
SCENARIO: Unauthorized data exfiltration suspected. 3 AM: someone downloaded
all customer data from S3.

INVESTIGATION WITH CLOUDTRAIL:
```

```bash
# Step 1: Who accessed the bucket at 3 AM?
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceName,AttributeValue=customer-data-bucket \
    --start-time "2026-03-02T02:00:00Z" \
    --end-time "2026-03-02T05:00:00Z" \
    --query 'Events[].{Time:EventTime,User:Username,Event:EventName,IP:sourceIPAddress}'

# Step 2: What else did this user do? (timeline of all their actions)
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=Username,AttributeValue=suspicious-user \
    --start-time "2026-03-01T00:00:00Z" \
    --end-time "2026-03-03T00:00:00Z"

# Step 3: Query with Athena (complex investigation)
# First, create Athena table for CloudTrail logs
```

```sql
-- Athena: Create table for CloudTrail analysis
CREATE EXTERNAL TABLE cloudtrail_logs (
    eventVersion STRING,
    userIdentity STRUCT<
        type: STRING,
        principalId: STRING,
        arn: STRING,
        accountId: STRING,
        invokedBy: STRING,
        accessKeyId: STRING,
        userName: STRING,
        sessionContext: STRUCT<
            attributes: STRUCT<mfaAuthenticated: STRING, creationDate: STRING>,
            sessionIssuer: STRUCT<type: STRING, principalId: STRING, arn: STRING, accountId: STRING, userName: STRING>
        >
    >,
    eventTime STRING,
    eventSource STRING,
    eventName STRING,
    awsRegion STRING,
    sourceIPAddress STRING,
    userAgent STRING,
    errorCode STRING,
    errorMessage STRING,
    requestParameters STRING,
    responseElements STRING,
    resources ARRAY<STRUCT<arn: STRING, accountId: STRING, type: STRING>>
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
LOCATION 's3://security-cloudtrail-logs-ACCT/AWSLogs/ACCT/CloudTrail/';

-- Find all console logins without MFA
SELECT eventTime, userIdentity.userName, sourceIPAddress, userAgent
FROM cloudtrail_logs
WHERE eventName = 'ConsoleLogin'
  AND userIdentity.sessionContext.attributes.mfaAuthenticated = 'false'
ORDER BY eventTime DESC;

-- Find all IAM key creation events (attackers create keys for persistence)
SELECT eventTime, userIdentity.userName, sourceIPAddress,
       json_extract(responseElements, '$.accessKey.accessKeyId') as new_key_id
FROM cloudtrail_logs
WHERE eventName = 'CreateAccessKey'
ORDER BY eventTime DESC;

-- Find unauthorized S3 access attempts (AccessDenied errors)
SELECT eventTime, userIdentity.arn, eventName, errorCode,
       json_extract(requestParameters, '$.bucketName') as bucket
FROM cloudtrail_logs
WHERE errorCode = 'AccessDenied'
  AND eventSource = 's3.amazonaws.com'
ORDER BY eventTime DESC
LIMIT 100;

-- Find all actions from a specific IP (attacker investigation)
SELECT eventTime, eventName, eventSource, userIdentity.arn
FROM cloudtrail_logs
WHERE sourceIPAddress = '185.xx.xx.xx'
ORDER BY eventTime ASC;
```

### Dangerous API Calls to Alert On
```bash
# Events that should ALWAYS trigger an alert
CRITICAL_EVENTS=(
    "ConsoleLogin"                    # Console access (especially without MFA)
    "CreateAccessKey"                 # New IAM keys = persistence
    "DeleteTrail"                     # Attacker hiding tracks
    "StopLogging"                     # Attacker disabling audit
    "PutBucketPolicy"                 # Changing S3 permissions
    "AuthorizeSecurityGroupIngress"   # Opening firewall
    "CreateUser"                      # Rogue user creation
    "AttachUserPolicy"                # Privilege escalation
    "RunInstances"                    # Crypto mining launch
    "PutBucketPublicAccessBlock"      # Making data public
    "DisableKey"                      # KMS key disabled (ransomware)
    "DeleteBucket"                    # Data destruction
    "ModifySnapshotAttribute"         # Sharing snapshots externally
)
```

---

## AWS Service 4: SCP Policies (Organization Guardrails)

### Real-World Analogy
SCPs are like **building codes for a city** — individual building owners (accounts) can decorate their rooms however they want, but they CANNOT remove fire exits, build above 50 floors, or use banned materials. SCPs set the **maximum boundary** of what's allowed.

### How SCPs Work
```
                    ┌──────────────────────────┐
                    │   ROOT (Management Acct)  │
                    │   SCP: FullAWSAccess      │
                    └───────────┬──────────────┘
                         ┌──────┴──────┐
                    ┌────┴────┐  ┌─────┴─────┐
                    │ PROD OU │  │  DEV OU    │
                    │ SCP:    │  │  SCP:      │
                    │ -Deny   │  │  -Deny     │
                    │  delete │  │   prod     │
                    │  trail  │  │   access   │
                    │ -Deny   │  │  -Deny     │
                    │  leave  │  │   large    │
                    │  org    │  │   EC2s     │
                    └────┬────┘  └─────┬─────┘
                    ┌────┴────┐  ┌─────┴─────┐
                    │ Account │  │  Account   │
                    │ Even    │  │  Dev team  │
                    │ admin   │  │  can only  │
                    │ CANNOT  │  │  use t3.*  │
                    │ delete  │  │  instances │
                    │ trail   │  │            │
                    └─────────┘  └────────────┘

EFFECTIVE PERMISSIONS = IAM Policy ∩ SCP ∩ Permission Boundary
(Intersection — ALL must allow for action to succeed)
```

### Essential SCP Policies (Copy-Paste Ready)

#### SCP 1: Prevent CloudTrail Tampering
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PreventCloudTrailTampering",
            "Effect": "Deny",
            "Action": [
                "cloudtrail:StopLogging",
                "cloudtrail:DeleteTrail",
                "cloudtrail:UpdateTrail",
                "cloudtrail:PutEventSelectors"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:PrincipalArn": "arn:aws:iam::*:role/SecurityAdminRole"
                }
            }
        }
    ]
}
```

#### SCP 2: Enforce Region Restriction (Data Sovereignty)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyOutsideAllowedRegions",
            "Effect": "Deny",
            "NotAction": [
                "iam:*",
                "organizations:*",
                "sts:*",
                "support:*",
                "budgets:*",
                "cloudfront:*",
                "route53:*",
                "waf:*",
                "trustedadvisor:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": [
                        "us-east-1",
                        "us-west-2",
                        "eu-west-1"
                    ]
                }
            }
        }
    ]
}
```

#### SCP 3: Prevent Leaving the Organization
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyLeaveOrg",
            "Effect": "Deny",
            "Action": "organizations:LeaveOrganization",
            "Resource": "*"
        }
    ]
}
```

#### SCP 4: Deny Root User Actions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyRootUser",
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:PrincipalArn": "arn:aws:iam::*:root"
                }
            }
        }
    ]
}
```

#### SCP 5: Enforce Encryption on S3
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyUnencryptedS3",
            "Effect": "Deny",
            "Action": "s3:PutObject",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": ["aws:kms", "AES256"]
                }
            }
        },
        {
            "Sid": "DenyNoEncryptionHeader",
            "Effect": "Deny",
            "Action": "s3:PutObject",
            "Resource": "*",
            "Condition": {
                "Null": {
                    "s3:x-amz-server-side-encryption": "true"
                }
            }
        }
    ]
}
```

#### SCP 6: Restrict EC2 Instance Types (Cost + Security)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyLargeInstances",
            "Effect": "Deny",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "ForAnyValue:StringNotLike": {
                    "ec2:InstanceType": [
                        "t3.*",
                        "t3a.*",
                        "m5.large",
                        "m5.xlarge"
                    ]
                }
            }
        }
    ]
}
```

### Apply SCPs
```bash
# Create SCP
aws organizations create-policy \
    --name "prevent-cloudtrail-tampering" \
    --description "Prevent anyone from disabling CloudTrail" \
    --content file://scp-cloudtrail.json \
    --type SERVICE_CONTROL_POLICY

# Attach SCP to Production OU
aws organizations attach-policy \
    --policy-id p-XXXXXXXXX \
    --target-id ou-XXXX-XXXXXXXX

# List all SCPs
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Detach SCP (with caution)
aws organizations detach-policy \
    --policy-id p-XXXXXXXXX \
    --target-id ou-XXXX-XXXXXXXX
```

---

## AWS Service 5: IAM Security Policies (Real-Time)

### IAM Policy Evaluation Logic
```
REQUEST COMES IN: "User wants to s3:DeleteBucket"
         │
    ┌────┴─────────────────────┐
    │ 1. Is there an EXPLICIT   │
    │    DENY anywhere?         │──── YES ──→ ❌ DENIED
    └────┬─────────────────────┘
         │ NO
    ┌────┴─────────────────────┐
    │ 2. Is there an SCP that   │
    │    allows it?             │──── NO ───→ ❌ DENIED
    └────┬─────────────────────┘
         │ YES
    ┌────┴─────────────────────┐
    │ 3. Is there a Permission  │
    │    Boundary that allows?  │──── NO ───→ ❌ DENIED
    └────┬─────────────────────┘
         │ YES
    ┌────┴─────────────────────┐
    │ 4. Is there an IAM Policy │
    │    that ALLOWS it?        │──── NO ───→ ❌ DENIED
    └────┬─────────────────────┘
         │ YES
         ▼
    ✅ ALLOWED
```

### Essential Security IAM Policies

#### Policy 1: Enforce MFA for All Actions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowOnlyWithMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:GetUser",
                "iam:ListMFADevices",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice",
                "sts:GetSessionToken"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
```

#### Policy 2: Developers — Read-Only Production + Full Dev
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "FullAccessDevEnvironment",
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "dev"
                }
            }
        },
        {
            "Sid": "ReadOnlyProduction",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "s3:Get*",
                "s3:List*",
                "rds:Describe*",
                "logs:Get*",
                "logs:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "prod"
                }
            }
        },
        {
            "Sid": "DenyProductionModification",
            "Effect": "Deny",
            "Action": [
                "ec2:TerminateInstances",
                "ec2:StopInstances",
                "rds:DeleteDBInstance",
                "rds:DeleteDBCluster",
                "s3:DeleteBucket",
                "s3:DeleteObject"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "prod"
                }
            }
        }
    ]
}
```

#### Policy 3: CI/CD Pipeline Role (Minimal Permissions)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECRAccess",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "arn:aws:ecr:us-east-1:ACCT:repository/myapp"
        },
        {
            "Sid": "ECSDeployment",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/ManagedBy": "ci-cd"
                }
            }
        },
        {
            "Sid": "DenyDangerousActions",
            "Effect": "Deny",
            "Action": [
                "iam:*",
                "organizations:*",
                "ec2:*SecurityGroup*",
                "ec2:*Vpc*"
            ],
            "Resource": "*"
        }
    ]
}
```

### IAM Access Analyzer
```bash
# Create IAM Access Analyzer (find overpermissioned resources)
aws accessanalyzer create-analyzer \
    --analyzer-name org-analyzer \
    --type ORGANIZATION

# List findings (external access detected)
aws accessanalyzer list-findings \
    --analyzer-arn arn:aws:access-analyzer:us-east-1:ACCT:analyzer/org-analyzer \
    --filter '{
        "status": {"eq": ["ACTIVE"]},
        "resourceType": {"eq": ["AWS::S3::Bucket"]}
    }'

# Generate policy from CloudTrail activity (least privilege)
aws accessanalyzer start-policy-generation \
    --policy-generation-details '{
        "principalArn": "arn:aws:iam::ACCT:role/MyAppRole",
        "cloudTrailDetails": {
            "trailArn": "arn:aws:cloudtrail:us-east-1:ACCT:trail/security-trail",
            "startTime": "2026-01-01T00:00:00Z",
            "endTime": "2026-03-03T00:00:00Z"
        }
    }'
# This generates a LEAST-PRIVILEGE policy based on actual API usage!
```

---

## AWS Service 6: CloudWatch for Security Monitoring

### Real-World Analogy
CloudWatch for security is like **a security alarm system** — you set up sensors (metric filters) on doors and windows (log groups), define conditions (when door opens after midnight), and trigger alarms (alerts + auto-remediation).

### Security Metric Filters (CloudTrail → CloudWatch)
```bash
# Create log group for CloudTrail
aws logs create-log-group --log-group-name /aws/cloudtrail/security

# FILTER 1: Unauthorized API Calls
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name UnauthorizedAPICalls \
    --filter-pattern '{ ($.errorCode = "*UnauthorizedAccess*") || ($.errorCode = "AccessDenied*") }' \
    --metric-transformations \
        metricName=UnauthorizedAPICalls,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 2: Console Login Without MFA
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name ConsoleLoginWithoutMFA \
    --filter-pattern '{ ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }' \
    --metric-transformations \
        metricName=ConsoleLoginNoMFA,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 3: Root Account Usage
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name RootAccountUsage \
    --filter-pattern '{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }' \
    --metric-transformations \
        metricName=RootAccountUsage,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 4: IAM Policy Changes
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name IAMPolicyChanges \
    --filter-pattern '{ ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=PutUserPolicy) }' \
    --metric-transformations \
        metricName=IAMPolicyChanges,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 5: Security Group Changes
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name SecurityGroupChanges \
    --filter-pattern '{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }' \
    --metric-transformations \
        metricName=SecurityGroupChanges,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 6: NACL Changes
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name NACLChanges \
    --filter-pattern '{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) }' \
    --metric-transformations \
        metricName=NACLChanges,metricNamespace=SecurityMetrics,metricValue=1

# FILTER 7: S3 Bucket Policy Changes
aws logs put-metric-filter \
    --log-group-name /aws/cloudtrail/security \
    --filter-name S3BucketPolicyChanges \
    --filter-pattern '{ ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketAcl) || ($.eventName = PutBucketPublicAccessBlock) || ($.eventName = DeleteBucketPolicy) }' \
    --metric-transformations \
        metricName=S3BucketPolicyChanges,metricNamespace=SecurityMetrics,metricValue=1
```

### Create Alarms for Security Events
```bash
# Alarm: Root Account Used
aws cloudwatch put-metric-alarm \
    --alarm-name "CRITICAL-RootAccountUsage" \
    --alarm-description "Root account was used — investigate immediately" \
    --metric-name RootAccountUsage \
    --namespace SecurityMetrics \
    --statistic Sum \
    --period 300 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:security-critical-alerts \
    --treat-missing-data notBreaching

# Alarm: Console Login Without MFA
aws cloudwatch put-metric-alarm \
    --alarm-name "HIGH-ConsoleLoginNoMFA" \
    --alarm-description "Console login without MFA detected" \
    --metric-name ConsoleLoginNoMFA \
    --namespace SecurityMetrics \
    --statistic Sum \
    --period 300 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:security-high-alerts

# Alarm: Excessive Unauthorized API Calls (brute force)
aws cloudwatch put-metric-alarm \
    --alarm-name "HIGH-ExcessiveUnauthorizedCalls" \
    --alarm-description "More than 10 unauthorized API calls in 5 minutes" \
    --metric-name UnauthorizedAPICalls \
    --namespace SecurityMetrics \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:security-high-alerts
```

---

## AWS Service 7: Amazon Inspector (Vulnerability Scanning)

### Real-World Analogy
Inspector is like a **health inspector visiting a restaurant** — it checks EC2 instances, Lambda functions, and ECR images for known vulnerabilities (CVEs) and network exposure, then gives you a checklist of what to fix.

### Enable & Use Inspector
```bash
# Enable Inspector v2
aws inspector2 enable \
    --resource-types EC2 ECR_CONTAINER_IMAGE LAMBDA LAMBDA_CODE

# Check what's being scanned
aws inspector2 list-coverage \
    --filter-criteria '{
        "resourceType": [{"comparison": "EQUALS", "value": "AWS_EC2_INSTANCE"}]
    }'

# List findings by severity
aws inspector2 list-findings \
    --filter-criteria '{
        "severity": [{"comparison": "EQUALS", "value": "CRITICAL"}],
        "findingStatus": [{"comparison": "EQUALS", "value": "ACTIVE"}]
    }' \
    --sort-criteria '{"field": "SEVERITY", "sortOrder": "DESC"}'

# Get vulnerability count summary
aws inspector2 list-finding-aggregations \
    --aggregation-type FINDING_TYPE

# Export findings to S3 (for compliance reporting)
aws inspector2 create-findings-report \
    --filter-criteria '{
        "severity": [{"comparison": "EQUALS", "value": "CRITICAL"},
                      {"comparison": "EQUALS", "value": "HIGH"}]
    }' \
    --report-format CSV \
    --s3-destination '{
        "bucketName": "security-reports-ACCT",
        "keyPrefix": "inspector/monthly",
        "kmsKeyArn": "arn:aws:kms:us-east-1:ACCT:key/KEY-ID"
    }'
```

### Real-Time Example: CI/CD ECR Image Scanning
```
 Developer pushes image → ECR → Inspector auto-scans → EventBridge → Block deploy

┌───────────┐     ┌──────┐     ┌──────────┐     ┌────────────┐
│ docker    │────→│ ECR  │────→│Inspector │────→│EventBridge │
│ push      │     │ Repo │     │ Scans    │     │ Rule       │
└───────────┘     └──────┘     └──────────┘     └─────┬──────┘
                                                       │
                    ┌──────────────────────────────────┤
                    │                                   │
              ┌─────┴─────┐                      ┌─────┴──────┐
              │ Lambda    │                      │ SNS Alert  │
              │ Block ECS │                      │ "CRITICAL  │
              │ Deploy    │                      │  CVE found"│
              └───────────┘                      └────────────┘
```

```bash
# EventBridge rule: Inspector finds CRITICAL in ECR image
aws events put-rule \
    --name "inspector-critical-ecr" \
    --event-pattern '{
        "source": ["aws.inspector2"],
        "detail-type": ["Inspector2 Finding"],
        "detail": {
            "severity": ["CRITICAL"],
            "status": ["ACTIVE"],
            "type": [{"prefix": "Package Vulnerability"}]
        }
    }'
```

---

## AWS Service 8: Amazon Macie (Sensitive Data Discovery)

### Real-World Analogy
Macie is like a **privacy detective** that scans your S3 buckets looking for sensitive data: credit card numbers, SSNs, API keys, medical records — data that shouldn't be stored unprotected.

### Enable & Configure Macie
```bash
# Enable Macie
aws macie2 enable-macie

# Create classification job (scan specific buckets)
aws macie2 create-classification-job \
    --job-type ONE_TIME \
    --name "scan-customer-data" \
    --s3-job-definition '{
        "bucketDefinitions": [{
            "accountId": "123456789012",
            "buckets": ["customer-uploads", "app-logs", "database-backups"]
        }]
    }' \
    --managed-data-identifier-ids '[
        "CREDIT_CARD_NUMBER",
        "AWS_CREDENTIALS",
        "US_SOCIAL_SECURITY_NUMBER",
        "EMAIL_ADDRESS",
        "US_PASSPORT_NUMBER"
    ]'

# Create SCHEDULED job (weekly scan)
aws macie2 create-classification-job \
    --job-type SCHEDULED \
    --name "weekly-sensitive-data-scan" \
    --schedule-frequency-details '{
        "weekly": {"dayOfWeek": "MONDAY"}
    }' \
    --s3-job-definition '{
        "bucketCriteria": {
            "includes": {
                "and": [{
                    "simpleCriterion": {
                        "key": "S3_BUCKET_NAME",
                        "comparator": "STARTS_WITH",
                        "values": ["prod-", "customer-"]
                    }
                }]
            }
        }
    }'

# List findings
aws macie2 list-findings \
    --finding-criteria '{
        "criterion": {
            "severity.description": {"eq": ["High", "Critical"]},
            "category": {"eq": ["CLASSIFICATION"]}
        }
    }' \
    --sort-criteria '{"attributeName": "severity.score", "orderBy": "DESC"}'
```

### What Macie Detects
```
SENSITIVE DATA TYPES:
├── Financial:     Credit cards, bank account numbers
├── Personal (PII): SSN, passport, driver's license, DOB
├── Credentials:   AWS keys, private keys, API tokens
├── Medical (PHI):  Patient IDs, health records
├── Custom:        Your own regex patterns (employee IDs, etc.)

BUCKET RISKS:
├── Public buckets
├── Unencrypted buckets
├── Buckets with overly permissive policies
├── Cross-account shared buckets
└── Buckets not using versioning
```

---

## AWS Service 9: Amazon Detective (Security Investigation)

### Real-World Analogy
Detective is like a **crime scene investigator with a timeline whiteboard** — it automatically builds a visual graph of relationships between IP addresses, IAM users, EC2 instances, and API calls to help you trace the full attack chain.

### How Detective Works
```
DATA SOURCES (automatic):           INVESTIGATION CAPABILITIES:
├── CloudTrail logs                  ├── Entity profiles (user/IP/instance)
├── VPC Flow Logs                    ├── Visual timeline of all actions
├── GuardDuty findings               ├── Geolocation mapping
├── EKS audit logs                   ├── Anomaly detection graphs
└── S3 data events                   └── Cross-account investigation

INVESTIGATION FLOW:
  1. GuardDuty finding → "Unusual API from 185.xx.xx.xx"
  2. Detective → Show ALL entities linked to that IP
  3. Graph shows → IP → assumed Role → launched 20 EC2 → mined crypto
  4. Timeline → Exact sequence with every API call
  5. Scope → Which other accounts/resources were accessed?
```

```bash
# Enable Detective
aws detective create-graph --tags '{"Environment": "Security"}'

# Add member accounts
aws detective create-members \
    --graph-arn arn:aws:detective:us-east-1:ACCT:graph/GRAPH-ID \
    --accounts '[
        {"AccountId": "222222222222", "EmailAddress": "dev@company.com"},
        {"AccountId": "333333333333", "EmailAddress": "prod@company.com"}
    ]'
```

---

## AWS Service 10: AWS Config for Security Compliance

### Security-Focused Config Rules
```bash
# Enable Config recorder
aws configservice put-configuration-recorder \
    --configuration-recorder name=security-recorder,roleARN=arn:aws:iam::ACCT:role/ConfigRole \
    --recording-group allSupported=true,includeGlobalResourceTypes=true

# Start recording
aws configservice start-configuration-recorder --configuration-recorder-name security-recorder

# RULE 1: S3 bucket public read prohibited
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "s3-bucket-public-read-prohibited",
    "Source": {"Owner": "AWS", "SourceIdentifier": "S3_BUCKET_PUBLIC_READ_PROHIBITED"},
    "MaximumExecutionFrequency": "One_Hour"
}'

# RULE 2: RDS encryption enabled
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "rds-storage-encrypted",
    "Source": {"Owner": "AWS", "SourceIdentifier": "RDS_STORAGE_ENCRYPTED"}
}'

# RULE 3: EC2 instances require IMDSv2
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "ec2-imdsv2-check",
    "Source": {"Owner": "AWS", "SourceIdentifier": "EC2_IMDSV2_CHECK"}
}'

# RULE 4: Security groups — no unrestricted SSH
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "restricted-ssh",
    "Source": {"Owner": "AWS", "SourceIdentifier": "INCOMING_SSH_DISABLED"}
}'

# RULE 5: Root account MFA enabled
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "root-account-mfa-enabled",
    "Source": {"Owner": "AWS", "SourceIdentifier": "ROOT_ACCOUNT_MFA_ENABLED"}
}'

# RULE 6: Access keys rotated every 90 days
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "access-keys-rotated",
    "Source": {"Owner": "AWS", "SourceIdentifier": "ACCESS_KEYS_ROTATED"},
    "InputParameters": "{\"maxAccessKeyAge\": \"90\"}"
}'

# RULE 7: CloudTrail enabled in all regions
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "cloud-trail-enabled",
    "Source": {"Owner": "AWS", "SourceIdentifier": "CLOUD_TRAIL_ENABLED"}
}'
```

### Auto-Remediation with Config + SSM
```bash
# Auto-remediate: Enable S3 encryption when non-compliant
aws configservice put-remediation-configurations --remediation-configurations '[{
    "ConfigRuleName": "s3-bucket-encryption-enabled",
    "TargetType": "SSM_DOCUMENT",
    "TargetId": "AWS-EnableS3BucketEncryption",
    "Parameters": {
        "BucketName": {
            "ResourceValue": {"Value": "RESOURCE_ID"}
        },
        "SSEAlgorithm": {
            "StaticValue": {"Values": ["aws:kms"]}
        }
    },
    "Automatic": true,
    "MaximumAutomaticAttempts": 3,
    "RetryAttemptSeconds": 60
}]'

# Auto-remediate: Remove public access from S3 buckets
aws configservice put-remediation-configurations --remediation-configurations '[{
    "ConfigRuleName": "s3-bucket-public-read-prohibited",
    "TargetType": "SSM_DOCUMENT",
    "TargetId": "AWS-DisableS3BucketPublicReadWrite",
    "Parameters": {
        "S3BucketName": {
            "ResourceValue": {"Value": "RESOURCE_ID"}
        }
    },
    "Automatic": true,
    "MaximumAutomaticAttempts": 3,
    "RetryAttemptSeconds": 60
}]'
```

---

## AWS Service 11: Amazon EventBridge (Security Event Router)

### What Is EventBridge?

EventBridge is the **central nervous system** of your security architecture. It's an event bus that receives events from AWS services (GuardDuty, Security Hub, Config, CloudTrail) and routes them to the right target (Lambda, SNS, SQS) based on rules you define.

**Think of it as a Smart Post Office:**
- Letters (events) arrive from different senders (GuardDuty, Config, etc.)
- Postal workers (rules) read the envelope label (event pattern)
- They route each letter to the correct mailbox (target: Lambda, SNS, etc.)
- Some letters go to multiple mailboxes (one event → multiple targets)

### How EventBridge Works in Security

```
EVENTS COME IN FROM:                  RULES MATCH PATTERNS:              TARGETS TAKE ACTION:
┌──────────────┐                     ┌──────────────────┐               ┌──────────────────┐
│ GuardDuty    │──→ Finding event    │ IF severity >= 7 │──→ Route to │ Lambda: Isolate  │
│              │    (JSON payload)   │ AND type=Crypto   │              │ EC2 instance     │
└──────────────┘                     └──────────────────┘               └──────────────────┘
┌──────────────┐                     ┌──────────────────┐               ┌──────────────────┐
│ Security Hub │──→ Finding imported │ IF S3 public     │──→ Route to │ Lambda: Block    │
│              │                     │ AND severity=CRIT │              │ public access    │
└──────────────┘                     └──────────────────┘               └──────────────────┘
┌──────────────┐                     ┌──────────────────┐               ┌──────────────────┐
│ CloudTrail   │──→ API call event   │ IF event=         │──→ Route to │ SNS: Alert team  │
│              │                     │   StopLogging     │              │ immediately      │
└──────────────┘                     └──────────────────┘               └──────────────────┘
┌──────────────┐                     ┌──────────────────┐               ┌──────────────────┐
│ Config       │──→ Compliance change│ IF status=        │──→ Route to │ Lambda: Auto-fix │
│              │                     │   NON_COMPLIANT   │              │ config drift     │
└──────────────┘                     └──────────────────┘               └──────────────────┘
```

### Why EventBridge Is Critical for Security

| Without EventBridge | With EventBridge |
|---------------------|------------------|
| GuardDuty finds threat → sits in console → someone checks hours later | GuardDuty finds threat → EventBridge → Lambda isolates in 5 seconds |
| Config detects public S3 → email sent → engineer fixes next day | Config detects public S3 → EventBridge → Lambda blocks in 3 seconds |
| Root login happens → nobody notices for weeks | Root login → EventBridge → SNS → PagerDuty alert in 2 seconds |

### Real-Time Example: 6 Security Rules Running 24/7

```
YOUR EVENTBRIDGE SECURITY RULES:

Rule 1: "guardduty-critical"
  WHEN: GuardDuty finding with severity >= 7 (CRITICAL/HIGH)
  THEN: → Lambda (isolate EC2 + snapshot + tag)
        → SNS (PagerDuty P1 alert)

Rule 2: "s3-public-detected"
  WHEN: Security Hub finding = S3 bucket public access
  THEN: → Lambda (enable Block Public Access + KMS encryption)
        → SNS (Slack #security-alerts)

Rule 3: "iam-key-compromise"
  WHEN: GuardDuty finding type starts with "UnauthorizedAccess:IAMUser"
  THEN: → Lambda (disable all keys + attach deny-all policy)
        → SNS (PagerDuty P1 + email to CISO)

Rule 4: "open-ssh-detected"
  WHEN: Security Hub finding = security group 0.0.0.0/0 on SSH
  THEN: → Lambda (revoke 0.0.0.0/0 ingress rule)
        → SNS (Slack notification)

Rule 5: "root-account-login"
  WHEN: CloudTrail event = ConsoleLogin with userIdentity.type = "Root"
  THEN: → SNS (CRITICAL alert to all channels)

Rule 6: "cloudtrail-stopped"
  WHEN: CloudTrail event = StopLogging OR DeleteTrail
  THEN: → SNS (CRITICAL alert)
        → Lambda (re-enable trail automatically)
```

### EventBridge Event Pattern Example
```json
{
    "source": ["aws.guardduty"],
    "detail-type": ["GuardDuty Finding"],
    "detail": {
        "severity": [{ "numeric": [">=", 7] }],
        "type": [{ "prefix": "CryptoCurrency:" }]
    }
}
```
This pattern says: "Match any GuardDuty finding where severity is 7+ AND the type starts with CryptoCurrency". When matched, EventBridge instantly sends the full event JSON to your Lambda function.

### Scheduled Rules (Cron Jobs)
EventBridge also replaces cron for scheduled security tasks:
```
"cron(0 9 ? * MON *)"  →  Every Monday 9 AM: Generate weekly security report
"rate(1 hour)"          →  Every hour: Check for stale IAM access keys
"rate(6 hours)"         →  Every 6 hours: Sync GuardDuty findings to SIEM
```

---

## AWS Service 12: AWS Lambda (Security Auto-Remediation Engine)

### What Is Lambda in Security Context?

Lambda is a **serverless function** that runs your security remediation code WITHOUT any servers to manage. You write Python/Node.js code, upload it, and Lambda runs it ONLY when triggered by EventBridge.

**Think of it as an Automatic Security Guard:**
- The alarm rings (EventBridge sends event)
- The guard wakes up (Lambda cold start, ~200ms)
- Performs the action (isolate server, revoke keys, block access)
- Goes back to sleep (you pay $0 when idle)
- If 10 alarms ring at once → 10 guards work simultaneously (auto-scales)

### Why Lambda for Security?

```
TRADITIONAL APPROACH:                     LAMBDA APPROACH:
┌────────────────────┐                   ┌────────────────────┐
│ Run EC2 24/7       │                   │ Pay $0 when idle   │
│ Install Python     │                   │ No servers to patch │
│ Keep it patched    │                   │ Auto-scales to 1000 │
│ Handle crashes     │                   │ Runs in 2 seconds  │
│ Monitor uptime     │                   │ Built-in retry     │
│                    │                   │                    │
│ Cost: ~$70/month   │                   │ Cost: ~$2/month    │
│ even when idle     │                   │ (pay per execution)│
└────────────────────┘                   └────────────────────┘
```

### How Lambda Functions Work in This Project

We have **4 Lambda functions**, each handling a different security scenario:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     LAMBDA SECURITY FUNCTIONS                        │
│                                                                      │
│  FUNCTION 1: guardduty-remediation                                  │
│  ─────────────────────────────────                                  │
│  Trigger: GuardDuty HIGH/CRITICAL finding                           │
│  Actions:                                                            │
│    1. Replace instance Security Group with ISOLATION SG             │
│       (no ingress, no egress = total network cutoff)                │
│    2. Create EBS snapshots of all volumes (forensic evidence)       │
│    3. Tag instance: SecurityStatus=COMPROMISED                      │
│    4. Send SNS alert to PagerDuty                                   │
│  Runtime: Python 3.12 | Timeout: 300s | Memory: 256MB              │
│                                                                      │
│  FUNCTION 2: s3-remediation                                         │
│  ──────────────────────────                                         │
│  Trigger: S3 bucket found public (via Config/Security Hub)          │
│  Actions:                                                            │
│    1. Enable Block Public Access (all 4 settings = true)            │
│    2. Enable KMS default encryption                                  │
│    3. Log which bucket was fixed and why                            │
│    4. Send Slack notification                                        │
│  Runtime: Python 3.12 | Timeout: 60s | Memory: 128MB               │
│                                                                      │
│  FUNCTION 3: iam-remediation                                        │
│  ────────────────────────────                                       │
│  Trigger: IAM credential compromise detected                        │
│  Actions:                                                            │
│    1. List ALL access keys for the user                             │
│    2. Disable every key (Status=Inactive)                           │
│    3. Attach deny-all inline policy (blocks active sessions too)    │
│    4. Send CRITICAL alert with user details                         │
│  Runtime: Python 3.12 | Timeout: 60s | Memory: 128MB               │
│                                                                      │
│  FUNCTION 4: sg-remediation                                         │
│  ───────────────────────────                                        │
│  Trigger: Security group with 0.0.0.0/0 on SSH/RDP detected        │
│  Actions:                                                            │
│    1. Get current SG rules                                          │
│    2. Find rules allowing 0.0.0.0/0 on port 22, 3389, or all      │
│    3. Revoke those specific ingress rules                           │
│    4. Send notification with SG ID and what was removed             │
│  Runtime: Python 3.12 | Timeout: 60s | Memory: 128MB               │
└─────────────────────────────────────────────────────────────────────┘
```

### Lambda Needs IAM Permissions

Each Lambda function has an **execution role** that grants only the permissions it needs:

```
guardduty-remediation role:
  ├── ec2:ModifyInstanceAttribute     (to replace security groups)
  ├── ec2:CreateSnapshot              (forensic snapshots)
  ├── ec2:CreateTags                  (tag as compromised)
  ├── ec2:DescribeInstances           (find attached volumes)
  ├── sns:Publish                     (send alerts)
  └── securityhub:BatchUpdateFindings (update finding status)

s3-remediation role:
  ├── s3:PutPublicAccessBlock         (block public access)
  ├── s3:PutBucketEncryption          (enable encryption)
  └── sns:Publish                     (send alerts)

iam-remediation role:
  ├── iam:ListAccessKeys              (find all keys)
  ├── iam:UpdateAccessKey             (disable keys)
  ├── iam:PutUserPolicy               (attach deny-all)
  └── sns:Publish                     (send alerts)
```

---

## AWS Service 13: Amazon SNS (Security Alerting)

### What Is SNS in Security Context?

SNS (Simple Notification Service) is the **alert delivery system**. When Lambda detects and remediates a threat, SNS delivers the notification to your team through multiple channels simultaneously.

**Think of it as a Fire Alarm System:**
- Fire detected (security event)
- Alarm sounds (SNS receives message)
- Simultaneously: sprinklers activate (Slack), fire department called (PagerDuty), PA announces (email)
- Everyone who needs to know gets notified in under 3 seconds

### How SNS Works in the Security Dashboard

```
                    Security Event Detected
                            │
                            ▼
                    ┌──────────────┐
                    │  SNS TOPIC   │
                    │  "security-  │
                    │   critical"  │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────┴────┐ ┌────┴────┐ ┌────┴─────┐
         │  Slack  │ │PagerDuty│ │  Email   │
         │ Webhook │ │  HTTPS  │ │  SMTP    │
         │         │ │         │ │          │
         │ #sec-   │ │ Creates │ │ security │
         │ alerts  │ │ P1 inc  │ │ @co.com  │
         │ channel │ │ pages   │ │          │
         │         │ │ on-call │ │ Full     │
         │ Quick   │ │ engineer│ │ detailed │
         │ summary │ │         │ │ report   │
         └─────────┘ └─────────┘ └──────────┘
```

### Two SNS Topics Used

```
TOPIC 1: security-critical-alerts
  ├── Who subscribes: PagerDuty (HTTPS), CISO email, Slack #critical
  ├── When triggered: Root login, credential compromise, crypto mining,
  │                   CloudTrail disabled, data exfiltration
  └── Response time: Immediate (P1 incident created)

TOPIC 2: security-high-alerts
  ├── Who subscribes: Slack #security-alerts, team email
  ├── When triggered: Public S3 bucket, open SSH, IAM policy change,
  │                   new findings in Security Hub
  └── Response time: Same business day
```

### What the Alert Looks Like

When GuardDuty detects crypto mining, your team gets:
```
SLACK MESSAGE:
┌────────────────────────────────────────────────────┐
│ 🚨 [AWS Security] GuardDuty: CryptoCurrency:EC2/  │
│    BitcoinTool.B on i-0abc123def456                │
│                                                     │
│ Severity: 8.0 (HIGH)                               │
│ Account: 111111111111 (Production)                  │
│ Region: us-east-1                                   │
│                                                     │
│ Actions Taken (auto-remediated):                    │
│ ✅ Isolated instance with SG sg-isolation           │
│ ✅ Forensic snapshot: snap-0abc123                   │
│ ✅ Tagged as COMPROMISED                             │
│                                                     │
│ Next Steps:                                         │
│ • Review in AWS Detective for attack chain          │
│ • Check CloudTrail for attacker activity            │
│ • Determine root cause                              │
│ • Decide: terminate or investigate further           │
└────────────────────────────────────────────────────┘
```

---

## AWS Service 14: Amazon Athena (Security Log Analysis)

### What Is Athena in Security Context?

Athena lets you run **SQL queries directly on CloudTrail logs stored in S3** — without setting up any database. This is how security teams do forensic investigations on millions of log events.

**Think of it as a Search Engine for Your Audit Logs:**
- CloudTrail writes billions of log entries to S3 over months/years
- You can't open these files manually — they're compressed JSON
- Athena lets you query them with SQL: "Show me all API calls from IP 185.x.x.x last Tuesday"
- Results in seconds, costs ~$5 per TB scanned

### How Athena Fits in the Security Architecture

```
CloudTrail logs every API call
        │
        ▼
  S3 Bucket (years of logs, TBs of data)
        │
        ▼
  Athena (serverless SQL engine)
        │
        ├── "Who logged in without MFA last month?"
        ├── "What did attacker IP 185.x.x.x do?"
        ├── "Show all CreateAccessKey events this quarter"
        ├── "Find all failed login attempts by country"
        └── "Which IAM user made the most API calls?"
```

### When Do You Use Athena vs CloudTrail Console?

| CloudTrail Console (lookup-events) | Athena (SQL on S3) |
|-------------------------------------|--------------------|
| Last 90 days only | **Years of history** |
| Simple filters (user, resource, event) | **Complex SQL joins, aggregations** |
| Good for quick checks | **Good for investigations & compliance reports** |
| Free | ~$5 per TB scanned |

### Real-Time Investigation Example
```sql
-- An alert fires at 3 AM: "Unusual S3 data download"
-- Security team uses Athena to investigate:

-- Step 1: Who accessed the bucket?
SELECT eventTime, userIdentity.arn, sourceIPAddress, eventName,
       requestParameters
FROM cloudtrail_logs
WHERE eventSource = 's3.amazonaws.com'
  AND eventTime BETWEEN '2026-03-02T02:00:00Z' AND '2026-03-02T05:00:00Z'
  AND requestParameters LIKE '%customer-data%'
ORDER BY eventTime;

-- Step 2: What else did this IP address do?
SELECT eventTime, eventName, eventSource, userIdentity.arn, errorCode
FROM cloudtrail_logs
WHERE sourceIPAddress = '185.xx.xx.xx'
ORDER BY eventTime;

-- Step 3: Were any new IAM users or keys created? (persistence check)
SELECT eventTime, userIdentity.arn, eventName, responseElements
FROM cloudtrail_logs
WHERE eventName IN ('CreateUser', 'CreateAccessKey', 'CreateRole')
  AND eventTime > '2026-03-01'
ORDER BY eventTime;
```

---

## AWS Service 15: Amazon SES (Security Report Delivery)

### What Is SES in Security Context?

SES (Simple Email Service) sends the **automated weekly security reports** to your leadership team. Every Monday morning, a Lambda function generates an HTML report with findings, compliance scores, and remediation stats, and SES delivers it.

```
FLOW:
  EventBridge (cron: Monday 9 AM UTC)
       │
       ▼
  Lambda function runs:
    1. Queries Security Hub API → findings count by severity
    2. Queries GuardDuty API → threat summary
    3. Queries Config API → compliance status
    4. Calculates trends (this week vs last week)
    5. Generates HTML email report
       │
       ▼
  SES sends email to:
    ├── ciso@company.com
    ├── devops-lead@company.com
    └── security-team@company.com
```

### Why SES Instead of Just SNS?

| SNS (real-time alerts) | SES (scheduled reports) |
|------------------------|------------------------|
| Short text messages | **Rich HTML emails** with tables, charts, colors |
| Immediate: "FIRE!" | Scheduled: "Here's your weekly summary" |
| Goes to Slack/PagerDuty/SMS | Goes to **email inboxes** |
| No formatting control | Full HTML/CSS formatting |

---

## Complete AWS Services Summary for This Project

| # | Service | Role in Project | Why It's Needed |
|---|---------|----------------|-----------------|
| 1 | **Security Hub** | Central aggregator | Single dashboard for ALL findings from ALL services |
| 2 | **GuardDuty** | Threat detection | ML-based 24/7 monitoring of VPC, DNS, CloudTrail |
| 3 | **CloudTrail** | Audit logging | Records every API call — who, what, when, from where |
| 4 | **SCPs** | Organization guardrails | Prevents dangerous actions even by admins |
| 5 | **IAM Policies** | Access control | Least privilege — who can do what |
| 6 | **CloudWatch** | Metrics & alarms | Security metric filters + alarms on CloudTrail logs |
| 7 | **Inspector** | Vulnerability scanning | Finds CVEs in EC2, ECR images, Lambda code |
| 8 | **Macie** | Data discovery | Finds PII/sensitive data in S3 buckets |
| 9 | **Detective** | Investigation | Visual attack graphs for forensic analysis |
| 10 | **Config** | Compliance | Monitors resource configurations, auto-remediates drift |
| 11 | **EventBridge** | Event routing | Routes security events to Lambda/SNS (the nervous system) |
| 12 | **Lambda** | Auto-remediation | Runs remediation code in seconds, serverless |
| 13 | **SNS** | Alerting | Delivers alerts to Slack, PagerDuty, email simultaneously |
| 14 | **Athena** | Log analysis | SQL queries on CloudTrail logs for investigations |
| 15 | **SES** | Report delivery | Sends weekly HTML security reports to leadership |
| 16 | **KMS** | Encryption | Encrypts CloudTrail logs, S3 buckets, EBS snapshots |
| 17 | **S3** | Storage | Stores CloudTrail logs, Config snapshots, reports |
| 18 | **IAM Access Analyzer** | Permission audit | Finds overpermissioned resources and external access |

---

# Part 3 — Real-Time Project: AWS Security Management Dashboard

> **Objective:** Build a complete security monitoring and auto-remediation system using AWS-native services. This is what enterprises run in production.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AWS SECURITY MANAGEMENT DASHBOARD                         │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                     DETECTION LAYER                                   │   │
│  │                                                                       │   │
│  │   GuardDuty        Inspector       Macie         Config               │   │
│  │   (Threats)        (CVEs)          (PII)         (Compliance)         │   │
│  │      │               │               │               │                │   │
│  │      └───────────────┴───────────────┴───────────────┘                │   │
│  │                          │                                             │   │
│  │                    SECURITY HUB                                        │   │
│  │              (Aggregation + Scoring)                                   │   │
│  └──────────────────────┬───────────────────────────────────────────────┘   │
│                          │                                                    │
│  ┌──────────────────────┴───────────────────────────────────────────────┐   │
│  │                    RESPONSE LAYER                                      │   │
│  │                                                                        │   │
│  │   EventBridge Rule ──→ Lambda ──→ Auto-Remediation                    │   │
│  │       │                    │           ├── Isolate EC2                 │   │
│  │       │                    │           ├── Revoke IAM keys             │   │
│  │       │                    │           ├── Block S3 public access      │   │
│  │       │                    │           ├── Enable encryption           │   │
│  │       │                    │           └── Quarantine container        │   │
│  │       │                    │                                           │   │
│  │       └──→ SNS ──→ Slack/PagerDuty/Email                             │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    VISIBILITY LAYER                                    │   │
│  │                                                                        │   │
│  │   CloudWatch Dashboard (Real-Time)                                    │   │
│  │   ├── Total findings by severity (CRITICAL/HIGH/MEDIUM/LOW)           │   │
│  │   ├── Compliance score (% resources compliant)                        │   │
│  │   ├── GuardDuty active threats timeline                               │   │
│  │   ├── Top 10 non-compliant resources                                  │   │
│  │   ├── Auto-remediation success rate                                   │   │
│  │   ├── Open vs resolved findings trend                                 │   │
│  │   └── Security score by account (multi-account)                       │   │
│  │                                                                        │   │
│  │   CloudTrail + Athena (Investigation)                                 │   │
│  │   ├── Full API audit trail                                            │   │
│  │   ├── Ad-hoc forensic queries                                         │   │
│  │   └── Compliance reports                                              │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## How The Project Works — Complete Flow Explanation

### What Are We Building?

An **enterprise-grade security monitoring system** that automatically:
1. **Detects** threats across your entire AWS account (compromised instances, exposed data, misconfigurations)
2. **Aggregates** all findings into one central dashboard with a security score
3. **Responds** automatically — isolates compromised servers, blocks public S3 buckets, revokes leaked credentials
4. **Alerts** humans via Slack/PagerDuty/Email for critical incidents
5. **Reports** weekly security posture to leadership

This is exactly what companies like Netflix, Airbnb, and Capital One run in production.

---

### Step 1: The Detection Layer — How Threats Get Found

Every security service runs independently, continuously scanning your AWS environment:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DETECTION (Always Running 24/7)                    │
│                                                                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────┐   ┌─────────┐ │
│  │  GuardDuty   │   │  Inspector   │   │  Macie   │   │ Config  │ │
│  │              │   │              │   │          │   │         │ │
│  │ Watches:     │   │ Watches:     │   │ Watches: │   │ Watches:│ │
│  │ • VPC Flow   │   │ • EC2 CVEs   │   │ • S3     │   │ • All   │ │
│  │   Logs       │   │ • ECR image  │   │   bucket │   │  resource│ │
│  │ • DNS logs   │   │   vulns      │   │   scans  │   │  configs │ │
│  │ • CloudTrail │   │ • Lambda     │   │ • PII    │   │ • SG     │ │
│  │ • S3 access  │   │   code       │   │   detect │   │ • IAM    │ │
│  │ • EKS audit  │   │              │   │          │   │ • S3     │ │
│  └──────┬───────┘   └──────┬───────┘   └────┬─────┘   └────┬────┘ │
│         │                  │                 │              │       │
│         └──────────────────┴─────────────────┴──────────────┘       │
│                              │                                       │
│                     ALL FINDINGS SENT TO                             │
│                              ▼                                       │
│                   ┌─────────────────────┐                           │
│                   │   SECURITY HUB      │                           │
│                   │  (Central Brain)    │                           │
│                   │                     │                           │
│                   │ • Aggregates ALL    │                           │
│                   │ • Scores: CRITICAL  │                           │
│                   │   HIGH/MEDIUM/LOW   │                           │
│                   │ • Compliance check  │                           │
│                   │   CIS + PCI DSS     │                           │
│                   │ • Security score %  │                           │
│                   └─────────────────────┘                           │
└─────────────────────────────────────────────────────────────────────┘
```

**Real-Time Example — What GuardDuty Detects:**

| Finding Type | What Happened | Severity |
|-------------|---------------|----------|
| `CryptoCurrency:EC2/BitcoinTool.B` | EC2 instance mining crypto | HIGH (8.0) |
| `UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B` | Login from impossible geo (India → Russia in 5 min) | MEDIUM (5.0) |
| `Recon:EC2/PortProbeUnprotectedPort` | Someone scanning your ports | LOW (2.0) |
| `Trojan:EC2/BlackholeTraffic` | Instance sending traffic to known malicious IPs | HIGH (8.0) |
| `Exfiltration:S3/MaliciousIPCaller` | S3 data downloaded from known attacker IP | HIGH (8.0) |

**How Each Service Finds Issues:**

**GuardDuty** — Uses Machine Learning on VPC Flow Logs + DNS queries + CloudTrail. Example: It learns your EC2 normally talks to 10 IPs. Suddenly it connects to 500 new IPs in Russia → ALERT: possible C2 communication.

**Inspector** — Scans EC2 instances and container images against the CVE database. Example: Your EC2 runs Apache 2.4.49 → Inspector flags CVE-2021-41773 (path traversal, CRITICAL). It tells you: "Update to Apache 2.4.51+".

**Macie** — Scans S3 bucket contents using ML. Example: Customer uploads a file to `app-uploads/` bucket → Macie finds Social Security Numbers, credit card numbers, passport scans → ALERT: PII stored without encryption.

**Config** — Monitors every configuration change. Example: Developer changes security group to allow `0.0.0.0/0` on port 22 → Config rule fires: "NONCOMPLIANT: SSH open to world".

---

### Step 2: The Aggregation Layer — Security Hub as the Central Brain

All findings flow into Security Hub. Here's what happens inside:

```
     GuardDuty Findings ────┐
     Inspector Findings ────┤
     Macie Findings ────────┤──→  SECURITY HUB
     Config Findings ───────┤
     IAM Analyzer Findings ─┤
     3rd Party (Snyk, etc) ─┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │  NORMALIZATION    │
                           │                   │
                           │ All findings      │
                           │ converted to      │
                           │ ASFF format       │
                           │ (standard schema) │
                           └────────┬──────────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │  SCORING          │
                           │                   │
                           │ CRITICAL: 90-100  │
                           │ HIGH:     70-89   │
                           │ MEDIUM:   40-69   │
                           │ LOW:      1-39    │
                           │ INFO:     0       │
                           └────────┬──────────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │  COMPLIANCE       │
                           │                   │
                           │ CIS Benchmark:    │
                           │  ✅ 142 PASSED    │
                           │  ❌ 18 FAILED     │
                           │  Score: 89%       │
                           │                   │
                           │ AWS Best Practice: │
                           │  ✅ 201 PASSED    │
                           │  ❌ 12 FAILED     │
                           │  Score: 94%       │
                           └──────────────────┘
```

**Real-Time Example — Security Hub Dashboard View:**

```
┌────────────────────────────────────────────────────────────────┐
│                   SECURITY HUB SUMMARY                          │
│                                                                  │
│  Overall Score: 87%  ████████████████████░░░                    │
│                                                                  │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │ CRITICAL │   HIGH   │  MEDIUM  │   LOW    │   INFO   │      │
│  │    3     │    12    │    45    │    23    │    8     │      │
│  │   🔴     │   🟠     │   🟡     │   🔵     │   ⚪     │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
│                                                                  │
│  Top 3 CRITICAL Findings:                                       │
│  1. S3 bucket "customer-data" is PUBLIC        (Config)         │
│  2. EC2 i-0abc mining cryptocurrency           (GuardDuty)      │
│  3. Root account logged in without MFA         (CloudTrail)     │
└────────────────────────────────────────────────────────────────┘
```

---

### Step 3: The Response Layer — Automated Remediation Flow

When Security Hub or GuardDuty generates a finding, here's the EXACT flow that happens in under 60 seconds:

```
THREAT DETECTED
      │
      ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                     EventBridge                               │
  │                                                               │
  │  6 Rules watching for specific event patterns:               │
  │                                                               │
  │  Rule 1: GuardDuty severity >= 7    →  Lambda (isolate EC2) │
  │  Rule 2: S3 public bucket detected  →  Lambda (block access) │
  │  Rule 3: IAM key compromise         →  Lambda (revoke keys) │
  │  Rule 4: Open SSH security group    →  Lambda (close port)  │
  │  Rule 5: Root account login         →  SNS (alert team)     │
  │  Rule 6: CloudTrail stopped         →  SNS (alert + re-enable)│
  └──────────────────────────────────────────────────────────────┘
```

#### Scenario A: Crypto Mining Detected on EC2

```
Timeline: What happens in 47 seconds

T+0s   GuardDuty detects: "CryptoCurrency:EC2/BitcoinTool.B"
       Instance i-0abc123 is mining Bitcoin
       Severity: 8.0 (HIGH)
            │
T+2s   EventBridge Rule 1 matches (severity >= 7)
       Triggers Lambda function: guardduty-remediation
            │
T+5s   Lambda executes:
       ├── 1. Replace SG with ISOLATION SG (no ingress, no egress)
       │      Instance is now completely cut off from network
       │      Can't mine crypto, can't exfiltrate data
       │
       ├── 2. Create forensic snapshots of ALL EBS volumes
       │      vol-abc → snap-forensic-001
       │      vol-def → snap-forensic-002
       │      Evidence preserved for investigation
       │
       ├── 3. Tag instance:
       │      SecurityStatus = COMPROMISED
       │      IsolatedAt = 2026-03-03T14:23:00Z
       │      IsolatedBy = auto-remediation-lambda
       │
       └── 4. Send SNS notification
            │
T+8s   SNS delivers to 3 channels simultaneously:
       ├── Slack #security-alerts: "🚨 CRITICAL: EC2 i-0abc123 mining crypto — ISOLATED"
       ├── PagerDuty: Creates P1 incident, pages on-call engineer
       └── Email: security-team@company.com gets detailed report
            │
T+15s  Security Hub finding updated:
       Status: NOTIFIED → IN_PROGRESS
       Note: "Auto-remediated: instance isolated, snapshots created"
            │
T+47s  Engineer acknowledges PagerDuty, starts investigation using
       the forensic snapshots (the instance is safely isolated)
```

#### Scenario B: S3 Bucket Made Public

```
Timeline: What happens in 12 seconds

T+0s   Developer runs: aws s3api put-bucket-acl --bucket customer-data --acl public-read
       (Mistake! Production customer data bucket is now PUBLIC)
            │
T+1s   Config detects: s3-bucket-public-read-prohibited → NONCOMPLIANT
       Security Hub receives finding: "S3 bucket customer-data allows public access"
            │
T+3s   EventBridge Rule 2 matches (S3 public + CRITICAL severity)
       Triggers Lambda function: s3-remediation
            │
T+5s   Lambda executes:
       ├── 1. Enable Block Public Access on the bucket
       │      BlockPublicAcls = true
       │      IgnorePublicAcls = true
       │      BlockPublicPolicy = true
       │      RestrictPublicBuckets = true
       │      ✅ Bucket is now PRIVATE again
       │
       ├── 2. Enable KMS encryption (if not already)
       │      SSEAlgorithm = aws:kms
       │      BucketKeyEnabled = true
       │
       └── 3. Send notification: "S3 bucket customer-data was public — FIXED"
            │
T+12s  Total exposure time: ~12 seconds
       Without automation: Could be hours or days before someone notices
       The 2019 Capital One breach? Their bucket was public for MONTHS.
```

#### Scenario C: IAM Access Key Leaked on GitHub

```
Timeline: What happens in 20 seconds

T+0s   Developer accidentally pushes code with AWS_ACCESS_KEY_ID
       to a public GitHub repo
            │
T+1s   Attacker's bot finds the key (automated scrapers scan GitHub
       every few seconds for AWS keys)
            │
T+2s   Attacker uses the key: aws ec2 describe-instances
       from IP 185.x.x.x (known malicious IP in Russia)
            │
T+3s   GuardDuty detects: "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration"
       Also detects: unusual geo (user normally in US, now calling from Russia)
            │
T+5s   EventBridge Rule 3 matches (IAM credential compromise)
       Triggers Lambda function: iam-remediation
            │
T+8s   Lambda executes:
       ├── 1. List ALL access keys for the user
       │      Key AKIA1234... → Status: Inactive (DISABLED)
       │      Key AKIA5678... → Status: Inactive (DISABLED)
       │
       ├── 2. Attach DENY-ALL inline policy
       │      Even active sessions are now blocked
       │      "Effect": "Deny", "Action": "*", "Resource": "*"
       │
       └── 3. Alert: "IAM credentials compromised for user dev-john — ALL ACCESS REVOKED"
            │
T+15s  Security team investigates:
       ├── CloudTrail: What did the attacker access? (7 API calls in 10 seconds)
       ├── Detective: Visual graph showing attack chain
       └── Action: Rotate all credentials, audit resources created by attacker
            │
T+20s  Total attacker access time: ~13 seconds
       Without automation: Attacker could have hours — enough to launch 100 EC2
       instances for crypto mining ($10,000+ in charges)
```

#### Scenario D: Root Account Login

```
T+0s   Someone logs into root account
            │
T+2s   CloudTrail records: ConsoleLogin with userIdentity.type = "Root"
       EventBridge Rule 5 matches
            │
T+3s   SNS sends IMMEDIATE alert:
       "🚨 ROOT ACCOUNT LOGIN DETECTED — This should NEVER happen in production"
       Includes: Source IP, time, MFA used (yes/no), user agent (browser info)
            │
       Team investigates: Was this authorized maintenance or a breach?
```

#### Scenario E: Someone Disables CloudTrail (Covering Tracks)

```
T+0s   Attacker (or compromised admin) runs: aws cloudtrail stop-logging
       They're trying to stop audit logging to hide their activities
            │
T+1s   EventBridge Rule 6 matches (StopLogging or DeleteTrail event)
            │
T+2s   SNS CRITICAL alert: "CloudTrail logging has been STOPPED"
            │
T+3s   (If you have SCP in place, this would have been BLOCKED entirely)
       SCP: "Deny cloudtrail:StopLogging for all accounts except security-admin"
            │
       Note: This is why SCPs are critical — even if an admin account
       is compromised, they CANNOT disable logging
```

---

### Step 4: The Visibility Layer — Security Dashboard

The CloudWatch Security Dashboard gives real-time visibility to your team:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                🛡️ AWS SECURITY MANAGEMENT DASHBOARD                        │
│                   Last updated: 2026-03-03 14:30 UTC                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 1: Security Score Over Time                                       │
│  ────────────────────────────────                                         │
│  100%│                                    ╭────                           │
│   90%│                          ╭─────────╯                               │
│   80%│              ╭───────────╯                                         │
│   70%│──────────────╯                                                     │
│   60%│                                                                    │
│      └──────────────────────────────────────                              │
│       Jan    Feb    Mar    Apr    May    Jun                               │
│  Trend: Score improved from 72% → 94% in 6 months                        │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 2: Active Findings by Severity                                    │
│  ────────────────────────────────────                                     │
│  CRITICAL  ████  3          NEEDS IMMEDIATE ACTION                        │
│  HIGH      █████████████  12                                              │
│  MEDIUM    ████████████████████████████  45                               │
│  LOW       ███████████████  23                                            │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 3: GuardDuty Threats (Last 7 Days)                                │
│  ────────────────────────────────────────                                 │
│  Mon: ▌▌ (2 findings)                                                     │
│  Tue: ▌▌▌▌▌ (5 findings — port scan detected)                            │
│  Wed: ▌ (1 finding)                                                       │
│  Thu: (0 — clean day ✅)                                                   │
│  Fri: ▌▌▌▌▌▌▌▌ (8 findings — crypto mining attempt, auto-remediated)     │
│  Sat: ▌ (1 finding)                                                       │
│  Sun: (0 — clean day ✅)                                                   │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 4: Compliance Status                                              │
│  ──────────────────────────                                               │
│  CIS AWS Benchmark 1.4:     ████████████████████░░  89% (142/160 PASSED) │
│  AWS Foundational Best:     ██████████████████████░  94% (201/213 PASSED) │
│  PCI DSS:                   ████████████████████░░░  87% (78/90 PASSED)  │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 5: Top 10 Non-Compliant Resources                                │
│  ────────────────────────────────────────                                 │
│  1. s3://customer-data-backup    — No encryption (CRITICAL)              │
│  2. sg-0abc1234                  — SSH open to 0.0.0.0/0 (HIGH)          │
│  3. i-0def5678                   — No SSM agent (MEDIUM)                 │
│  4. arn:iam::user/dev-intern     — MFA not enabled (HIGH)                │
│  5. rds:prod-database            — Public accessibility ON (CRITICAL)    │
│  6. lambda:payment-processor     — Has HIGH CVE (HIGH)                   │
│  7. s3://test-uploads            — Versioning disabled (MEDIUM)          │
│  8. ebs:vol-0ghi9012             — Not encrypted (MEDIUM)                │
│  9. arn:iam::role/legacy-admin   — Has AdministratorAccess (HIGH)        │
│  10. ec2:i-0jkl3456              — Outdated AMI, 12 CVEs (HIGH)          │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 6: Auto-Remediation Stats (Last 30 Days)                         │
│  ───────────────────────────────────────────────                          │
│  Total auto-remediations:    47                                           │
│  Success rate:               95.7% (45/47)                                │
│  Failed (manual needed):     2                                            │
│                                                                            │
│  Breakdown:                                                               │
│  • S3 public access blocked:     18 times                                │
│  • Security groups closed:       14 times                                │
│  • IAM keys revoked:              8 times                                │
│  • EC2 instances isolated:        5 times                                │
│  • Encryption enabled:            2 times                                │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 7: Open vs Resolved Findings (Trend)                             │
│  ───────────────────────────────────────────                              │
│  150│  ╲ Open                                                             │
│  100│    ╲                                                                │
│   50│      ╲───────── ← Trending DOWN (good!)                            │
│     │   ╱──────────── ← Resolved trending UP                             │
│   0 └────────────────────                                                 │
│      Week1  Week2  Week3  Week4                                           │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  WIDGET 8: Security Score by Account (Multi-Account)                     │
│  ──────────────────────────────────────────────────                       │
│  Production (111111111111):  ██████████████████████  96%                  │
│  Staging (222222222222):     █████████████████████░  92%                  │
│  Development (333333333333): ████████████████░░░░░░  78%   ← Needs work  │
│  Sandbox (444444444444):     █████████████░░░░░░░░░  65%   ← Alert!      │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**How the Dashboard Data Flows:**

```
GuardDuty/Inspector/Macie/Config
         │
         ▼
    Security Hub (aggregates + scores)
         │
         ├──→ Custom Metrics → CloudWatch (GuardDuty finding count, compliance %)
         │
         ├──→ CloudWatch Logs → Metric Filters (root login count, unauthorized API calls)
         │
         └──→ Security Hub Insights (top resources, trend queries)
                    │
                    ▼
            CloudWatch Dashboard
            (8 widgets pulling from above data sources)
```

---

### Step 5: The Investigation Layer — When Humans Need to Dig Deeper

When auto-remediation handles the immediate threat, the security team investigates using:

```
┌─────────────────────────────────────────────────────────────────┐
│                    INVESTIGATION FLOW                             │
│                                                                   │
│  Alert received: "IAM key compromise for user dev-john"          │
│                                                                   │
│  Step 1: CloudTrail — WHAT happened?                             │
│  ────────────────────────────────                                │
│  Query: "Show all API calls by dev-john in last 24 hours"        │
│                                                                   │
│  Results:                                                         │
│  14:20:01  sts:GetCallerIdentity     (attacker checking access)  │
│  14:20:03  ec2:DescribeInstances     (reconnaissance)            │
│  14:20:05  iam:ListUsers             (looking for more targets)  │
│  14:20:07  s3:ListBuckets            (finding sensitive data)    │
│  14:20:08  s3:GetObject customer-db-backup.sql  ← DATA ACCESSED │
│  14:20:10  ec2:RunInstances (t3.xlarge × 10)    ← CRYPTO MINING │
│  14:20:13  iam:CreateUser "backdoor-admin"       ← PERSISTENCE  │
│  14:20:15  [BLOCKED] — Auto-remediation kicked in                │
│                                                                   │
│  Step 2: Detective — Visual Attack Graph                         │
│  ──────────────────────────────────────                          │
│                                                                   │
│  IP: 185.x.x.x (Russia)                                          │
│       │                                                           │
│       ├──→ AssumeRole: dev-john                                  │
│       │     ├──→ Described 47 EC2 instances                      │
│       │     ├──→ Downloaded 1 S3 object (3.2 GB)                 │
│       │     ├──→ Launched 10 EC2 instances                       │
│       │     └──→ Created IAM user "backdoor-admin"               │
│       │                                                           │
│       └──→ Also tried (FAILED):                                  │
│             ├──→ iam:CreateLoginProfile (denied by SCP)          │
│             └──→ cloudtrail:StopLogging (denied by SCP)          │
│                                                                   │
│  Step 3: Athena — Deep Analysis                                  │
│  ──────────────────────────────                                  │
│  Query CloudTrail logs in S3 using SQL:                          │
│  "SELECT * FROM cloudtrail_logs                                  │
│   WHERE sourceipaddress = '185.x.x.x'                           │
│   AND eventtime > '2026-03-01'                                   │
│   ORDER BY eventtime"                                            │
│                                                                   │
│  Found: Attacker also probed 3 other accounts                    │
│  Action: Alert those account owners immediately                  │
│                                                                   │
│  Step 4: Cleanup & Hardening                                     │
│  ───────────────────────────                                     │
│  ✅ Delete backdoor IAM user                                     │
│  ✅ Terminate 10 unauthorized EC2 instances                      │
│  ✅ Rotate ALL of dev-john's credentials                         │
│  ✅ Enable MFA enforcement policy                                │
│  ✅ Add IP allowlist for IAM console access                      │
│  ✅ Write incident report + update runbook                       │
└─────────────────────────────────────────────────────────────────┘
```

---

### Step 6: Weekly Security Report — Automated

Every Monday at 9 AM, an automated Lambda function generates and emails a report:

```
┌────────────────────────────────────────────────────────────────┐
│              WEEKLY SECURITY REPORT                             │
│              Week of March 3, 2026                              │
│              Generated: Mon 9:00 AM UTC                         │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  EXECUTIVE SUMMARY                                             │
│  ─────────────────                                             │
│  Overall Security Score: 94% (+3% from last week)              │
│  New findings this week: 17                                    │
│  Auto-remediated: 14 (82%)                                     │
│  Needs manual action: 3                                        │
│  Mean time to remediate: 23 seconds (auto) / 4.2 hours (manual)│
│                                                                 │
│  FINDINGS SUMMARY                                              │
│  ────────────────                                              │
│  CRITICAL:  0 (was 3 last week — all resolved ✅)              │
│  HIGH:      5 (was 12 last week — 7 resolved)                  │
│  MEDIUM:    8 (new discoveries from Inspector scan)            │
│  LOW:       4                                                   │
│                                                                 │
│  TOP ACTIONS NEEDED                                            │
│  ────────────────                                              │
│  1. Patch Apache on 3 EC2 instances (CVE-2024-1234, HIGH)     │
│  2. Enable MFA for 2 IAM users in dev account                 │
│  3. Review Lambda function with HIGH vulnerability             │
│                                                                 │
│  COMPLIANCE TREND                                              │
│  ────────────────                                              │
│  CIS:  89% → 92% → 94%  (improving ✅)                        │
│  NIST: 85% → 88% → 91%  (improving ✅)                        │
│                                                                 │
│  GUARDDUTY ACTIVITY                                            │
│  ──────────────────                                            │
│  Total findings: 17                                            │
│  Crypto mining attempts: 2 (auto-isolated)                     │
│  Port scans: 8 (from known scanner IPs)                        │
│  Unusual API activity: 5 (investigated, 3 false positives)     │
│  Data exfiltration: 2 (auto-blocked, investigated)             │
│                                                                 │
│  Sent to: CISO, Security Team, DevOps Lead                    │
└────────────────────────────────────────────────────────────────┘

Flow: EventBridge (cron: Monday 9 AM)
        → Lambda (queries Security Hub API + GuardDuty API)
        → Generates HTML report
        → SES sends email to security-team@company.com
        → Also posts summary to Slack #security-weekly
```

---

### Complete End-to-End Flow Summary

```
THE COMPLETE SECURITY MANAGEMENT FLOW
======================================

    1. PREVENT (Before Attack)
    ─────────────────────────
    SCPs block dangerous actions at org level
    IAM policies enforce least privilege
    Config rules flag misconfigurations instantly
    Permission boundaries limit damage radius
         │
         ▼
    2. DETECT (During Attack)
    ─────────────────────────
    GuardDuty → threats (ML-based, 24/7)
    Inspector → vulnerabilities (CVE scan)
    Macie → data exposure (PII in S3)
    CloudTrail → audit trail (every API call)
    Config → configuration drift (SG/IAM changes)
         │
         ▼
    3. AGGREGATE (Centralize)
    ─────────────────────────
    Security Hub collects ALL findings
    Normalizes to ASFF format
    Scores by severity
    Checks compliance (CIS, PCI, NIST)
         │
         ▼
    4. RESPOND (Automated — seconds)
    ─────────────────────────────────
    EventBridge routes events by pattern
    Lambda auto-remediates:
      • Isolate compromised EC2
      • Block public S3
      • Revoke leaked IAM keys
      • Close open security groups
    SNS alerts team (Slack/PagerDuty/Email)
         │
         ▼
    5. INVESTIGATE (Human — minutes to hours)
    ─────────────────────────────────────────
    CloudTrail → full API history
    Detective → visual attack graph
    Athena → SQL queries on log data
    Forensic snapshots → preserved evidence
         │
         ▼
    6. VISUALIZE (Ongoing)
    ──────────────────────
    CloudWatch Dashboard → real-time 8-widget view
    Security Hub Insights → trend analysis
    Weekly Report → automated executive summary
         │
         ▼
    7. IMPROVE (Continuous)
    ───────────────────────
    Post-incident review → update runbooks
    Tighten SCPs → prevent recurrence
    Tune GuardDuty → reduce false positives
    Add Config rules → prevent new misconfigs
    Update IAM policies → least privilege
```

---

### What Each AWS Service Costs (Real Numbers)

| Service | Pricing Model | Typical Monthly Cost (small org) |
|---------|--------------|--------------------------------|
| **Security Hub** | $0.0010 per finding check | ~$30-50/month |
| **GuardDuty** | Per GB of logs analyzed | ~$20-80/month |
| **Inspector** | $0.15/instance + $0.09/image | ~$10-30/month |
| **Macie** | $1/bucket + $1/GB scanned | ~$15-40/month |
| **Config** | $0.003/rule evaluation | ~$5-20/month |
| **CloudTrail** | Free (management events) | ~$2-10/month (data events) |
| **Detective** | Per GB of data ingested | ~$2-30/month |
| **CloudWatch** | Per metric/alarm/log GB | ~$10-40/month |
| **SNS** | $0.50/million notifications | ~$1-5/month |
| **Lambda** | Per invocation + duration | ~$1-10/month |
| **EventBridge** | $1/million events | ~$1-5/month |
| **Total** | | **~$100-320/month** |

> **ROI:** One prevented data breach saves $4.45M (IBM average). This entire setup costs ~$200/month = $2,400/year. That's a **1,854x ROI**.

---

## Complete Security Checklist

| # | Check | Service | Priority |
|---|-------|---------|----------|
| 1 | CloudTrail enabled in ALL regions | CloudTrail | 🔴 Critical |
| 2 | CloudTrail log file validation ON | CloudTrail | 🔴 Critical |
| 3 | GuardDuty enabled in ALL regions | GuardDuty | 🔴 Critical |
| 4 | Security Hub with CIS benchmark | Security Hub | 🔴 Critical |
| 5 | Root account has MFA (hardware key) | IAM | 🔴 Critical |
| 6 | No root access keys exist | IAM | 🔴 Critical |
| 7 | SCP: Prevent CloudTrail deletion | Organizations | 🔴 Critical |
| 8 | SCP: Region restriction | Organizations | 🟠 High |
| 9 | Config rules for compliance | Config | 🟠 High |
| 10 | Inspector scanning EC2 + ECR | Inspector | 🟠 High |
| 11 | S3 Block Public Access (account-level) | S3 | 🔴 Critical |
| 12 | KMS encryption for all data at rest | KMS | 🟠 High |
| 13 | Macie scanning for PII/sensitive data | Macie | 🟡 Medium |
| 14 | IAM Access Analyzer enabled | IAM | 🟠 High |
| 15 | VPC Flow Logs enabled | VPC | 🟠 High |
| 16 | Security groups — no 0.0.0.0/0 SSH | VPC | 🔴 Critical |
| 17 | IAM password policy enforced | IAM | 🟠 High |
| 18 | Access keys rotated every 90 days | IAM | 🟠 High |
| 19 | MFA required for all human users | IAM | 🔴 Critical |
| 20 | Auto-remediation Lambda functions | Lambda + EventBridge | 🟠 High |
| 21 | Weekly security report automated | SES + Lambda | 🟡 Medium |
| 22 | Incident response runbook documented | Documentation | 🟠 High |

---

## Interview Questions — AWS Security & DevSecOps

### Q1: How would you design a security monitoring system for a multi-account AWS organization?
> **Answer:** I would implement a **hub-and-spoke model**:
> - **Management Account**: AWS Organizations with SCPs as guardrails (prevent trail deletion, region restriction, deny root usage)
> - **Security Hub Admin Account**: Aggregates findings from ALL member accounts — GuardDuty, Inspector, Macie, Config
> - **Each Member Account**: GuardDuty + Inspector + Config enabled locally, findings auto-sent to admin
> - **Centralized CloudTrail**: Organization trail → centralized S3 bucket with log file validation + KMS encryption
> - **EventBridge**: Cross-account event bus for centralized auto-remediation
> - **Dashboard**: CloudWatch dashboard in security account showing org-wide posture
> - **Alerting**: SNS → Slack/PagerDuty for CRITICAL, email digest for HIGH
> - **Weekly Report**: Lambda generates compliance report, sends to CISO

### Q2: What is the difference between GuardDuty, Inspector, and Macie?
> | Service | Purpose | What It Scans | Use Case |
> |---------|---------|--------------|----------|
> | **GuardDuty** | Threat detection | VPC Flow Logs, DNS, CloudTrail, S3, EKS | "Is someone attacking us RIGHT NOW?" |
> | **Inspector** | Vulnerability scanning | EC2 instances, ECR images, Lambda | "Do we have known CVEs in our software?" |
> | **Macie** | Sensitive data discovery | S3 bucket contents | "Is PII/PHI stored unprotected?" |
>
> Think of it as: GuardDuty = **security guard** watching for intruders, Inspector = **health inspector** checking for weaknesses, Macie = **privacy auditor** finding exposed sensitive data.

### Q3: Explain SCPs vs IAM Policies vs Permission Boundaries.
> | Aspect | SCP | IAM Policy | Permission Boundary |
> |--------|-----|-----------|---------------------|
> | **Level** | Organization/OU/Account | User/Group/Role | User/Role |
> | **Effect** | Sets MAXIMUM (ceiling) | Grants permissions | Sets MAXIMUM (ceiling) |
> | **Can grant?** | No — only restrict | Yes — Allow & Deny | No — only restrict |
> | **Who applies?** | Org admin | Account admin | Account admin |
> | **Affects root?** | Yes (except management acct) | No | No |
>
> Effective permissions = SCP ∩ Permission Boundary ∩ IAM Policy (intersection of all three)

### Q4: How would you respond to a compromised IAM access key?
> **Immediate (< 5 minutes):**
> 1. **Disable** the compromised access key: `aws iam update-access-key --status Inactive`
> 2. **Attach deny-all policy** to the user/role (stop any active sessions)
> 3. **Revoke active sessions**: Update role trust policy or use `aws iam put-user-policy` with explicit deny
>
> **Investigation (< 1 hour):**
> 4. Check CloudTrail: What did the attacker do? Which resources were accessed?
> 5. Check GuardDuty: Were there related findings (unusual geo, known bad IP)?
> 6. Use Detective: Visual graph of the entire attack chain
>
> **Remediation (< 24 hours):**
> 7. Rotate ALL credentials for the affected user
> 8. Check for persistence: New IAM users, new access keys, new roles?
> 9. Review and clean up any resources the attacker created (EC2, Lambda, etc.)
> 10. Post-incident: Document, create runbook, implement prevention (MFA, key rotation)

### Q5: How does CloudWatch monitor security events from CloudTrail?
> CloudTrail logs → CloudWatch Logs log group → **Metric Filters** extract specific patterns → **CloudWatch Alarms** trigger on thresholds → **SNS/Lambda** for alerting and remediation.
>
> Example: Filter `{ $.userIdentity.type = "Root" }` creates a custom metric. Alarm fires when metric > 0 in any 5-minute window. SNS sends PagerDuty alert + Lambda disables root access keys.
>
> This is the **CIS AWS Benchmark recommended approach** — 14+ metric filters covering root usage, MFA bypass, IAM changes, SG changes, NACL changes, route table changes, VPC changes, S3 policy changes, etc.

### Q6: What is the "shift-left" approach in DevSecOps and how do you implement it?
> **Shift-left** means moving security checks earlier in the development lifecycle:
>
> | Stage | Tool/Service | What It Catches |
> |-------|-------------|-----------------|
> | **Pre-commit** | git-secrets, pre-commit hooks | Hardcoded API keys, passwords |
> | **PR Review** | SonarQube (SAST), CodeQL | SQL injection, XSS, code smells |
> | **Build** | Trivy, Snyk (SCA) | Vulnerable npm/pip packages |
> | **Docker Build** | Trivy image scan | CVEs in base images |
> | **IaC** | Checkov, tfsec | Public S3, open SG, no encryption |
> | **Staging** | OWASP ZAP (DAST) | Live vulnerability testing |
> | **Production** | GuardDuty, Inspector, Macie | Runtime threats, new CVEs |
>
> Cost of fixing: $10 at code → $10,000 in production → $1M after breach.

### Q7: How would you enforce that ALL S3 buckets must be encrypted and private?
> **Three layers of enforcement:**
> 1. **SCP (Organization level):** Deny `s3:PutObject` without encryption header + Deny `s3:PutBucketPublicAccessBlock` with false values
> 2. **AWS Config Rule:** `s3-bucket-server-side-encryption-enabled` + auto-remediation via SSM document that enables KMS encryption
> 3. **Account-level S3 Block Public Access:** `aws s3control put-public-access-block --account-id ACCT --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true`
>
> With all three: even an admin in a member account cannot create a public, unencrypted bucket.

### Q8: What is AWS Security Hub and how does it differ from CloudWatch?
> **Security Hub** = **Security-specific aggregator and compliance checker**. It collects findings from GuardDuty, Inspector, Macie, Config, IAM Access Analyzer, and 3rd-party tools. It scores each finding (CRITICAL/HIGH/MEDIUM/LOW) and checks compliance against CIS, PCI DSS, and NIST standards.
>
> **CloudWatch** = **General-purpose monitoring and alerting**. It handles metrics, logs, alarms, and dashboards for ALL AWS services (CPU, memory, custom metrics, log analysis).
>
> **How they work together:** Security Hub finds the problems → EventBridge routes events → Lambda auto-remediates → CloudWatch dashboards visualize the security posture in real-time. They complement each other — Security Hub for "what's wrong", CloudWatch for "show me the trend".

---

## Project Deliverables Checklist

### Part 1 — CI/CD Pipeline Security
- [ ] SonarQube running with quality gates (coverage > 80%, 0 vulns)
- [ ] Trivy scanning images AND Terraform code
- [ ] Checkov IaC scan with custom policy baseline
- [ ] HashiCorp Vault for secrets (KV + dynamic AWS creds)
- [ ] OWASP ZAP scanning staging environment
- [ ] git-secrets pre-commit hooks preventing AWS key leaks
- [ ] SARIF reports uploaded to GitHub Security tab
- [ ] Pipeline blocks on CRITICAL findings

### Part 2 — AWS Security Services
- [ ] Security Hub enabled with CIS + AWS Foundational Best Practices
- [ ] GuardDuty enabled in ALL regions
- [ ] Inspector scanning EC2, ECR, and Lambda
- [ ] Macie weekly scan for sensitive data in S3
- [ ] CloudTrail organization trail with log validation + KMS
- [ ] AWS Config with 7+ security rules + auto-remediation
- [ ] IAM Access Analyzer enabled
- [ ] 6 SCPs applied (CloudTrail protection, region lock, root deny, encryption, etc.)

### Part 3 — Security Dashboard & Automation
- [ ] CloudWatch Security Management Dashboard (8+ widgets)
- [ ] 7 CloudTrail → CloudWatch metric filters (CIS Benchmark)
- [ ] 3 CloudWatch alarms (root usage, no-MFA login, excessive unauthorized calls)
- [ ] 4 Lambda auto-remediation functions (GuardDuty, S3, IAM, SG)
- [ ] 6 EventBridge rules connecting detection → response
- [ ] Security Hub custom insights (5 queries)
- [ ] Weekly automated security report via SES
- [ ] Documented incident response runbook
