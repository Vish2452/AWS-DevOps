# AIOps — AI-Powered DevOps & Intelligent Automation (2 Weeks)

> **Objective:** Leverage AI tools for DevOps productivity, implement ML-based monitoring and anomaly detection, build self-healing infrastructure, and master AI-assisted workflows.

---

## 🤖 Real-World Analogy: AIOps is Like Having a Self-Driving Car for Your Infrastructure

```
🚗 Traditional DevOps = MANUAL DRIVING:

   You (the engineer) must:
   • Watch the road (dashboards) constantly
   • Check mirrors (logs) every few seconds
   • React to road hazards (incidents) manually
   • Navigate traffic (capacity planning) yourself
   • Remember every route (runbook) in your head
   
   Result: Exhausting. You can only monitor so much.
   10 microservices? Maybe. 500? Impossible for humans.


🤖 AIOps = SELF-DRIVING CAR (Tesla Autopilot for servers):

   AI does the heavy lifting:
   • 👁️  SEES problems before you do (anomaly detection)
        "CPU pattern looks unusual — predict failure in 2 hours"
   • 🧠  UNDERSTANDS root cause (correlation)
        "5 alerts fired, but they're all caused by THIS one database"
   • 🛠️  FIXES issues automatically (self-healing)
        "Pod crashed → auto-restarted → didn't need to wake anyone"
   • 💬  COMMUNICATES in plain English (ChatOps)
        "@engineer: I detected a memory leak in payment-service.
         It will OOM in ~4 hours. Shall I restart it now?"
```

### AI Tools in Your Daily DevOps Life
```
  🌅 MORNING (AI helps you code):
     GitHub Copilot: "Here's the Terraform module you need"
     Claude/ChatGPT: "Here's why your pipeline is failing"

  ☀️ AFTERNOON (AI monitors your systems):
     CloudWatch Anomaly Detection: "Traffic is 3x normal — is this expected?"
     DevOps Guru: "This deployment caused a 40% latency increase"

  🌙 NIGHT (AI handles incidents while you sleep):
     Self-healing Lambda: "Disk full → auto-cleaned old logs → resolved"
     ChatOps bot: "Incident resolved automatically. Summary in #incidents"
     
  You wake up to: "3 incidents detected and resolved overnight. No action needed." ✅
```

### Before vs After AIOps
| Scenario | Without AIOps | With AIOps |
|----------|--------------|------------|
| Unusual traffic spike | Engineer stares at dashboard, guesses | AI: "This matches Black Friday pattern. Auto-scaling triggered." |
| 20 alerts fire at once | Engineer panics, investigates each one | AI: "All 20 trace back to database failover. Root cause: disk IOPS." |
| Memory leak | Discovered when app crashes at 3 AM | AI predicts OOM 4 hours early, notifies team |
| "Write a Terraform module" | 2 hours of documentation reading | Copilot generates 80% in 2 minutes |
| Post-incident analysis | 4-hour meeting, finger-pointing | AI generates timeline + root cause + recommendations |

---

## Week 1 — AI Tools for DevOps & Intelligent Monitoring

### AI Tools in the DevOps Workflow
```
┌────────────── DevOps + AI Integration ──────────────────┐
│                                                          │
│  Code         → GitHub Copilot, Claude, ChatGPT         │
│  Review       → AI-assisted PR reviews                   │
│  IaC          → AI-generated Terraform / CloudFormation  │
│  Debug        → AI root-cause analysis                   │
│  Docs         → Auto-generated runbooks & READMEs        │
│  Monitoring   → ML anomaly detection                     │
│  Incident     → ChatOps with AI triage                   │
│  Cost         → AI-powered FinOps recommendations        │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Prompt Engineering for DevOps
```markdown
## Effective Prompts for DevOps Tasks

### Terraform Generation
"Write a Terraform module for an EKS cluster with:
- Managed node groups (t3.large, 3-10 nodes)
- IRSA enabled for pod-level IAM
- EBS CSI driver addon
- Private endpoint access only
- KMS encryption for secrets
Follow AWS best practices and include variables.tf and outputs.tf"

### Debugging
"I'm getting 'CrashLoopBackOff' on my Kubernetes pod. The logs show:
[error log snippet]
The pod spec uses image X with these resource limits.
What are the possible causes and how do I debug this step by step?"

### Runbook Generation
"Create an incident runbook for: RDS PostgreSQL high CPU (>90%)
Include: detection method, initial triage steps, escalation criteria,
remediation steps, post-incident verification, and prevention measures.
Format as a numbered checklist."
```

### AI-Assisted Documentation Generator
```python
#!/usr/bin/env python3
"""Generate documentation from Terraform files using AI."""

import os
import json
import glob
import boto3  # or use openai library

def extract_terraform_info(tf_dir):
    """Parse .tf files to extract resource info."""
    resources = []
    variables = []
    outputs = []

    for tf_file in glob.glob(f"{tf_dir}/*.tf"):
        with open(tf_file) as f:
            content = f.read()

        # Simple extraction (production: use python-hcl2)
        for line in content.split('\n'):
            if line.strip().startswith('resource "'):
                parts = line.split('"')
                resources.append({'type': parts[1], 'name': parts[3]})
            elif line.strip().startswith('variable "'):
                name = line.split('"')[1]
                variables.append(name)
            elif line.strip().startswith('output "'):
                name = line.split('"')[1]
                outputs.append(name)

    return {
        'resources': resources,
        'variables': variables,
        'outputs': outputs,
        'file_count': len(glob.glob(f"{tf_dir}/*.tf"))
    }

def generate_readme(tf_info):
    """Generate a README from Terraform info."""
    prompt = f"""Generate a professional README.md for this Terraform module:

Resources: {json.dumps(tf_info['resources'], indent=2)}
Variables: {tf_info['variables']}
Outputs: {tf_info['outputs']}

Include: description, architecture diagram (ASCII), usage example,
required variables table, outputs table, and prerequisites."""

    # Use AWS Bedrock (Claude) for generation
    bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 4096,
            'messages': [{'role': 'user', 'content': prompt}]
        })
    )

    result = json.loads(response['body'].read())
    return result['content'][0]['text']

if __name__ == '__main__':
    info = extract_terraform_info('./terraform')
    readme = generate_readme(info)
    with open('README.md', 'w') as f:
        f.write(readme)
    print("README.md generated successfully")
```

### ML-Based Anomaly Detection for Monitoring
```python
#!/usr/bin/env python3
"""CloudWatch anomaly detection with statistical methods."""

import boto3
import numpy as np
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

ALERT_TOPIC = 'arn:aws:sns:us-east-1:123456:aiops-alerts'

def get_metric_data(namespace, metric_name, dimensions, hours=168):
    """Fetch 7 days of metric data."""
    response = cloudwatch.get_metric_statistics(
        Namespace=namespace,
        MetricName=metric_name,
        Dimensions=dimensions,
        StartTime=datetime.utcnow() - timedelta(hours=hours),
        EndTime=datetime.utcnow(),
        Period=300,  # 5-minute intervals
        Statistics=['Average']
    )
    values = [dp['Average'] for dp in sorted(response['Datapoints'], key=lambda x: x['Timestamp'])]
    return np.array(values) if values else np.array([])

def detect_anomalies(values, threshold_sigma=3):
    """Detect anomalies using Z-score method."""
    if len(values) < 10:
        return []

    mean = np.mean(values)
    std = np.std(values)

    if std == 0:
        return []

    z_scores = np.abs((values - mean) / std)
    anomaly_indices = np.where(z_scores > threshold_sigma)[0]

    return [{
        'index': int(idx),
        'value': float(values[idx]),
        'z_score': float(z_scores[idx]),
        'mean': float(mean),
        'std': float(std)
    } for idx in anomaly_indices]

def check_ecs_anomalies():
    """Monitor ECS services for anomalous behavior."""
    ecs = boto3.client('ecs')
    clusters = ecs.list_clusters()['clusterArns']

    findings = []
    for cluster_arn in clusters:
        cluster_name = cluster_arn.split('/')[-1]
        services = ecs.list_services(cluster=cluster_arn)['serviceArns']

        for service_arn in services:
            service_name = service_arn.split('/')[-1]
            dimensions = [
                {'Name': 'ClusterName', 'Value': cluster_name},
                {'Name': 'ServiceName', 'Value': service_name}
            ]

            # Check CPU anomalies
            cpu_data = get_metric_data('AWS/ECS', 'CPUUtilization', dimensions)
            cpu_anomalies = detect_anomalies(cpu_data)

            if cpu_anomalies:
                latest = cpu_anomalies[-1]
                findings.append({
                    'service': service_name,
                    'metric': 'CPUUtilization',
                    'current': latest['value'],
                    'baseline_mean': latest['mean'],
                    'deviation': latest['z_score']
                })

            # Check Memory anomalies
            mem_data = get_metric_data('AWS/ECS', 'MemoryUtilization', dimensions)
            mem_anomalies = detect_anomalies(mem_data)

            if mem_anomalies:
                latest = mem_anomalies[-1]
                findings.append({
                    'service': service_name,
                    'metric': 'MemoryUtilization',
                    'current': latest['value'],
                    'baseline_mean': latest['mean'],
                    'deviation': latest['z_score']
                })

    return findings

def lambda_handler(event, context):
    """Lambda entry point — run anomaly detection."""
    findings = check_ecs_anomalies()

    if findings:
        message = "🤖 AIOps Anomaly Detection Report\n\n"
        for f in findings:
            message += (
                f"Service: {f['service']}\n"
                f"Metric: {f['metric']}\n"
                f"Current: {f['current']:.1f}% (baseline: {f['baseline_mean']:.1f}%)\n"
                f"Deviation: {f['deviation']:.1f} sigma\n\n"
            )

        sns.publish(
            TopicArn=ALERT_TOPIC,
            Subject=f'AIOps: {len(findings)} Anomalies Detected',
            Message=message
        )

    return {'anomalies_found': len(findings), 'details': findings}
```

### CloudWatch Anomaly Detection (Native)
```hcl
# Use CloudWatch's built-in ML anomaly detection
resource "aws_cloudwatch_metric_alarm" "cpu_anomaly" {
  alarm_name          = "ecs-cpu-anomaly-detection"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 3
  threshold_metric_id = "ad1"
  alarm_actions       = [aws_sns_topic.aiops_alerts.arn]

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions  = {
        ClusterName = "production"
        ServiceName = "webapp"
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "CPUUtilization (expected)"
    return_data = true
  }
}
```

---

## Week 2 — Self-Healing & Advanced AIOps

### Self-Healing Architecture
```
Monitoring → Detect → Analyze → Decide → Act → Verify
     │          │         │         │        │       │
CloudWatch  Anomaly    AI/ML    Decision   Lambda  Health
Prometheus  Detection  Model     Engine    SSM     Check
                                   │
                          ┌────────┼────────┐
                          │        │        │
                       Restart  Scale    Rollback
                       Service  Up/Down  Deploy
```

### Self-Healing Lambda: Auto-Restart Unhealthy ECS Tasks
```python
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs = boto3.client('ecs')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """Auto-remediate unhealthy ECS services."""
    detail = event.get('detail', {})
    cluster = detail.get('clusterArn', '')
    service = detail.get('group', '').replace('service:', '')

    if not cluster or not service:
        logger.warning("Missing cluster/service info")
        return

    # Check if service is unhealthy
    response = ecs.describe_services(
        cluster=cluster, services=[service]
    )

    svc = response['services'][0]
    running = svc['runningCount']
    desired = svc['desiredCount']

    if running < desired:
        logger.info(f"Service {service}: {running}/{desired} tasks running. Triggering redeployment.")

        # Force new deployment (rolling restart)
        ecs.update_service(
            cluster=cluster,
            service=service,
            forceNewDeployment=True
        )

        # Notify team
        sns.publish(
            TopicArn=os.environ['ALERT_TOPIC'],
            Subject=f'Self-Healing: {service} restarted',
            Message=(
                f"Service {service} had {running}/{desired} healthy tasks.\n"
                f"Action: Forced new deployment.\n"
                f"Cluster: {cluster}"
            )
        )

        return {'action': 'redeployed', 'service': service}

    return {'action': 'none', 'service': service, 'status': 'healthy'}
```

### AI-Powered ChatOps (Slack Bot)
```python
"""Slack bot that uses AI to help with incident response."""

import json
import boto3
import requests
import os

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
SLACK_TOKEN = os.environ['SLACK_BOT_TOKEN']

def analyze_incident(incident_data):
    """Use Claude to analyze an incident and suggest remediation."""
    prompt = f"""Analyze this DevOps incident and provide:
1. Probable root cause
2. Immediate remediation steps (numbered)
3. Prevention recommendations
4. Suggested runbook link

Incident data:
{json.dumps(incident_data, indent=2)}"""

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 2048,
            'messages': [{'role': 'user', 'content': prompt}]
        })
    )

    result = json.loads(response['body'].read())
    return result['content'][0]['text']

def lambda_handler(event, context):
    """Slack event handler for /incident command."""
    body = json.loads(event['body'])

    # Parse incident description from Slack command
    incident_text = body.get('text', '')
    channel_id = body.get('channel_id', '')

    # Get AI analysis
    analysis = analyze_incident({
        'description': incident_text,
        'timestamp': context.invoked_function_arn,
        'source': 'slack-command'
    })

    # Post analysis to Slack
    requests.post('https://slack.com/api/chat.postMessage', headers={
        'Authorization': f'Bearer {SLACK_TOKEN}',
        'Content-Type': 'application/json'
    }, json={
        'channel': channel_id,
        'text': f"🤖 *AI Incident Analysis*\n\n{analysis}"
    })

    return {'statusCode': 200}
```

### AI-Powered Cost Optimization
```python
"""Use AI to analyze AWS costs and generate optimization recommendations."""

import boto3
import json
from datetime import datetime, timedelta

ce = boto3.client('ce', region_name='us-east-1')
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

def get_cost_data(days=30):
    end = datetime.utcnow().strftime('%Y-%m-%d')
    start = (datetime.utcnow() - timedelta(days=days)).strftime('%Y-%m-%d')

    # Get cost by service
    by_service = ce.get_cost_and_usage(
        TimePeriod={'Start': start, 'End': end},
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
    )

    # Get cost by usage type for top services
    costs = {}
    for period in by_service['ResultsByTime']:
        for group in period['Groups']:
            svc = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            costs[svc] = costs.get(svc, 0) + cost

    return dict(sorted(costs.items(), key=lambda x: x[1], reverse=True)[:15])

def ai_cost_analysis():
    cost_data = get_cost_data()

    prompt = f"""As a FinOps expert, analyze these AWS costs (last 30 days) and provide:
1. Top 3 cost optimization opportunities with estimated savings
2. Right-sizing recommendations
3. Reserved Instance / Savings Plan suggestions
4. Any unusual spending patterns

Cost data (service → total USD):
{json.dumps(cost_data, indent=2)}

Be specific with dollar amounts and actionable steps."""

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 2048,
            'messages': [{'role': 'user', 'content': prompt}]
        })
    )

    return json.loads(response['body'].read())['content'][0]['text']
```

---

## Real-Time Project: AIOps Platform

### Architecture
```
┌────────────── AIOps Platform ──────────────────────────┐
│                                                         │
│  Data Collection        Intelligence       Actions      │
│  ├─ CloudWatch ──┐      ├─ Anomaly    ┌─ Self-Heal    │
│  ├─ Prometheus ──┼──▶   │  Detection  ├─ Auto-Scale   │
│  ├─ CloudTrail ──┤      ├─ AI Triage  ├─ Rollback     │
│  └─ App Logs ────┘      ├─ Cost AI    ├─ Alert        │
│                          └─ ChatOps   └─ Notify       │
│                              │                         │
│                         ┌────┴────┐                    │
│                         │ Bedrock │                    │
│                         │ (Claude)│                    │
│                         └─────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### Deliverables
- [ ] AI-assisted Terraform and Dockerfile generation workflows
- [ ] Auto-generated documentation from Terraform modules
- [ ] ML anomaly detection Lambda (Z-score + CloudWatch native)
- [ ] Self-healing Lambda for ECS service recovery
- [ ] AI-powered Slack ChatOps bot for incident triage
- [ ] Cost optimization analysis using Bedrock (Claude)
- [ ] Prompt engineering cookbook for DevOps tasks
- [ ] War room simulation with AI-assisted RCA
- [ ] Dashboard showing anomaly detection results
- [ ] All infrastructure deployed with Terraform

---

## Interview & Career Prep

### Resume Templates
- **Freshers:** Focus on bootcamp projects, certifications, GitHub portfolio
- **Experienced (1-3 yr):** Highlight automation, CI/CD pipelines, cost savings
- **Experienced (3+ yr):** Architecture decisions, team leadership, SRE practices

### Key Portfolio Metrics to Include
- "Reduced deployment time from 2 hours to 15 minutes with CI/CD"
- "Automated infrastructure for 3 environments saving 20 hrs/week"
- "Implemented monitoring that reduced MTTR from 45min to 10min"
- "Built DevSecOps pipeline catching 100% of critical vulnerabilities pre-deploy"
- "Designed multi-account AWS landing zone serving 50+ developers"
