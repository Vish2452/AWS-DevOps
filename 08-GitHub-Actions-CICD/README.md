# Module 8 — GitHub Actions CI/CD (1 Week)

> **Objective:** Master modern CI/CD with GitHub Actions. Build OIDC-based, zero-credential pipelines for infrastructure and application deployment.

---

## 🤖 Real-World Analogy: GitHub Actions = Your Personal Robot Assistant

If Jenkins is a factory you build and maintain yourself, **GitHub Actions is a robot butler that lives inside your GitHub repo**:

```
🏠 Think of your GitHub Repo as your HOUSE:

  📝 You write a to-do list (.github/workflows/deploy.yml):
     "When I come home (push to main):
      1. Turn on the lights (install dependencies)
      2. Check the mail (run tests)
      3. Cook dinner (build the app)
      4. Set the table (deploy to AWS)
      5. Text family it's ready (Slack notification)"

  🤖 GitHub Actions Robot:
     "Got it! I'll do this EVERY TIME you push code.
      I'll run in GitHub's cloud — no server to maintain!"
```

### Jenkins vs GitHub Actions
```
  🏭 Jenkins (Self-hosted factory)        🤖 GitHub Actions (Cloud robot)
  ┌───────────────────────────┐          ┌───────────────────────────┐
  │ You buy the building      │          │ GitHub provides the space │
  │ You hire the workers      │          │ Workers included free     │
  │ You fix broken machines   │          │ Machines auto-maintained  │
  │ You pay rent + utilities  │          │ Free for public repos!    │
  │ Full control (customize)  │          │ Easy setup (YAML files)   │
  │ Complex but powerful      │          │ Simple but flexible       │
  └───────────────────────────┘          └───────────────────────────┘
  
  Best for: Large enterprises           Best for: Most teams, startups
  with complex custom needs              that use GitHub already
```

### OIDC = Keyless Entry (No Passwords!)
```
  🔑 OLD WAY (Access Keys — risky!):
     Store AWS_ACCESS_KEY in GitHub Secrets
     If leaked → hacker has permanent access! 😱

  🎫 NEW WAY (OIDC — temporary pass!):
     GitHub: "Hey AWS, it's me — GitHub repo X, running workflow Y"
     AWS: "I trust GitHub. Here's a 15-minute temporary pass."
     After 15 mins → pass expires automatically! ✅
     
     Like a visitor badge that expires when you leave the building.
```

---

## Topics

### Core Concepts
- **Workflows** — YAML files in `.github/workflows/`
- **Jobs** — run on a runner (parallel by default)
- **Steps** — individual tasks within a job
- **Actions** — reusable units from Marketplace
- **Runners** — GitHub-hosted (ubuntu, windows, macos) or self-hosted

### Triggers
```yaml
on:
  push:              # On push to branches
    branches: [main, develop]
    paths: ['src/**']
  pull_request:      # On PR events
    branches: [main]
  workflow_dispatch:  # Manual trigger with inputs
    inputs:
      environment:
        type: choice
        options: [dev, staging, prod]
  schedule:          # Cron-based
    - cron: '0 6 * * 1-5'
  repository_dispatch: # External API trigger
```

### OIDC with AWS (Zero Credentials!)
```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
      aws-region: us-east-1
      # No access keys needed! Uses OIDC federation
```

### Security Hardening
- Pin actions to SHA: `actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29`
- Minimal `permissions` block
- Dependabot for action updates
- Environment protection rules

---

## Workflow Examples

### 1. CI Pipeline
```yaml
name: CI Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/

  build-and-push:
    needs: lint-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: aws-actions/amazon-ecr-login@v2
      - run: |
          docker build -t $ECR_REGISTRY/$ECR_REPO:${{ github.sha }} .
          docker push $ECR_REGISTRY/$ECR_REPO:${{ github.sha }}
```

### 2. Terraform Pipeline
```yaml
name: Terraform
on:
  push:
    branches: [main]
    paths: ['terraform/**']
  pull_request:
    branches: [main]
    paths: ['terraform/**']

permissions:
  contents: read
  id-token: write
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
        working-directory: terraform/
      - run: terraform plan -no-color -out=plan.tfplan
        working-directory: terraform/
      - uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan 📖
            \`\`\`
            ${process.env.PLAN_OUTPUT}
            \`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });

  apply:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: |
          terraform init
          terraform apply -auto-approve
        working-directory: terraform/
```

### 3. Multi-Environment Deploy
```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy-dev:
    uses: ./.github/workflows/deploy-reusable.yml
    with:
      environment: dev
    secrets: inherit

  deploy-staging:
    needs: deploy-dev
    uses: ./.github/workflows/deploy-reusable.yml
    with:
      environment: staging
    secrets: inherit

  deploy-prod:
    needs: deploy-staging
    uses: ./.github/workflows/deploy-reusable.yml
    with:
      environment: production
    secrets: inherit
```

---

## Real-Time Project: Full CI/CD with GitHub Actions

### Workflows
```
.github/workflows/
├── ci.yml              # Lint → Test → Build → Docker → Push to ECR
├── terraform.yml       # Plan on PR → Apply on merge
├── deploy-db.yml       # Liquibase migrations
├── deploy-app.yml      # ECS Fargate deployment
└── cleanup.yml         # Scheduled resource cleanup
```

### Key Features
- OIDC-based AWS auth (zero static credentials)
- Environment gates: dev → staging → prod
- Terraform plan comments on PRs
- Docker build with Trivy scanning
- Liquibase DB migrations on merge
- Slack notifications via webhook

### Deliverables
- [ ] 4+ GitHub Actions workflows
- [ ] OIDC IAM role configured
- [ ] Environment protection rules (staging, production)
- [ ] Terraform plan/apply pipeline
- [ ] Docker build → scan → push to ECR
- [ ] Reusable workflows and composite actions
- [ ] Branch protection with required status checks

---

## Interview Questions
1. GitHub Actions vs Jenkins — when to choose each?
2. How does OIDC authentication work with AWS?
3. How to secure GitHub Actions workflows?
4. What are reusable workflows?
5. How to implement environment-based deployment gates?
6. How to cache dependencies in GitHub Actions?
7. Self-hosted vs GitHub-hosted runners — trade-offs?
8. How to trigger a workflow from an external event?
