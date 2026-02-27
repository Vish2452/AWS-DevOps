# Real-Time Project: Team GitFlow Simulation

> **Industry Context:** Every development team needs a branching strategy. This project simulates real team collaboration on GitHub.

## Architecture

```
GitHub Organization
├── frontend-app/          # React/Next.js app
│   ├── main               # Production (protected)
│   ├── develop             # Integration branch
│   ├── feature/user-auth   # Feature branch
│   ├── feature/dashboard   # Feature branch
│   ├── release/v1.0.0      # Release preparation
│   └── hotfix/login-fix    # Emergency fix
│
├── backend-api/            # Node.js/Python API
│   ├── main
│   ├── develop
│   └── feature/*
│
└── infra-terraform/        # Infrastructure code
    ├── main
    └── feature/*
```

## Setup Instructions

### 1. Create GitHub Organization
```bash
# Using GitHub CLI
gh org create devops-training-2026 --description "DevOps Bootcamp Training"

# Create repositories
gh repo create devops-training-2026/frontend-app --public
gh repo create devops-training-2026/backend-api --public
gh repo create devops-training-2026/infra-terraform --public
```

### 2. Configure Branch Protection
```bash
# Protect main branch — requires:
# - 1 approval
# - Status checks passing
# - No direct pushes
# - Signed commits (optional)

# Via GitHub CLI
gh api repos/devops-training-2026/frontend-app/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field required_status_checks='{"strict":true,"contexts":["ci/build"]}' \
  --field enforce_admins=true
```

### 3. Setup Conventional Commits
```json
// .commitlintrc.json
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [2, "always", [
      "feat", "fix", "docs", "style", "refactor",
      "perf", "test", "chore", "ci", "build"
    ]],
    "subject-case": [2, "never", ["start-case", "pascal-case", "upper-case"]]
  }
}
```

### 4. Setup Release Please
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        id: release
        with:
          release-type: node

      - uses: actions/checkout@v4
        if: ${{ steps.release.outputs.release_created }}

      - name: Tag Docker Image
        if: ${{ steps.release.outputs.release_created }}
        run: |
          echo "New release: ${{ steps.release.outputs.tag_name }}"
          echo "Version: ${{ steps.release.outputs.major }}.${{ steps.release.outputs.minor }}.${{ steps.release.outputs.patch }}"
```

## Simulation Exercises

### Exercise 1: Feature Development
```bash
# Developer A creates a feature
git checkout develop
git pull origin develop
git checkout -b feature/user-registration
# ... make changes ...
git add .
git commit -m "feat(auth): add user registration endpoint"
git push origin feature/user-registration
# Create PR → develop
gh pr create --base develop --title "feat(auth): add user registration" --body "Adds /api/register endpoint"
```

### Exercise 2: Code Review & Merge
```bash
# Reviewer checks out PR
gh pr checkout 1
# Review code, approve
gh pr review 1 --approve --body "LGTM! Good test coverage."
# Merge
gh pr merge 1 --squash
```

### Exercise 3: Conflict Resolution
```bash
# Two developers edit the same file
# Dev A: feature/user-auth (modifies auth.js line 45)
# Dev B: feature/dashboard (modifies auth.js line 45)
# Merge Dev A first, then Dev B gets conflict
git checkout feature/dashboard
git merge develop
# CONFLICT in auth.js
# Resolve manually, then:
git add auth.js
git commit -m "fix: resolve merge conflict in auth module"
```

### Exercise 4: Hotfix Flow
```bash
# Production bug! Create hotfix from main
git checkout main
git checkout -b hotfix/login-timeout
git commit -m "fix(auth): increase login timeout to 30s"
git push origin hotfix/login-timeout
# PR to main AND develop
gh pr create --base main --title "hotfix: login timeout fix"
```

### Exercise 5: Release Process
```bash
# Create release branch
git checkout develop
git checkout -b release/v1.0.0
# Final testing, bump version
git commit -m "chore: prepare release v1.0.0"
# Merge to main
gh pr create --base main --title "release: v1.0.0"
# After merge, tag
git tag -a v1.0.0 -m "Release v1.0.0 — Initial release"
git push origin v1.0.0
# Merge back to develop
git checkout develop && git merge main
```

## Deliverables
- [ ] GitHub org with 3 repos created
- [ ] Branch protection rules configured
- [ ] 5+ PRs with code reviews completed
- [ ] At least 1 merge conflict resolved
- [ ] Hotfix flow demonstrated
- [ ] Release v1.0.0 tagged with changelog
- [ ] Conventional commits enforced via hooks
- [ ] Release Please generating automatic releases
