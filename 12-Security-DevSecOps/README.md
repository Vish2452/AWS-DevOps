# Module 12 — Security & DevSecOps (1 Week)

> **Objective:** Embed security into every stage of the CI/CD pipeline. Master SAST, SCA, container scanning, IaC scanning, secrets management, and DAST.

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
