# ECR — Elastic Container Registry

> Fully managed Docker container registry. Store, manage, and deploy container images securely with integrated vulnerability scanning.

---

## Real-World Analogy

ECR is like a **secure warehouse for shipping containers**:
- **Registry** = Your warehouse in AWS
- **Repository** = A labeled shelf for a specific product (one per microservice)
- **Image** = A packed container on the shelf (versioned with tags)
- **Image Scanning** = Quality inspection before shipping
- **Lifecycle Policy** = "Discard containers older than 30 days"
- **Replication** = Copy inventory to another warehouse (cross-region)

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Registry** | Account-level container store | `ACCT.dkr.ecr.us-east-1.amazonaws.com` |
| **Repository** | One per application/service | `my-app/backend`, `my-app/frontend` |
| **Image Tag** | Version identifier | `latest`, `v1.2.3`, `sha-abc123` |
| **Image Scanning** | CVE vulnerability detection | Scan on push, find Critical/High vulns |
| **Lifecycle Policy** | Auto-cleanup old images | Keep last 10 images, delete untagged |
| **Pull-Through Cache** | Cache Docker Hub/public images | Avoid Docker Hub rate limits |
| **Replication** | Cross-region/account copy | DR: replicate to eu-west-1 |
| **OCI Artifacts** | Store Helm charts, WASM | Not just Docker images |

---

## Real-Time Example 1: CI/CD Pipeline with ECR

**Scenario:** Build Docker images in CI/CD and deploy to ECS/EKS.

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  GitHub   │────▶│  GitHub  │────▶│  ECR     │────▶│  ECS     │
│  Push     │     │  Actions │     │  (Store  │     │  (Deploy │
│  (code)   │     │  (Build) │     │   Image) │     │   Image) │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                  │ docker build
                  │ docker tag
                  │ docker push
```

```bash
# Step 1: Create repository
aws ecr create-repository --repository-name my-app/backend \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=KMS \
    --image-tag-mutability IMMUTABLE

# Step 2: Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    ACCT.dkr.ecr.us-east-1.amazonaws.com

# Step 3: Build, tag, push
docker build -t my-app/backend:v1.0.0 .
docker tag my-app/backend:v1.0.0 ACCT.dkr.ecr.us-east-1.amazonaws.com/my-app/backend:v1.0.0
docker push ACCT.dkr.ecr.us-east-1.amazonaws.com/my-app/backend:v1.0.0

# Step 4: Check scan results
aws ecr describe-image-scan-findings \
    --repository-name my-app/backend \
    --image-id imageTag=v1.0.0

# Step 5: Deploy (update ECS service to use new image)
aws ecs update-service --cluster prod \
    --service backend-svc \
    --force-new-deployment
```

---

## Real-Time Example 2: Lifecycle Policy — Avoid Cost Explosion

**Scenario:** After 6 months of CI/CD, you have 5,000 images and $200/month ECR storage cost. Set up lifecycle policies.

```bash
# Keep only last 10 tagged images + delete all untagged
aws ecr put-lifecycle-policy --repository-name my-app/backend \
    --lifecycle-policy-text '{
        "rules": [
            {
                "rulePriority": 1,
                "description": "Remove untagged images after 1 day",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "sinceImagePushed",
                    "countUnit": "days",
                    "countNumber": 1
                },
                "action": {"type": "expire"}
            },
            {
                "rulePriority": 2,
                "description": "Keep only last 10 images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["v"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 10
                },
                "action": {"type": "expire"}
            }
        ]
    }'
```

---

## Labs

### Lab 1: Full ECR Workflow
```bash
# Create, push, scan, pull
aws ecr create-repository --repository-name demo-app --image-scanning-configuration scanOnPush=true
aws ecr get-login-password | docker login --username AWS --password-stdin ACCT.dkr.ecr.us-east-1.amazonaws.com
docker pull nginx:latest
docker tag nginx:latest ACCT.dkr.ecr.us-east-1.amazonaws.com/demo-app:v1
docker push ACCT.dkr.ecr.us-east-1.amazonaws.com/demo-app:v1
aws ecr describe-images --repository-name demo-app
```

### Lab 2: Cross-Region Replication
```bash
aws ecr create-repository --repository-name demo-app --region eu-west-1
aws ecr put-replication-configuration --replication-configuration '{
    "rules": [{"destinations": [{"region": "eu-west-1", "registryId": "ACCT"}]}]
}'
```

---

## Interview Questions

1. **What is ECR and why use it over Docker Hub?**
   > ECR is AWS's private container registry. Benefits over Docker Hub: integrated with IAM (fine-grained access), no rate limits, image scanning for vulnerabilities, encryption at rest (KMS), lifecycle policies, cross-region replication, and stays within your AWS network (faster pulls from ECS/EKS).

2. **How does ECR image scanning work?**
   > Two types: Basic scanning (free, uses Clair CVE database) and Enhanced scanning (uses Amazon Inspector, continuous scanning, more accurate). Scan on push or manually. Returns findings with severity (Critical, High, Medium, Low). Block deployments in CI/CD if Critical vulns found.

3. **What is image tag immutability?**
   > When enabled, once a tag (e.g., `v1.0.0`) is pushed, it cannot be overwritten. Prevents `latest` tag from being accidentally replaced. Best practice: use immutable tags with semantic versioning. This ensures what you tested is what gets deployed.

4. **How to reduce ECR storage costs?**
   > Lifecycle policies: delete untagged images after 1 day, keep only last N tagged images, expire images older than X days. This alone can cut costs by 80%+. Also: use multi-stage Docker builds to reduce image size, use Alpine/distroless base images.

5. **How does ECR authentication work?**
   > `aws ecr get-login-password` returns a temporary token (valid 12 hours). Use it with `docker login`. For ECS/EKS, the task execution role must have `ecr:GetAuthorizationToken` and `ecr:BatchGetImage` permissions. No long-lived credentials stored.

6. **How to implement cross-account image sharing?**
   > Option 1: ECR repository policy allowing cross-account pull. Option 2: ECR replication to copy images to other accounts. Option 3: Shared ECR in a central account. Best practice: central build account pushes to ECR, other accounts pull via repository policy.
