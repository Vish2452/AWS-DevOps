# SRE — Site Reliability Engineering & Incident Management

> **Objective:** Implement SRE principles in production Kubernetes environments. Define SLIs/SLOs, manage error budgets, run war-room simulations, write blameless postmortems, and build incident response procedures.

---

## 🏥 Real-World Analogy: SRE is Like Running a Hospital Emergency Room

Imagine your production system is a **hospital** and your users are **patients**:

```
🏥 YOUR PRODUCTION SYSTEM = HOSPITAL
│
├── 📊 SLI (Service Level Indicator) = Patient Vital Signs
│   What we MEASURE:
│   - Response time = How fast a nurse responds to a call
│   - Error rate = How often treatments fail
│   - Availability = Is the ER open 24/7?
│   - Throughput = How many patients treated per hour
│
├── 🎯 SLO (Service Level Objective) = Quality Standards
│   What we PROMISE:
│   "99.9% of emergencies will be responded to within 5 minutes"
│   "Fewer than 0.1% of surgeries will have complications"
│   This leaves 0.1% wiggle room — that's the error budget!
│
├── 💰 Error Budget = Allowed "Oops" Quota
│   99.9% uptime = 8.76 hours of downtime allowed per YEAR.
│   That's your budget. Spend it wisely!
│   
│   Budget remaining: 6.5 hours
│     → "We can afford to do a risky deployment" ✅
│   Budget exhausted: 0 hours left
│     → "FREEZE all changes! Focus only on reliability" ❌
│
├── 🚨 Incident Response = Emergency Room Protocol
│   Severity 1 (SEV1) = Heart attack! All hands on deck!
│     • War room opens immediately
│     • Incident Commander leads the response
│     • Communication lead updates stakeholders every 15 min
│     • Engineers work on fix
│
│   Severity 3 (SEV3) = Sprained ankle. Schedule a doctor visit.
│     • Create a Jira ticket
│     • Fix during business hours
│
└── 📝 Postmortem = Medical Case Review (Blameless!)
    After every major incident:
    "What happened? Why? How do we prevent it?"
    NOT: "Who do we fire?" (Blameless = learning culture)
    
    Template:
    1. Timeline of events
    2. Root cause (5 Whys analysis)
    3. What went well
    4. What went wrong
    5. Action items with owners and deadlines
```

### Error Budget in Action
```
  📊 99.9% SLO = 43.8 minutes of downtime allowed per month

  January:
  ┌───────────────────────────────────────┐
  │ Incident 1: DB failover        − 12 min │
  │ Incident 2: Bad deploy          −  8 min │
  │ Remaining budget:                23 min │
  │ Status: ✅ Can ship new features         │
  └───────────────────────────────────────┘

  February:
  ┌───────────────────────────────────────┐
  │ Incident 1: Major outage       − 40 min │
  │ Remaining budget:                 3 min │
  │ Status: ❌ FREEZE deployments!           │
  │ Focus: Only reliability improvements     │
  └───────────────────────────────────────┘
  
  This is how Google, Netflix, and Amazon balance speed vs. reliability!
```

### Google's Famous SRE Rule
> "Hope is not a strategy." — Google SRE Book
>
> If you're hoping your system stays up, you're doing SRE wrong.
> Measure it, set a target, automate the response.

---

## SRE Fundamentals

### The SRE Pyramid
```
           ┌─────────────────┐
           │   Product       │  ← Feature velocity
           │   Development   │
           ├─────────────────┤
           │   Release       │  ← CI/CD, canary, blue-green
           │   Engineering   │
           ├─────────────────┤
           │   Monitoring &  │  ← Observability, alerting
           │   Observability │
           ├─────────────────┤
           │   Incident      │  ← On-call, war rooms, RCA
           │   Response      │
           ├─────────────────┤
           │   Capacity      │  ← Scaling, cost, load planning
           │   Planning      │
           └─────────────────┘
```

### Key Terms
| Term | Definition |
|------|-----------|
| **SLI** | Service Level Indicator — measurable metric (e.g., latency, error rate) |
| **SLO** | Service Level Objective — target for an SLI (e.g., 99.9% availability) |
| **SLA** | Service Level Agreement — contractual promise with consequences |
| **Error Budget** | Allowed downtime: 100% - SLO = error budget |
| **Toil** | Repetitive, automatable operational work |
| **MTTR** | Mean Time To Recovery |
| **MTTD** | Mean Time To Detection |
| **MTBF** | Mean Time Between Failures |

---

## SLIs, SLOs & Error Budgets

### Defining SLIs
```yaml
# sli-definitions.yaml
slis:
  availability:
    description: "Percentage of successful HTTP requests"
    formula: "successful_requests / total_requests * 100"
    good_event: "HTTP status < 500"
    bad_event: "HTTP status >= 500"
    measurement: "ratio"

  latency:
    description: "Percentage of requests served within threshold"
    formula: "requests_under_threshold / total_requests * 100"
    threshold: "300ms for p99"
    measurement: "distribution"

  throughput:
    description: "System processes minimum expected load"
    formula: "actual_rps / expected_rps * 100"
    threshold: "> 95% of expected RPS"
```

### SLO Dashboard (PromQL)
```promql
# Availability SLI (last 30 days)
1 - (
  sum(rate(http_requests_total{status=~"5.."}[30d]))
  /
  sum(rate(http_requests_total[30d]))
) 

# Latency SLI (p99 under 300ms)
sum(rate(http_request_duration_seconds_bucket{le="0.3"}[30d]))
/
sum(rate(http_request_duration_seconds_count[30d]))

# Error Budget Remaining
(1 - (
  sum(increase(http_requests_total{status=~"5.."}[30d]))
  /
  sum(increase(http_requests_total[30d]))
)) - 0.999
# Result > 0 = budget remaining, < 0 = budget exhausted
```

### Error Budget Policy
```markdown
## Error Budget Policy

### When Error Budget is > 50%
- Normal feature development velocity
- Standard deployment frequency
- Regular toil reduction work

### When Error Budget is 25-50%
- Slow deployment frequency (1/day → 2/week)
- Increase monitoring coverage
- Prioritize reliability improvements

### When Error Budget is < 25%
- Feature freeze — reliability work only
- All hands on reliability improvements
- Daily error budget review meetings

### When Error Budget is Exhausted (0%)
- Full deployment freeze
- Incident-level response to restore budget
- Executive review required to resume deploys
```

---

## Incident Management

### Incident Severity Levels
| Level | Name | Description | Response Time | Example |
|-------|------|-------------|---------------|---------|
| **SEV1** | Critical | Service down, all users affected | 5 min | App offline, data loss |
| **SEV2** | Major | Degraded service, most users affected | 15 min | High error rate, slow response |
| **SEV3** | Minor | Partial impact, some users affected | 30 min | Single feature broken |
| **SEV4** | Low | Minimal impact | Next business day | UI bug, non-critical alert |

### Incident Response Procedure
```
┌─ Detection ──────────────────────────────────────┐
│ 1. Alert fires (PagerDuty/Slack)                 │
│ 2. On-call engineer acknowledges                 │
│ 3. Initial assessment (severity classification)  │
└───────────────────────┬──────────────────────────┘
                        │
┌─ Triage (< 15 min) ──┴──────────────────────────┐
│ 4. Check dashboards & recent changes             │
│ 5. Determine blast radius                        │
│ 6. Decide: can fix quickly? or escalate?         │
│ 7. Start incident channel (#inc-YYYYMMDD-desc)   │
└───────────────────────┬──────────────────────────┘
                        │
┌─ War Room ────────────┴──────────────────────────┐
│ Roles:                                           │
│   • Incident Commander (IC) — coordinates        │
│   • Comms Lead — stakeholder updates             │
│   • Operations Lead — executes fixes             │
│   • Subject Matter Expert — domain knowledge     │
│                                                  │
│ 8. IC declares incident severity                 │
│ 9. Ops Lead investigates and applies fix         │
│ 10. Comms Lead updates status page               │
│ 11. Document timeline in real-time               │
└───────────────────────┬──────────────────────────┘
                        │
┌─ Resolution ──────────┴──────────────────────────┐
│ 12. Verify fix (health checks, dashboards)       │
│ 13. Monitor for regression (30 min)              │
│ 14. IC declares incident resolved                │
│ 15. Schedule postmortem (within 48 hours)        │
└──────────────────────────────────────────────────┘
```

### On-Call Rotation (PagerDuty / Opsgenie)
```yaml
# on-call-schedule.yaml
schedule:
  name: "DevOps Primary On-Call"
  timezone: "America/New_York"
  rotation:
    type: weekly
    start: "2026-01-05T09:00:00"
    members:
      - name: "Alice"
        escalation_delay: 15m
      - name: "Bob"
        escalation_delay: 15m
      - name: "Charlie"
        escalation_delay: 15m

escalation_policy:
  - level: 1
    target: primary-on-call
    delay: 15m
  - level: 2
    target: secondary-on-call
    delay: 15m
  - level: 3
    target: engineering-manager
    delay: 10m
```

---

## Blameless Postmortem Template

```markdown
# Incident Postmortem: [Title]

## Summary
**Date:** 2026-02-15
**Duration:** 45 minutes (14:30 - 15:15 UTC)  
**Severity:** SEV2  
**Impact:** 30% of API requests returned 503 errors  
**On-call:** Alice (IC), Bob (Ops)

## Timeline (UTC)
| Time | Event |
|------|-------|
| 14:28 | CloudWatch alarm: ECS task count below threshold |
| 14:30 | PagerDuty alert acknowledged by Alice |
| 14:32 | Opened #inc-20260215-api-503 in Slack |
| 14:35 | Identified: recent deployment (14:20) changed DB connection pool |
| 14:40 | Decision: rollback to previous task definition |
| 14:42 | Initiated ECS service rollback via GitHub Actions |
| 14:50 | New tasks running, error rate dropping |
| 15:00 | Error rate back to baseline |
| 15:15 | Incident declared resolved after 15 min monitoring |

## Root Cause
The deployment at 14:20 included a change to the database connection 
pool configuration (max connections reduced from 20 to 5). Under 
normal load, this caused connection exhaustion, leading to 503 errors.

## What Went Well
- Alert fired within 2 minutes of issue starting
- On-call responded within 2 minutes
- Rollback process was automated and worked reliably

## What Went Wrong
- Configuration change was not tested under load
- No connection pool metrics in our dashboards
- PR review did not catch the risky config change

## Action Items
| # | Action | Owner | Due Date | Status |
|---|--------|-------|----------|--------|
| 1 | Add DB connection pool metrics to dashboard | Bob | 2026-02-20 | TODO |
| 2 | Add load test stage to CI/CD pipeline | Alice | 2026-02-25 | TODO |
| 3 | Create runbook for DB connection issues | Charlie | 2026-02-22 | TODO |
| 4 | Add config change detection to PR checks | Alice | 2026-03-01 | TODO |

## Lessons Learned
- Configuration changes need the same rigor as code changes
- Load testing in CI/CD would have caught this before production
- We need better observability of connection pool health
```

---

## War Room Simulation (Practice Exercise)

### Scenario: Kubernetes Pod Memory Leak

**Setup:** Deploy an application with a gradual memory leak to an EKS cluster.

```yaml
# chaos-app.yaml — App with intentional memory leak
apiVersion: apps/v1
kind: Deployment
metadata:
  name: leaky-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: leaky-app
  template:
    spec:
      containers:
      - name: app
        image: python:3.12-slim
        command:
          - python3
          - -c
          - |
            from http.server import HTTPServer, BaseHTTPRequestHandler
            import time
            memory_hog = []
            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    memory_hog.append('x' * 1024 * 1024)  # 1MB per request
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(f'Memory blocks: {len(memory_hog)}'.encode())
            HTTPServer(('', 8080), Handler).serve_forever()
        resources:
          requests:
            memory: 128Mi
          limits:
            memory: 512Mi
        ports:
        - containerPort: 8080
```

### War Room Exercise Steps
```markdown
1. **Detection Phase (10 min)**
   - Deploy the leaky app
   - Send traffic: `while true; do curl http://leaky-app:8080; sleep 0.1; done`
   - Wait for OOMKilled events / pod restarts
   - Observe: Prometheus alerts, Grafana dashboards

2. **Triage Phase (15 min)**
   - Acknowledge the alert
   - Open incident channel
   - Assign roles: IC, Ops Lead, Comms Lead
   - Investigate: `kubectl top pods`, `kubectl describe pod`, `kubectl logs`

3. **Resolution Phase (15 min)**
   - Identify: memory growing linearly → memory leak
   - Immediate: increase memory limit to buy time
   - Longer: rollback to last known good image
   - Verify: watch memory stabilize in Grafana

4. **Postmortem Phase (20 min)**
   - Write timeline
   - Identify root cause
   - Define action items
   - Present to team
```

---

## Grafana SLO Dashboard

### Prometheus Recording Rules
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-recording-rules
spec:
  groups:
  - name: slo.rules
    interval: 30s
    rules:
    # Availability (30-day rolling)
    - record: slo:availability:ratio_rate30d
      expr: |
        1 - (
          sum(increase(http_requests_total{status=~"5.."}[30d]))
          /
          sum(increase(http_requests_total[30d]))
        )

    # Error budget remaining
    - record: slo:error_budget:remaining
      expr: |
        1 - (
          (1 - slo:availability:ratio_rate30d)
          /
          (1 - 0.999)
        )

    # Latency (p99 < 300ms)
    - record: slo:latency_p99:ratio_rate30d
      expr: |
        sum(increase(http_request_duration_seconds_bucket{le="0.3"}[30d]))
        /
        sum(increase(http_request_duration_seconds_count[30d]))

    # Burn rate (fast burn = consuming budget quickly)
    - record: slo:burn_rate:1h
      expr: |
        sum(rate(http_requests_total{status=~"5.."}[1h]))
        /
        sum(rate(http_requests_total[1h]))
        /
        (1 - 0.999)
```

---

## SRE Toolchain — Complete Setup & Integration

### SRE Monitoring & Alerting Stack
```
┌──────────────────────────────────────────────────────────────────────┐
│                        SRE Observability Stack                       │
│                                                                      │
│  ┌─── Metrics Layer ──────────┐  ┌─── Alerting Layer ─────────────┐ │
│  │ Prometheus (scrape metrics)│  │ AlertManager (routing/grouping)│ │
│  │ Thanos (long-term storage) │  │ PagerDuty (on-call paging)    │ │
│  │ VictoriaMetrics (alt.)     │  │ OpsGenie (incident tracking)  │ │
│  └────────────────────────────┘  │ Slack (team notifications)    │ │
│                                   └───────────────────────────────┘ │
│  ┌─── Dashboard Layer ────────┐  ┌─── Status Page Layer ─────────┐ │
│  │ Grafana (SLO dashboards)   │  │ Statuspage.io (public status) │ │
│  │ Grafana OnCall (rotation)  │  │ Cachet (self-hosted)          │ │
│  │ Grafana SLO plugin         │  │ Atlassian Statuspage          │ │
│  └────────────────────────────┘  └───────────────────────────────┘ │
│                                                                      │
│  ┌─── Chaos Engineering ──────┐  ┌─── Incident Management ───────┐ │
│  │ Litmus Chaos (K8s native)  │  │ Jira/Linear (action tracking) │ │
│  │ AWS FIS (Fault Injection)  │  │ Confluence (runbooks/postmort)│ │
│  │ Chaos Monkey (Netflix OSS) │  │ Rootly/FireHydrant (SaaS)     │ │
│  │ Gremlin (SaaS)             │  │ Notion (documentation)        │ │
│  └────────────────────────────┘  └───────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

### Tool Comparison: When to Use What
| Tool | Category | Best For | Cost |
|------|----------|----------|------|
| **PagerDuty** | Incident alerting | Large teams, complex escalations | $21+/user/mo |
| **OpsGenie** | Incident alerting | Atlassian ecosystem integration | $9+/user/mo |
| **Grafana OnCall** | On-call management | Open-source, Grafana users | Free (OSS) |
| **Rootly** | Incident management | Slack-first incident response | $17+/user/mo |
| **FireHydrant** | Incident management | Automated runbooks + retros | $25+/user/mo |
| **Statuspage.io** | Status page | Public-facing status updates | $29+/mo |
| **Litmus Chaos** | Chaos engineering | K8s native chaos experiments | Free (OSS) |
| **AWS FIS** | Chaos engineering | AWS-native fault injection | Pay per action |
| **Thanos** | Metrics storage | Multi-cluster, long-term metrics | Free (OSS) |

---

## Toil Elimination — Automating Repetitive Work

### What is Toil?
```
🔄 TOIL = Work that is:
  ✗ Manual         — requires human intervention
  ✗ Repetitive     — done over and over
  ✗ Automatable    — a machine COULD do it
  ✗ Reactive       — triggered by an event, not planned
  ✗ No lasting value — doesn't improve the system permanently

📊 Google's Rule: SREs should spend < 50% time on toil.
   If toil > 50%, STOP and automate!
```

### Real-World Toil Examples & Automation
| Toil Task | Frequency | Manual Time | Automated Solution | Time After |
|-----------|-----------|-------------|-------------------|------------|
| SSL certificate renewal | Monthly | 2 hours | cert-manager + Let's Encrypt | 0 min |
| Disk cleanup on servers | Weekly | 1 hour | Cron job + Lambda | 0 min |
| Scale up for traffic spike | Ad-hoc | 30 min | HPA + Karpenter | 30 sec |
| Restart crashed pods | Daily | 15 min | K8s self-healing | 3 sec |
| Generate uptime report | Weekly | 4 hours | Grafana scheduled report | 0 min |
| Rotate database passwords | Quarterly | 2 hours | Secrets Manager auto-rotation | 0 min |
| Patch OS on 50 servers | Monthly | 8 hours | SSM Patch Manager | Auto |
| Monitor SSL expiry | Daily | 30 min | CloudWatch + SNS alert | Auto |

### Toil Automation with Lambda (Real Example)
```python
# auto-remediation/stale-ebs-cleanup.py
"""
SRE Toil Automation: Find and snapshot unattached EBS volumes,
then delete volumes older than 30 days unattached.
Triggered by: CloudWatch Events (weekly schedule)
Saves: ~$2,000/month in zombie EBS costs
"""
import boto3
from datetime import datetime, timedelta, timezone

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    
    # Find unattached volumes
    volumes = ec2.describe_volumes(
        Filters=[{'Name': 'status', 'Values': ['available']}]
    )['Volumes']
    
    cleaned = []
    for vol in volumes:
        create_date = vol['CreateDate'].replace(tzinfo=timezone.utc)
        age_days = (datetime.now(timezone.utc) - create_date).days
        
        if age_days > 30:
            # Create safety snapshot first
            snap = ec2.create_snapshot(
                VolumeId=vol['VolumeId'],
                Description=f"SRE-auto-backup before cleanup (age: {age_days}d)"
            )
            # Delete the zombie volume
            ec2.delete_volume(VolumeId=vol['VolumeId'])
            cleaned.append({
                'volume': vol['VolumeId'],
                'size_gb': vol['Size'],
                'age_days': age_days,
                'snapshot': snap['SnapshotId']
            })
    
    # Report to SRE team
    if cleaned:
        total_gb = sum(v['size_gb'] for v in cleaned)
        savings = total_gb * 0.10 * 30  # $0.10/GB/month for gp3
        sns.publish(
            TopicArn='arn:aws:sns:us-east-1:123456789:sre-automation',
            Subject=f'SRE: Cleaned {len(cleaned)} zombie EBS volumes',
            Message=(
                f"Volumes cleaned: {len(cleaned)}\n"
                f"Storage freed: {total_gb} GB\n"
                f"Estimated monthly savings: ${savings:.2f}\n"
                f"Details: {cleaned}"
            )
        )
    return {'cleaned': len(cleaned), 'volumes': cleaned}
```

---

## Capacity Planning & Load Testing

### Capacity Planning Framework
```
┌──────────────────── CAPACITY PLANNING CYCLE ─────────────────────┐
│                                                                   │
│  1. MEASURE (Current State)                                       │
│     └── Current CPU, Memory, Disk, Network usage                  │
│     └── Traffic patterns: daily peaks, weekly trends              │
│     └── Cost per request: infrastructure / total requests         │
│                                                                   │
│  2. FORECAST (Future Demand)                                      │
│     └── Business growth: 20% user growth/quarter                  │
│     └── Seasonal events: Black Friday, New Year                   │
│     └── Feature launches: new features = new load patterns        │
│                                                                   │
│  3. PLAN (Right-Size Infrastructure)                              │
│     └── HPA settings for expected peak                            │
│     └── RDS instance size for 2x current connections              │
│     └── S3 bucket lifecycle for data growth                       │
│                                                                   │
│  4. TEST (Validate with Load Tests)                               │
│     └── k6 load tests simulating peak traffic                     │
│     └── Chaos experiments under load                              │
│     └── Verify auto-scaling triggers correctly                    │
│                                                                   │
│  5. REVIEW (Monthly)                                              │
│     └── Actual vs. predicted usage                                │
│     └── Cost per transaction trending                             │
│     └── Adjust forecasts                                          │
└───────────────────────────────────────────────────────────────────┘
```

### Load Testing with k6
```javascript
// load-tests/soak-test.js
// Simulates 8 hours of production traffic to find memory leaks
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '5m',  target: 100 },   // Ramp up
    { duration: '8h',  target: 100 },   // Sustained load (soak)
    { duration: '5m',  target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(99)<500'],    // 99% requests < 500ms
    errors: ['rate<0.01'],               // Error rate < 1%
  },
};

export default function () {
  const responses = http.batch([
    ['GET', 'https://api.example.com/health'],
    ['GET', 'https://api.example.com/api/v1/products'],
    ['POST', 'https://api.example.com/api/v1/orders', 
      JSON.stringify({ productId: 1, qty: 1 }),
      { headers: { 'Content-Type': 'application/json' } }
    ],
  ]);
  
  responses.forEach(res => {
    check(res, { 'status is 200': (r) => r.status === 200 });
    errorRate.add(res.status >= 400);
  });
  
  sleep(1);
}
```

```bash
# Run the load test & export results
k6 run --out json=results.json load-tests/soak-test.js

# Integration with Grafana (k6 Cloud or InfluxDB output)
k6 run --out influxdb=http://localhost:8086/k6 load-tests/soak-test.js
```

---

## Chaos Engineering — Proactive Resilience Testing

### Chaos Engineering Architecture
```
┌──────────── Chaos Engineering Framework ──────────────────┐
│                                                           │
│  HYPOTHESIS: "If a pod dies, traffic fails over in <5s"   │
│                                                           │
│  ┌─── Steady State ──┐    ┌─── Inject Chaos ──────────┐  │
│  │ All metrics normal │ →  │ Kill random pod           │  │
│  │ Latency p99 < 300ms│    │ Simulate AZ failure       │  │
│  │ Error rate < 0.1%  │    │ Network partition          │  │
│  └────────────────────┘    │ CPU/Memory stress          │  │
│                             │ DNS failure                │  │
│  ┌─── Observe ────────┐    └──────────────────────────┘  │
│  │ Did metrics recover?│                                  │
│  │ Within SLO targets? │    ┌─── Improve ─────────────┐  │
│  │ Alerts fired?       │ →  │ Fix gaps found           │  │
│  │ Auto-healing worked?│    │ Update runbooks          │  │
│  └────────────────────┘    │ Add missing alerts        │  │
│                             └──────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### AWS Fault Injection Simulator (FIS)
```json
{
  "description": "SRE Chaos: Terminate 30% of ECS tasks in production",
  "targets": {
    "ecsTaskTarget": {
      "resourceType": "aws:ecs:task",
      "selectionMode": "PERCENT(30)",
      "resourceArns": ["arn:aws:ecs:us-east-1:123456789:cluster/prod"],
      "filters": [
        {"path": "Service.Name", "values": ["api-service"]}
      ]
    }
  },
  "actions": {
    "stopEcsTasks": {
      "actionId": "aws:ecs:stop-task",
      "parameters": {},
      "targets": {"Tasks": "ecsTaskTarget"}
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:123456789:alarm:HighErrorRate"
    }
  ],
  "roleArn": "arn:aws:iam::123456789:role/FISRole"
}
```

### Litmus Chaos — Kubernetes Native
```yaml
# litmus-pod-kill.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-kill-chaos
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: 'app=api-server'
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'          # Kill pods for 60 seconds
            - name: CHAOS_INTERVAL
              value: '10'          # Every 10 seconds
            - name: FORCE
              value: 'true'
            - name: PODS_AFFECTED_PERC
              value: '50'          # Kill 50% of pods
```

---

## SRE Real-Time Project: Production Reliability Platform

### Project Architecture
```
┌───────────────────── SRE Reliability Platform ─────────────────────┐
│                                                                     │
│  ┌─── Application Layer ────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  User → Route53 → CloudFront → ALB → EKS Cluster            │  │
│  │                                          │                    │  │
│  │                    ┌─────────────────────┼──────────────┐     │  │
│  │                    │                     │              │     │  │
│  │              Frontend (React)    API (Node.js)    Worker     │  │
│  │                    │                     │              │     │  │
│  │                    └────────┬────────────┘              │     │  │
│  │                             │                           │     │  │
│  │                    RDS (PostgreSQL)              SQS Queue   │  │
│  │                    Multi-AZ + Read Replica                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─── SRE Observability Layer ──────────────────────────────────┐  │
│  │                                                               │  │
│  │  Prometheus ──→ Thanos (long-term) ──→ Grafana               │  │
│  │     │                                     │                   │  │
│  │     └── AlertManager ──→ PagerDuty ──→ On-Call Engineer      │  │
│  │                     ──→ Slack #sre-alerts                     │  │
│  │                     ──→ Email escalation                      │  │
│  │                                                               │  │
│  │  Fluent Bit ──→ OpenSearch ──→ Kibana (log analysis)         │  │
│  │  AWS X-Ray  ──→ Trace analysis (distributed tracing)         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─── SRE Automation Layer ─────────────────────────────────────┐  │
│  │                                                               │  │
│  │  HPA/Karpenter (auto-scaling)                                │  │
│  │  Litmus Chaos (weekly game days)                              │  │
│  │  k6 (continuous load testing)                                 │  │
│  │  cert-manager (auto TLS renewal)                              │  │
│  │  Lambda (toil automation: cleanup, reports, rotation)         │  │
│  │  AWS FIS (monthly chaos experiments)                          │  │
│  │  Statuspage.io (public status dashboard)                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─── SRE Governance Layer ─────────────────────────────────────┐  │
│  │                                                               │  │
│  │  SLI/SLO Definitions → Error Budget Dashboard                │  │
│  │  Incident Response Playbook → PagerDuty Escalation           │  │
│  │  Postmortem Template → Confluence Knowledge Base              │  │
│  │  Capacity Planning → Monthly Review                           │  │
│  │  On-Call Rotation → Grafana OnCall                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Project Implementation Steps

#### Step 1: Define SLIs/SLOs for Each Service
```yaml
# slo-config/api-service.yaml
service: api-service
slos:
  - name: availability
    target: 99.95%
    sli: "HTTP 2xx+3xx / total requests"
    window: 30d
    error_budget: 21.9 minutes/month
    
  - name: latency-p99
    target: 99%
    sli: "requests with latency < 500ms / total requests"
    window: 30d
    
  - name: throughput
    target: 95%
    sli: "actual RPS / expected RPS"
    window: 1h
    alert: "If < 80% for 10 minutes"

burn_rate_alerts:
  fast_burn:
    window: 5m
    budget_consumption: 2%     # 2% error budget in 5 min
    severity: critical
  slow_burn:
    window: 6h
    budget_consumption: 5%     # 5% budget in 6 hours
    severity: warning
```

#### Step 2: Build Grafana SLO Dashboards
```json
{
  "dashboard": {
    "title": "SRE: Service SLO Dashboard",
    "panels": [
      {
        "title": "Availability (30-day rolling)",
        "type": "gauge",
        "targets": [{"expr": "slo:availability:ratio_rate30d * 100"}],
        "thresholds": [
          {"value": 99.9, "color": "green"},
          {"value": 99.5, "color": "yellow"},
          {"value": 0, "color": "red"}
        ]
      },
      {
        "title": "Error Budget Remaining",
        "type": "stat",
        "targets": [{"expr": "slo:error_budget:remaining * 100"}],
        "unit": "percent"
      },
      {
        "title": "Error Budget Burn Rate (1h)",
        "type": "timeseries",
        "targets": [{"expr": "slo:burn_rate:1h"}],
        "thresholds": [
          {"value": 1, "color": "green"},
          {"value": 14.4, "color": "red"}
        ]
      },
      {
        "title": "Latency P99 (ms)",
        "type": "timeseries",
        "targets": [{"expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) * 1000"}]
      }
    ]
  }
}
```

#### Step 3: On-Call Runbook Structure
```markdown
# Runbook: API-SERVICE-HIGH-ERROR-RATE

## Alert
- **Alert Name:** HighErrorRate  
- **Severity:** Critical  
- **Condition:** 5xx rate > 5% for 5 minutes  

## Diagnosis Steps
1. Check recent deployments: `kubectl rollout history deployment/api-service -n production`
2. Check pod status: `kubectl get pods -n production -l app=api-service`
3. Check logs: `kubectl logs -l app=api-service -n production --tail=100`
4. Check database: `SELECT count(*) FROM pg_stat_activity WHERE state = 'active';`
5. Check downstream services: Grafana → Service Dependency Dashboard

## Common Causes & Fixes
| Cause | Symptoms | Fix |
|-------|----------|-----|
| Bad deployment | Errors started after deploy | `kubectl rollout undo deployment/api-service` |
| DB connection pool exhausted | "too many connections" in logs | Restart pods or increase pool size |
| Downstream service down | Timeout errors in logs | Check dependency health, enable circuit breaker |
| Memory leak | OOMKilled events | Scale replicas, then investigate leak |
| Traffic spike beyond capacity | HPA at max replicas | Increase HPA max, add Karpenter nodes |

## Escalation
- If not resolved in 15 min → Escalate to SRE lead
- If data loss suspected → Escalate to Database team + Engineering Manager
```

---

## Deliverables
- [ ] SLI/SLO definitions for 3+ services (availability, latency, throughput)
- [ ] Error budget tracking dashboard in Grafana
- [ ] Error budget policy document
- [ ] Incident severity classification guide
- [ ] On-call rotation schedule and escalation policy
- [ ] Incident response procedure (detection → resolution)
- [ ] War room simulation executed with full timeline
- [ ] Blameless postmortem written from war room exercise
- [ ] Prometheus recording rules for SLO calculations
- [ ] Burn rate alerts (fast + slow burn)
- [ ] Chaos engineering scenario (memory leak, network partition)
- [ ] Sprint planning and retrospective templates for DevOps teams
- [ ] Toil inventory and automation backlog
- [ ] Capacity planning document and load test results
- [ ] k6 load test scripts (smoke, load, soak, spike)
- [ ] Litmus Chaos experiments for pod kill, network loss, AZ failure
- [ ] AWS FIS experiment templates
- [ ] On-call runbooks for top 10 alerts
- [ ] Statuspage.io integration for public incident communication
- [ ] Monthly SRE review template (error budget, toil, incidents)
