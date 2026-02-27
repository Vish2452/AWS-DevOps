# Module 7 — Jenkins CI/CD (1.5 Weeks)

> **Objective:** Build production CI/CD pipelines with Jenkins. Integrate SonarQube, Trivy, Docker, and Slack notifications.

---

## 🏭 Real-World Analogy: Jenkins is Like a Car Factory Assembly Line

Imagine building a car **by hand** vs. an **automated assembly line**:

```
🔧 WITHOUT CI/CD (Manual = slow, error-prone):

  Developer writes code
       │
  Manually copies to server (FTP? USB drive? 😱)
       │
  Manually runs tests (or skips them... 🙈)
       │
  Deploys at 2 AM on Friday (pray it works 🙏)
       │
  Bug found Monday → Roll back manually → Chaos!


🏭 WITH JENKINS (Automated Assembly Line):

  Developer pushes code to Git
       │
       ▼ (Jenkins triggers automatically!)
  ┌─── STATION 1: Build ──────────────────┐
  │  Compile code, install dependencies    │
  └──────────────┬────────────────────────┘
                 ▼
  ┌─── STATION 2: Quality Check ──────────┐
  │  SonarQube scans for bugs & code smells│
  └──────────────┬────────────────────────┘
                 ▼
  ┌─── STATION 3: Security Scan ──────────┐
  │  Trivy scans Docker image for CVEs     │
  └──────────────┬────────────────────────┘
                 ▼
  ┌─── STATION 4: Test ───────────────────┐
  │  Run 500 automated tests (2 minutes)   │
  └──────────────┬────────────────────────┘
                 ▼
  ┌─── STATION 5: Deploy ─────────────────┐
  │  Push to staging → smoke test → prod   │
  └──────────────┬────────────────────────┘
                 ▼
  ┌─── STATION 6: Notify ─────────────────┐
  │  Slack: "✅ v2.3.1 deployed to prod!"  │
  └────────────────────────────────────────┘

  Total time: code push → production = 12 minutes! ⚡
```

### Real-World Impact
| Metric | Manual Deploy | Jenkins CI/CD |
|--------|--------------|---------------|
| Deploys per month | 1-2 | 50-200 |
| Deploy time | 4 hours | 12 minutes |
| Failed deploys | 30% | 2% |
| Recovery time | 2-4 hours | 5 minutes (auto rollback) |
| Engineer time/week on deploys | 20 hours | 1 hour |

> **Netflix deploys thousands of times per day** using CI/CD pipelines. Without automation, they'd need 10x more engineers!

---

## Topics

### Jenkins Architecture
- **Controller (Master)** — orchestrates pipelines, UI, scheduling
- **Agents (Slaves)** — execute builds (SSH, JNLP, Docker, Kubernetes)
- **Executors** — concurrent build slots per agent

### Pipeline Types
| Type | Syntax | Use Case |
|------|--------|----------|
| **Freestyle** | UI-based | Simple builds (not recommended) |
| **Declarative Pipeline** | `pipeline {}` | Structured, most common |
| **Scripted Pipeline** | `node {}` | Maximum flexibility |
| **Multibranch** | Auto-discovers branches | Branch-per-PR workflows |

### Key Plugins
- **Blue Ocean** — modern UI for pipelines
- **Git / GitHub** — SCM integration
- **Docker Pipeline** — build containers in pipeline
- **SonarQube Scanner** — code quality
- **Slack Notification** — team alerts
- **Credentials Binding** — secure secret injection
- **Role Strategy** — RBAC

---

## Real-Time Project: Complete Jenkins Pipeline for Java Microservice

### Pipeline Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Jenkins Pipeline                           │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐ │
│  │ Git      │→│ Build    │→│ Unit     │→│ SonarQube  │ │
│  │ Checkout │  │ (Maven)  │  │ Tests    │  │ Analysis   │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘ │
│                                                     │       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────▼─────┐ │
│  │ Deploy   │←│ Approval │←│ Push     │←│ Trivy     │ │
│  │ to ECS   │  │ Gate     │  │ to ECR   │  │ Image Scan │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘ │
│        │                                                    │
│  ┌─────▼─────┐  ┌──────────┐                               │
│  │ Smoke     │→│ Slack    │                               │
│  │ Tests     │  │ Notify   │                               │
│  └───────────┘  └──────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

### Jenkinsfile
```groovy
pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        ECR_REGISTRY    = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO        = 'java-microservice'
        IMAGE_TAG       = "${env.BUILD_NUMBER}-${env.GIT_COMMIT[0..7]}"
        SONAR_URL       = 'http://sonarqube:9000'
    }

    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn sonar:sonar \
                            -Dsonar.projectKey=${ECR_REPO} \
                            -Dsonar.host.url=${SONAR_URL}
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ."
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                    trivy image --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --format table \
                        ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    docker tag ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
                """
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh """
                    aws ecs update-service --cluster staging \
                        --service ${ECR_REPO} \
                        --force-new-deployment --region ${AWS_REGION}
                """
            }
        }

        stage('Approval') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                sh """
                    aws ecs update-service --cluster production \
                        --service ${ECR_REPO} \
                        --force-new-deployment --region ${AWS_REGION}
                """
            }
        }
    }

    post {
        success {
            slackSend color: 'good',
                message: "✅ Build #${env.BUILD_NUMBER} succeeded\n${env.GIT_COMMIT_MSG}\n${env.BUILD_URL}"
        }
        failure {
            slackSend color: 'danger',
                message: "❌ Build #${env.BUILD_NUMBER} failed\n${env.GIT_COMMIT_MSG}\n${env.BUILD_URL}"
        }
        always {
            cleanWs()
        }
    }
}
```

### Jenkins Setup with Docker
```yaml
# docker-compose.yml for Jenkins lab
version: '3.9'
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins-data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false

  sonarqube:
    image: sonarqube:lts-community
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonar-data:/opt/sonarqube/data

volumes:
  jenkins-data:
  sonar-data:
```

### Deliverables
- [ ] Jenkins running with Docker Compose
- [ ] Multi-branch pipeline with Jenkinsfile
- [ ] SonarQube quality gate integrated
- [ ] Docker build → Trivy scan → ECR push
- [ ] Staging auto-deploy, production manual approval
- [ ] Slack notifications on build status
- [ ] RBAC configured for team access

---

## Interview Questions
1. Explain Jenkins pipeline stages
2. Declarative vs Scripted pipeline — when to use each?
3. How to set up Jenkins agents?
4. How to manage credentials in Jenkins?
5. What is a shared library in Jenkins?
6. How to trigger Jenkins from GitHub webhooks?
7. How to implement a quality gate?
8. How to troubleshoot a failed Jenkins build?
