# AWS Code* Services — DevOps on AWS

> AWS-native CI/CD suite: CodeCommit (source control), CodeBuild (build/test), CodeDeploy (deployment), CodePipeline (orchestration). End-to-end deployment automation without leaving AWS.

---

## Real-World Analogy

Think of a **car assembly line**:
- **CodeCommit** = the design vault where blueprints are stored
- **CodeBuild** = the factory floor where parts are assembled and tested
- **CodeDeploy** = the delivery truck that ships finished cars to dealers
- **CodePipeline** = the assembly line controller that orchestrates everything in order

---

## Architecture Overview

```
Developer → CodeCommit → CodePipeline → CodeBuild → CodeDeploy → Production
               (source)    (orchestrate)   (build)     (deploy)

  ┌────────────┐    ┌──────────────┐    ┌───────────┐    ┌────────────┐
  │ CodeCommit │───▶│ CodePipeline │───▶│ CodeBuild │───▶│ CodeDeploy │
  │ (Git repo) │    │ (workflow)   │    │ (compile, │    │ (EC2, ECS, │
  │            │    │              │    │  test,    │    │  Lambda,   │
  │ or GitHub  │    │              │    │  package) │    │  on-prem)  │
  └────────────┘    └──────────────┘    └───────────┘    └────────────┘
                           │                                    │
                    ┌──────▼──────┐                    ┌───────▼───────┐
                    │ Manual      │                    │ Deployment    │
                    │ Approval    │                    │ Strategies    │
                    │ (optional)  │                    │ In-place,     │
                    └─────────────┘                    │ Blue/Green    │
                                                      └───────────────┘
```

---

## CodeCommit — Source Control

> AWS-managed Git repositories. Private, encrypted, integrated with IAM.

| Feature | Description |
|---------|-------------|
| **Protocol** | HTTPS, SSH, or HTTPS (GRC) |
| **Authentication** | IAM users, Git credentials, SSH keys |
| **Encryption** | At rest (KMS) and in transit (TLS) |
| **Triggers** | SNS notifications and Lambda on push events |
| **Approval Rules** | Require N approvals before merge |
| **Cross-Account** | Share repos via IAM roles |

> **Note:** AWS announced CodeCommit won't accept new customers (July 2024). Existing users can continue. For new projects, use GitHub or GitLab.

```bash
# Create repository
aws codecommit create-repository \
    --repository-name my-app \
    --repository-description "My application repo"

# Clone
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/my-app

# Set up triggers (notify on push)
aws codecommit put-repository-triggers \
    --repository-name my-app \
    --triggers '[{
      "name": "push-notify",
      "destinationArn": "arn:aws:sns:us-east-1:ACCT:repo-updates",
      "events": ["all"],
      "branches": ["main"]
    }]'

# Create pull request
aws codecommit create-pull-request \
    --title "Add new feature" \
    --targets '[{
      "repositoryName": "my-app",
      "sourceReference": "feature/login",
      "destinationReference": "main"
    }]'

# Create approval rule
aws codecommit create-approval-rule-template \
    --approval-rule-template-name "require-2-approvals" \
    --approval-rule-template-content '{
      "Version": "2018-11-08",
      "Statements": [{
        "Type": "Approvers",
        "NumberOfApprovalsNeeded": 2,
        "ApprovalPoolMembers": ["arn:aws:iam::ACCT:root"]
      }]
    }'
```

---

## CodeBuild — Build & Test

> Fully managed build service. Compiles source code, runs tests, produces deployable artifacts. Pay per build-minute.

| Feature | Description |
|---------|-------------|
| **Build Environments** | Ubuntu, Amazon Linux, Windows (Docker containers) |
| **Runtimes** | Java, Python, Node.js, Go, Ruby, PHP, .NET, Docker |
| **buildspec.yml** | Build instructions file (phases: install, pre_build, build, post_build) |
| **Artifacts** | Output to S3 (zip, tar, jar, Docker image) |
| **Caching** | S3 or local caching for dependencies |
| **VPC Access** | Build inside VPC to access private resources |
| **Reports** | JUnit, Cucumber, NUnit test reports |
| **Concurrent Builds** | Default 60, can request increase |

### buildspec.yml

```yaml
version: 0.2

env:
  variables:
    ENV: production
  parameter-store:
    DB_PASSWORD: /myapp/db-password
  secrets-manager:
    API_KEY: myapp/api:api_key

phases:
  install:
    runtime-versions:
      java: corretto17
    commands:
      - echo "Installing dependencies..."

  pre_build:
    commands:
      - echo "Logging in to ECR..."
      - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCT.dkr.ecr.us-east-1.amazonaws.com

  build:
    commands:
      - echo "Building..."
      - mvn clean package -DskipTests=false
      - docker build -t my-app .
      - docker tag my-app:latest ACCT.dkr.ecr.us-east-1.amazonaws.com/my-app:$CODEBUILD_RESOLVED_SOURCE_VERSION

  post_build:
    commands:
      - echo "Pushing to ECR..."
      - docker push ACCT.dkr.ecr.us-east-1.amazonaws.com/my-app:$CODEBUILD_RESOLVED_SOURCE_VERSION
      - echo "Writing image definitions file..."
      - printf '[{"name":"my-app","imageUri":"%s"}]' ACCT.dkr.ecr.us-east-1.amazonaws.com/my-app:$CODEBUILD_RESOLVED_SOURCE_VERSION > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
    - target/*.jar
  discard-paths: yes

reports:
  junit-reports:
    files:
      - 'target/surefire-reports/*.xml'
    file-format: JUNITXML

cache:
  paths:
    - '/root/.m2/**/*'
```

```bash
# Create CodeBuild project
aws codebuild create-project \
    --name my-app-build \
    --source '{"type":"CODECOMMIT","location":"https://git-codecommit.us-east-1.amazonaws.com/v1/repos/my-app"}' \
    --artifacts '{"type":"S3","location":"my-app-artifacts","packaging":"ZIP"}' \
    --environment '{
      "type": "LINUX_CONTAINER",
      "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
      "computeType": "BUILD_GENERAL1_MEDIUM",
      "privilegedMode": true
    }' \
    --service-role arn:aws:iam::ACCT:role/CodeBuildServiceRole

# Start build manually
aws codebuild start-build --project-name my-app-build

# View build logs
aws codebuild batch-get-builds --ids BUILD_ID
```

---

## CodeDeploy — Deployment Automation

> Automate deployments to EC2, ECS, Lambda, or on-premises servers. Supports rolling, blue/green, and canary strategies.

### Deployment Targets

| Target | Strategy |
|--------|----------|
| **EC2 / On-Premise** | In-place, Blue/Green |
| **ECS (Fargate)** | Blue/Green (with traffic shifting) |
| **Lambda** | Canary, Linear, All-at-once |

### appspec.yml (EC2)

```yaml
version: 0.0
os: linux

files:
  - source: /
    destination: /var/www/myapp

permissions:
  - object: /var/www/myapp
    owner: www-data
    group: www-data
    mode: "755"

hooks:
  BeforeInstall:
    - location: scripts/stop-server.sh
      timeout: 300
  AfterInstall:
    - location: scripts/install-dependencies.sh
      timeout: 300
  ApplicationStart:
    - location: scripts/start-server.sh
      timeout: 300
  ValidateService:
    - location: scripts/health-check.sh
      timeout: 300
```

### Deployment Lifecycle (EC2)

```
ApplicationStop
    → DownloadBundle
        → BeforeInstall
            → Install
                → AfterInstall
                    → ApplicationStart
                        → ValidateService
```

### appspec.yml (ECS Blue/Green)

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:us-east-1:ACCT:task-definition/my-app:2"
        LoadBalancerInfo:
          ContainerName: "my-app"
          ContainerPort: 8080

Hooks:
  - BeforeInstall: "arn:aws:lambda:us-east-1:ACCT:function:pre-deploy-check"
  - AfterInstall: "arn:aws:lambda:us-east-1:ACCT:function:smoke-test"
  - AfterAllowTestTraffic: "arn:aws:lambda:us-east-1:ACCT:function:integration-test"
  - BeforeAllowTraffic: "arn:aws:lambda:us-east-1:ACCT:function:final-validation"
```

### Lambda Traffic Shifting

| Strategy | Pattern |
|----------|---------|
| **Canary10Percent5Minutes** | 10% → wait 5 min → 100% |
| **Canary10Percent30Minutes** | 10% → wait 30 min → 100% |
| **Linear10PercentEvery1Minute** | +10% every minute |
| **Linear10PercentEvery10Minutes** | +10% every 10 minutes |
| **AllAtOnce** | 100% immediately |

```bash
# Create application
aws deploy create-application --application-name my-app

# Create deployment group (EC2)
aws deploy create-deployment-group \
    --application-name my-app \
    --deployment-group-name production \
    --deployment-config-name CodeDeployDefault.OneAtATime \
    --ec2-tag-filters '[{"Key":"Environment","Value":"prod","Type":"KEY_AND_VALUE"}]' \
    --service-role-arn arn:aws:iam::ACCT:role/CodeDeployServiceRole \
    --auto-rollback-configuration '{"enabled":true,"events":["DEPLOYMENT_FAILURE"]}'

# Deploy
aws deploy create-deployment \
    --application-name my-app \
    --deployment-group-name production \
    --s3-location bucket=my-artifacts,key=my-app.zip,bundleType=zip
```

---

## CodePipeline — CI/CD Orchestration

> Visual workflow that orchestrates source, build, test, and deploy stages. The glue that connects Code* services.

```
┌──────────────────────────────────────────────────────────────┐
│                     CodePipeline                              │
│                                                               │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────────┐ │
│  │ Source   │──▶│ Build   │──▶│ Test    │──▶│ Deploy      │ │
│  │         │   │         │   │         │   │             │ │
│  │ GitHub  │   │ Build   │   │ Build   │   │ CodeDeploy  │ │
│  │ or CC   │   │ Code    │   │ Reports │   │ to EC2/ECS  │ │
│  └─────────┘   └─────────┘   └─────────┘   └─────────────┘ │
│                                    │                         │
│                              ┌─────▼─────┐                  │
│                              │  Manual    │                  │
│                              │  Approval  │                  │
│                              └───────────┘                  │
└──────────────────────────────────────────────────────────────┘
```

### Pipeline Concepts

| Concept | Description |
|---------|-------------|
| **Stage** | Logical group of actions (Source, Build, Test, Deploy) |
| **Action** | A task within a stage (CodeBuild, CodeDeploy, Lambda, Manual Approval) |
| **Artifact** | Files passed between stages (stored in S3) |
| **Transition** | Connection between stages (can be disabled/enabled) |
| **Trigger** | What starts the pipeline (push to branch, schedule, manual) |

```bash
# Create pipeline (JSON definition)
aws codepipeline create-pipeline --pipeline '{
  "name": "my-app-pipeline",
  "roleArn": "arn:aws:iam::ACCT:role/CodePipelineServiceRole",
  "stages": [
    {
      "name": "Source",
      "actions": [{
        "name": "SourceAction",
        "actionTypeId": {
          "category": "Source",
          "owner": "AWS",
          "provider": "CodeCommit",
          "version": "1"
        },
        "configuration": {
          "RepositoryName": "my-app",
          "BranchName": "main"
        },
        "outputArtifacts": [{"name": "SourceOutput"}]
      }]
    },
    {
      "name": "Build",
      "actions": [{
        "name": "BuildAction",
        "actionTypeId": {
          "category": "Build",
          "owner": "AWS",
          "provider": "CodeBuild",
          "version": "1"
        },
        "configuration": {
          "ProjectName": "my-app-build"
        },
        "inputArtifacts": [{"name": "SourceOutput"}],
        "outputArtifacts": [{"name": "BuildOutput"}]
      }]
    },
    {
      "name": "Approval",
      "actions": [{
        "name": "ManualApproval",
        "actionTypeId": {
          "category": "Approval",
          "owner": "AWS",
          "provider": "Manual",
          "version": "1"
        },
        "configuration": {
          "NotificationArn": "arn:aws:sns:us-east-1:ACCT:pipeline-approvals"
        }
      }]
    },
    {
      "name": "Deploy",
      "actions": [{
        "name": "DeployAction",
        "actionTypeId": {
          "category": "Deploy",
          "owner": "AWS",
          "provider": "CodeDeploy",
          "version": "1"
        },
        "configuration": {
          "ApplicationName": "my-app",
          "DeploymentGroupName": "production"
        },
        "inputArtifacts": [{"name": "BuildOutput"}]
      }]
    }
  ],
  "artifactStore": {
    "type": "S3",
    "location": "my-pipeline-artifacts"
  }
}'

# View pipeline status
aws codepipeline get-pipeline-state --name my-app-pipeline
```

---

## Real-Time Example: Complete CI/CD Pipeline

**Scenario:** Java microservice: CodeCommit → CodeBuild (Maven + Docker) → CodeDeploy to ECS.

```bash
# 1. Developer pushes to CodeCommit
git push origin main

# 2. CodePipeline detects change (CloudWatch Event)
# 3. Source stage: pulls code
# 4. Build stage: CodeBuild runs buildspec.yml
#    - mvn clean package
#    - docker build + push to ECR
#    - Output: imagedefinitions.json
# 5. Approval stage (optional): team lead reviews
# 6. Deploy stage: CodeDeploy updates ECS service
#    - Blue/Green: new task set created
#    - Health checks pass
#    - Traffic shifted (canary: 10% → 100%)
#    - Old task set terminated

# Monitor pipeline
aws codepipeline get-pipeline-execution \
    --pipeline-name my-app-pipeline \
    --pipeline-execution-id EXECUTION_ID
```

---

## AWS Code* vs GitHub Actions vs Jenkins

| Feature | AWS Code* | GitHub Actions | Jenkins |
|---------|-----------|---------------|---------|
| **Hosting** | AWS-managed | GitHub-managed | Self-hosted |
| **Source** | CodeCommit/GitHub/S3 | GitHub | Any SCM |
| **Build** | CodeBuild | GitHub runners | Jenkins agents |
| **Deploy** | CodeDeploy (EC2/ECS/Lambda) | Custom actions | Plugins |
| **Cost** | Pay per pipeline/build-min | Free tier + per-min | Free (infra cost) |
| **Multi-cloud** | AWS only | Any cloud | Any cloud |
| **IAM** | Native IAM roles | OIDC federation | Plugin-based |
| **Approval** | Built-in manual approval | Environment protection | Built-in |
| **Best for** | AWS-centric teams | GitHub-centric teams | Complex/legacy pipelines |

---

## Labs

### Lab 1: Create CodeBuild Project
```bash
# Fork a sample repository
# Create buildspec.yml with install, build, post_build phases
# Create CodeBuild project via console or CLI
# Run build and view logs
# Check artifacts in S3
```

### Lab 2: Set Up CodeDeploy to EC2
```bash
# Launch EC2 instance with CodeDeploy agent
sudo yum install -y ruby wget
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x install && sudo ./install auto

# Create appspec.yml with lifecycle hooks
# Create deployment group targeting EC2 by tags
# Deploy application revision
# Monitor deployment events
```

### Lab 3: Build End-to-End Pipeline with CodePipeline
```bash
# Create pipeline with 4 stages:
# 1. Source: GitHub or CodeCommit
# 2. Build: CodeBuild (compile + test + docker)
# 3. Approval: Manual approval with SNS notification
# 4. Deploy: CodeDeploy to EC2 or ECS

# Test the full pipeline by pushing a code change
# Monitor each stage in the console
# Test rollback on deployment failure
```

---

## Interview Questions

1. **What is AWS CodePipeline?**
   → Managed CI/CD service that orchestrates source, build, test, and deploy stages. Integrates natively with CodeCommit, CodeBuild, CodeDeploy, and third-party tools.

2. **CodeBuild vs Jenkins — when to use which?**
   → CodeBuild: serverless (no servers to manage), pay per build-minute, native AWS integration. Jenkins: full control, extensive plugin ecosystem, multi-cloud, free (self-hosted).

3. **Explain CodeDeploy deployment strategies.**
   → EC2: In-place (update existing) or Blue/Green (new fleet → swap). ECS: Blue/Green with traffic shifting. Lambda: Canary, Linear, AllAtOnce. Auto-rollback on failure.

4. **What is a buildspec.yml?**
   → Build instructions for CodeBuild. Defines phases (install, pre_build, build, post_build), environment variables, artifacts, cache, and reports.

5. **How does CodeDeploy appspec.yml work?**
   → Deployment instructions. For EC2: defines files to copy + lifecycle hook scripts. For ECS: defines task definition + Lambda validation hooks. For Lambda: traffic shifting config.

6. **Can CodePipeline deploy to non-AWS targets?**
   → Yes, with custom actions or Lambda functions. CodeDeploy also supports on-premises servers with the CodeDeploy agent installed.

7. **How do you handle secrets in CodeBuild?**
   → Use Systems Manager Parameter Store (`parameter-store` in env) or Secrets Manager (`secrets-manager` in env). Never hardcode in buildspec.yml.

8. **What triggers a CodePipeline execution?**
   → CloudWatch Events (EventBridge) on source changes, webhooks (GitHub), scheduled via EventBridge, or manual trigger. Polling source (legacy) also supported.
