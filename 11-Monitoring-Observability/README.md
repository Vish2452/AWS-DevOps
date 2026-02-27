# Module 11 — Monitoring & Observability (2 Weeks)

> **Objective:** Build a production-grade observability stack with Prometheus, Grafana, and EFK on EKS. Implement alerting, dashboards, and centralized logging.

---

## 🏥 Real-World Analogy: Monitoring is Like a Hospital Patient Monitor

Imagine your servers are **patients in a hospital**:

```
🏥 YOUR APPLICATION = A PATIENT IN THE ICU
│
├── 📊 Metrics (Prometheus) = Heart Rate Monitor
│   Continuously measures vital signs:
│   - CPU usage = Heart rate (💓 normal: 40-70%, danger: >90%)
│   - Memory = Blood pressure (high = trouble!)
│   - Disk space = Oxygen level (runs out = death!)
│   - Request rate = Breathing rate
│   - Error rate = Fever (indicates infection/bugs)
│
├── 📝 Logs (EFK Stack) = Patient Medical Records
│   Every event is written down:
│   "10:05 AM — Patient coughed (ERROR: database timeout)"
│   "10:06 AM — Nurse administered medicine (auto-restart)"
│   "10:07 AM — Patient stable (service recovered)"
│   Searchable history = find when problems started
│
├── 🔍 Traces (X-Ray/Jaeger) = Following a blood cell through the body
│   A single user request travels through 10 microservices.
│   Tracing shows: "The request spent 3 seconds stuck in the payment service!"
│   Like tracking a package through every sorting facility.
│
├── 📱 Grafana Dashboard = The TV screen showing all vital signs
│   Beautiful graphs that anyone can read:
│   Green = healthy, Yellow = warning, Red = critical
│   CEO can understand: "95% of users are getting fast responses"
│
└── 🚨 Alerts (AlertManager) = Hospital alarm system
    "If heart rate > 90% for 5 minutes → page the doctor!"
    "If error rate > 5% → send Slack alert to on-call engineer!"
    Escalation: Slack → PagerDuty → Phone call → Wake up manager
```

### The 3 Pillars = Doctor's Complete Picture
```
  🩺 Doctor diagnosing a patient needs ALL THREE:

  1. METRICS:  "Blood pressure is 180/120 (high!)"
               → Know SOMETHING is wrong

  2. LOGS:     "Patient ate 3 pizzas at 9 PM"
               → Know WHAT happened

  3. TRACES:   "Digestive system slowdown started at stomach,
               propagated to intestines, caused blood pressure spike"
               → Know WHERE and WHY it happened

  Without all 3, you're guessing!
```

### Real-World Impact
| Scenario | Without Monitoring | With Monitoring |
|----------|-------------------|------------------|
| Server runs out of disk | App crashes, users see errors | Alert 2 days before: "Disk 80% full" |
| Memory leak | Gradual slowdown over weeks, random crashes | Dashboard shows memory climbing → fix before crash |
| Spike in errors | Users complain on Twitter (too late!) | PagerDuty alerts in 30 seconds |
| "Which service is slow?" | "I don't know, everything looks fine to me" | Trace shows: "Payment API: 4.2s response time" |
| Post-incident review | "What happened?" "No idea" | Full timeline from logs with exact root cause |

---

## The Three Pillars of Observability
| Pillar | Tool | Purpose |
|--------|------|---------|
| **Metrics** | Prometheus + Grafana | Time-series data (CPU, memory, request rate) |
| **Logs** | EFK (Elasticsearch + Fluent Bit + Kibana) | Centralized log aggregation and search |
| **Traces** | AWS X-Ray / Jaeger | Distributed request tracing |

---

## Week 1 — Prometheus & Grafana

### Prometheus Architecture
```
┌─────────────────────────────────────────────────────┐
│                    Prometheus Server                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ Retrieval │  │   TSDB   │  │  HTTP Server      │  │
│  │ (scrape)  │  │ (storage)│  │  (PromQL queries) │  │
│  └─────┬─────┘  └──────────┘  └────────┬──────────┘  │
│        │                               │              │
└────────┼───────────────────────────────┼──────────────┘
         │                               │
    ┌────┴────┐                    ┌─────┴─────┐
    │ Targets │                    │  Grafana  │
    │ /metrics│                    │  AlertMgr │
    └─────────┘                    └───────────┘

Targets:
  - Node Exporter (host metrics)
  - kube-state-metrics (K8s object states)
  - cAdvisor (container metrics)
  - Application /metrics endpoints
```

### Install with Helm (kube-prometheus-stack)
```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (Prometheus + Grafana + AlertManager)
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword="SecureP@ss123" \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ebs-gp3 \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=ebs-gp3 \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi
```

### Custom values.yaml
```yaml
# monitoring-values.yaml
prometheus:
  prometheusSpec:
    retention: 30d
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: "2"
        memory: 4Gi
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

grafana:
  adminPassword: "${GRAFANA_PASSWORD}"
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internal
    hosts:
      - grafana.internal.example.com
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: default
          folder: ''
          type: file
          options:
            path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      node-exporter:
        gnetId: 1860
        revision: 33
        datasource: Prometheus
      kubernetes-cluster:
        gnetId: 6417
        revision: 1
        datasource: Prometheus

alertmanager:
  config:
    route:
      receiver: 'slack-notifications'
      group_by: ['alertname', 'namespace']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
        - match:
            severity: critical
          receiver: 'pagerduty-critical'
    receivers:
      - name: 'slack-notifications'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/xxx'
            channel: '#devops-alerts'
            title: '{{ .CommonAnnotations.summary }}'
            text: '{{ range .Alerts }}*{{ .Labels.alertname }}*: {{ .Annotations.description }}\n{{ end }}'
      - name: 'pagerduty-critical'
        pagerduty_configs:
          - service_key: '<PD_SERVICE_KEY>'
```

### PromQL Examples
```promql
# CPU usage per pod
rate(container_cpu_usage_seconds_total{namespace="production"}[5m])

# Memory usage percentage
(container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100

# HTTP request rate
rate(http_requests_total{job="webapp"}[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Pod restart count
increase(kube_pod_container_status_restarts_total[1h])

# Disk usage
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100
```

### Custom Alerting Rules
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
spec:
  groups:
  - name: application
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High 5xx error rate on {{ $labels.service }}"
        description: "Error rate is {{ $value | humanizePercentage }}"

    - alert: PodCrashLooping
      expr: increase(kube_pod_container_status_restarts_total[1h]) > 5
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"

    - alert: HighMemoryUsage
      expr: (container_memory_working_set_bytes / container_spec_memory_limit_bytes) > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Memory usage > 90% for {{ $labels.pod }}"
```

### ServiceMonitor (Custom App Metrics)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: webapp-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: webapp
  namespaceSelector:
    matchNames: [production]
  endpoints:
  - port: http-metrics
    interval: 15s
    path: /metrics
```

---

## Week 2 — EFK Stack (Centralized Logging)

### Architecture
```
Apps → Fluent Bit (DaemonSet) → Elasticsearch → Kibana
  │         │                         │              │
  │   Collects from                Indexes &      Dashboard
  │   /var/log/containers/         searches        & alerts
  │                                    │
  │                            Amazon OpenSearch
  │                            (managed alternative)
```

### Fluent Bit DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:3.0
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: config
          mountPath: /fluent-bit/etc/
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: config
        configMap:
          name: fluent-bit-config
```

### Fluent Bit Configuration
```ini
# fluent-bit.conf
[SERVICE]
    Flush         5
    Log_Level     info
    Parsers_File  parsers.conf

[INPUT]
    Name              tail
    Tag               kube.*
    Path              /var/log/containers/*.log
    Parser            docker
    Mem_Buf_Limit     5MB
    Skip_Long_Lines   On
    Refresh_Interval  10

[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_Tag_Prefix     kube.var.log.containers.
    Merge_Log           On
    Keep_Log            Off
    K8S-Logging.Parser  On

[FILTER]
    Name    grep
    Match   kube.*
    Exclude log healthcheck

[OUTPUT]
    Name            es
    Match           kube.*
    Host            elasticsearch.logging.svc.cluster.local
    Port            9200
    Index           k8s-logs
    Type            _doc
    Logstash_Format On
    Logstash_Prefix k8s
    Retry_Limit     3
```

### CloudWatch Integration (Alternative)
```yaml
# AWS for Fluent Bit — push to CloudWatch
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: aws-fluent-bit
  namespace: logging
spec:
  template:
    spec:
      containers:
      - name: aws-fluent-bit
        image: public.ecr.aws/aws-observability/aws-for-fluent-bit:latest
        env:
        - name: AWS_REGION
          value: us-east-1
        - name: CLUSTER_NAME
          value: production-cluster
```

---

## Real-Time Project: Full Observability Stack on EKS

### Architecture
```
┌─────────────────── EKS Cluster ───────────────────────┐
│                                                        │
│  ┌─── Monitoring NS ───┐  ┌─── Logging NS ─────────┐ │
│  │ Prometheus           │  │ Fluent Bit (DaemonSet)  │ │
│  │ Grafana              │  │ Elasticsearch / OpenSrch│ │
│  │ AlertManager         │  │ Kibana                  │ │
│  │ kube-state-metrics   │  └─────────────────────────┘ │
│  │ node-exporter        │                              │
│  └──────────────────────┘                              │
│                                                        │
│  ┌─── Production NS ───┐  ┌─── Alerts ─────────────┐ │
│  │ Frontend (React)     │  │ Slack → #devops-alerts  │ │
│  │ Backend (Node.js)    │  │ PagerDuty → on-call     │ │
│  │ Worker (background)  │  │ Email → team@company    │ │
│  └──────────────────────┘  └─────────────────────────┘ │
└────────────────────────────────────────────────────────┘

External:
  → SNS → Lambda → Incident Management
  → CloudWatch Dashboards (executive view)
```

### Grafana Dashboards to Build
| Dashboard | Panels |
|-----------|--------|
| **Cluster Overview** | Node count, CPU/Mem utilization, pod count, namespace breakdown |
| **Application Performance** | Request rate, error rate, latency (RED method) |
| **Node Health** | CPU, memory, disk, network per node |
| **Pod Detail** | Container restarts, OOM kills, resource usage vs limits |
| **Cost Dashboard** | Spot vs on-demand usage, namespace cost allocation |
| **SLA Dashboard** | Uptime %, error budget remaining, SLO compliance |

### Alerting Rules Coverage
| Alert | Condition | Severity |
|-------|-----------|----------|
| High CPU usage | > 80% for 10m | warning |
| High memory usage | > 90% for 5m | warning |
| Pod crash looping | > 5 restarts/hour | critical |
| High 5xx error rate | > 5% for 5m | critical |
| PVC almost full | > 85% | warning |
| Node not ready | Status != Ready for 5m | critical |
| Certificate expiring | < 7 days | warning |

### Deliverables
- [ ] kube-prometheus-stack deployed via Helm
- [ ] Custom Grafana dashboards (cluster, app, node, SLA)
- [ ] PrometheusRules for application-specific alerts
- [ ] AlertManager routing to Slack + PagerDuty
- [ ] Fluent Bit DaemonSet shipping logs to OpenSearch
- [ ] Kibana index patterns and saved searches
- [ ] ServiceMonitor for custom application metrics
- [ ] CloudWatch integration as secondary sink
- [ ] Runbook links in alert annotations
- [ ] On-call escalation policy documented

---

## Complete Monitoring Tools Landscape

### Tool Comparison Matrix
```
┌─────────────────── MONITORING TOOLS UNIVERSE ──────────────────────┐
│                                                                     │
│  ┌─── Open-Source (Self-Hosted) ─────────────────────────────────┐ │
│  │                                                                │ │
│  │  METRICS:                                                      │ │
│  │  ├── Prometheus      → Industry standard, PromQL, pull-based  │ │
│  │  ├── VictoriaMetrics → Prometheus-compatible, better perf     │ │
│  │  ├── Thanos          → Multi-cluster, long-term Prometheus    │ │
│  │  ├── Mimir (Grafana) → Horizontally scalable metrics          │ │
│  │  └── InfluxDB        → Time-series DB, push-based             │ │
│  │                                                                │ │
│  │  LOGS:                                                         │ │
│  │  ├── Loki (Grafana)  → Lightweight, labels-based (like Prom)  │ │
│  │  ├── Elasticsearch   → Full-text search, powerful but heavy   │ │
│  │  ├── Fluent Bit      → Lightweight log forwarder (Go)         │ │
│  │  ├── Fluentd         → Full-featured log aggregator (Ruby)    │ │
│  │  └── Vector          → High-perf observability pipeline (Rust)│ │
│  │                                                                │ │
│  │  TRACES:                                                       │ │
│  │  ├── Jaeger          → Distributed tracing (CNCF)             │ │
│  │  ├── Tempo (Grafana) → Cost-effective, object-storage backend │ │
│  │  └── Zipkin          → Original distributed tracer            │ │
│  │                                                                │ │
│  │  DASHBOARDS:                                                   │ │
│  │  ├── Grafana         → #1 visualization platform              │ │
│  │  └── Kibana          → Elasticsearch companion dashboard      │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─── AWS Native (Managed) ──────────────────────────────────────┐ │
│  │                                                                │ │
│  │  ├── CloudWatch Metrics    → Built-in AWS resource monitoring │ │
│  │  ├── CloudWatch Logs       → Log groups, insights queries     │ │
│  │  ├── CloudWatch Alarms     → Threshold + anomaly detection    │ │
│  │  ├── X-Ray                 → Distributed tracing              │ │
│  │  ├── Amazon Managed Prometheus (AMP) → Managed Prometheus     │ │
│  │  ├── Amazon Managed Grafana (AMG)    → Managed Grafana        │ │
│  │  ├── Amazon OpenSearch     → Managed Elasticsearch/Kibana     │ │
│  │  ├── CloudWatch Container Insights → EKS/ECS metrics         │ │
│  │  └── DevOps Guru          → AI-powered anomaly detection      │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─── SaaS (Commercial) ────────────────────────────────────────┐  │
│  │                                                                │  │
│  │  ├── Datadog      → All-in-one (metrics, logs, traces, APM) │  │
│  │  ├── New Relic    → Full observability (free tier available)  │  │
│  │  ├── Splunk       → Enterprise log analytics                 │  │
│  │  ├── Dynatrace    → AI-powered APM                           │  │
│  │  ├── Grafana Cloud → Managed Grafana + Loki + Tempo          │  │
│  │  └── Honeycomb    → Event-driven observability               │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Which Stack to Choose? (Decision Tree)
```
START → Do you have a Kubernetes cluster?
  │
  ├── YES → Budget for SaaS tools?
  │     ├── YES → Budget > $5K/mo?
  │     │     ├── YES → Datadog (all-in-one, easy)
  │     │     └── NO  → Grafana Cloud (free tier covers small clusters)
  │     └── NO  → Prometheus + Grafana + Loki + Tempo (all free, OSS)
  │               ↑ MOST COMMON DevOps choice!
  │
  └── NO  → Running on AWS only?
        ├── YES → CloudWatch + X-Ray + Container Insights
        │         (zero setup, native integration)
        └── NO  → Prometheus + Grafana (works everywhere)
```

---

## Grafana Loki — Lightweight Log Aggregation

### Why Loki Over Elasticsearch?
| Factor | Elasticsearch (EFK) | Loki (PLG) |
|--------|-------------------|-------------|
| Storage cost | High (indexes everything) | Low (indexes labels only) |
| Resource usage | 8GB+ RAM per node | 512MB enough for small clusters |
| Query language | Lucene/KQL | LogQL (similar to PromQL!) |
| Best for | Full-text search, analytics | DevOps log grep/tail |
| Complexity | High (cluster management) | Low (single binary or Helm) |
| Integration | Kibana | Grafana (same tool for metrics!) |

### Install Loki Stack with Helm
```bash
# Install Loki + Promtail (log shipper)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring --create-namespace \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi \
  --set loki.persistence.storageClassName=ebs-gp3
```

### LogQL Examples (Loki's Query Language)
```logql
# Find all error logs in production namespace
{namespace="production"} |= "error"

# Parse JSON logs and filter by status code
{app="api-service"} | json | status >= 500

# Count errors per minute
count_over_time({namespace="production"} |= "error" [1m])

# Top 5 most common error messages
topk(5, count_over_time({app="api-service"} |= "ERROR" [1h]) by (msg))

# Latency from access logs (value extraction)
{app="nginx"} | regexp `(?P<latency>\d+\.\d+)ms` | latency > 500
```

---

## Grafana Tempo — Distributed Tracing

### Install Tempo
```bash
helm install tempo grafana/tempo \
  --namespace monitoring \
  --set tempo.storage.trace.backend=s3 \
  --set tempo.storage.trace.s3.bucket=my-traces-bucket \
  --set tempo.storage.trace.s3.region=us-east-1
```

### OpenTelemetry Integration (Application Instrumentation)
```python
# app/tracing.py — Auto-instrument a Python Flask app
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

def init_tracing(app):
    """Initialize OpenTelemetry tracing for Flask app."""
    provider = TracerProvider()
    exporter = OTLPSpanExporter(endpoint="http://tempo.monitoring:4317")
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)
    
    FlaskInstrumentor().instrument_app(app)
    RequestsInstrumentor().instrument()
    
    return trace.get_tracer(__name__)
```

---

## AWS CloudWatch — Native Monitoring Deep Dive

### CloudWatch Architecture for Production
```
┌─────────────── CloudWatch Production Setup ───────────────────────┐
│                                                                    │
│  ┌─── Data Sources ───────────┐   ┌─── CloudWatch ────────────┐  │
│  │ EC2 (detailed monitoring)  │──→│ Metrics (custom + AWS)    │  │
│  │ ECS/EKS Container Insights │──→│ Logs (application + infra)│  │
│  │ RDS Enhanced Monitoring    │──→│ Alarms (threshold + ML)   │  │
│  │ ALB Access Logs            │──→│ Dashboards (executive)     │  │
│  │ Lambda (auto-instrumented) │──→│ Insights (log queries)     │  │
│  │ Custom App Metrics         │──→│ Anomaly Detection (ML)    │  │
│  └────────────────────────────┘   └──────────┬────────────────┘  │
│                                               │                   │
│                              ┌────────────────┼────────────────┐  │
│                              │                │                │  │
│                         SNS Topic       Lambda          EventBridge│
│                              │           │                │       │
│                        ┌─────┼─────┐   Auto-          Trigger    │
│                        │     │     │   Remediate      Workflows  │
│                      Email  Slack  PD                             │
│                      SMS   Webhook                                │
└───────────────────────────────────────────────────────────────────┘
```

### CloudWatch Custom Metrics (Application-Level)
```python
# app/metrics.py — Push custom business metrics to CloudWatch
import boto3
from datetime import datetime

cloudwatch = boto3.client('cloudwatch')

def put_business_metric(metric_name, value, unit='Count'):
    """Push custom business metrics to CloudWatch."""
    cloudwatch.put_metric_data(
        Namespace='MyApp/Production',
        MetricData=[{
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Timestamp': datetime.utcnow(),
            'Dimensions': [
                {'Name': 'Environment', 'Value': 'production'},
                {'Name': 'Service', 'Value': 'api-server'},
            ]
        }]
    )

# Usage examples:
put_business_metric('OrdersProcessed', 42)
put_business_metric('PaymentFailures', 3)
put_business_metric('APILatencyP99', 245.6, 'Milliseconds')
put_business_metric('ActiveUsers', 1523)
put_business_metric('QueueDepth', 89)
```

### CloudWatch Logs Insights Queries
```sql
-- Top 10 slowest API requests
fields @timestamp, @message, latency_ms, path
| filter latency_ms > 1000
| sort latency_ms desc
| limit 10

-- Error count by service (last 24h)
fields @timestamp, service, level
| filter level = "ERROR"
| stats count(*) as error_count by service
| sort error_count desc

-- Memory usage trend per container
fields @timestamp, container_name, memory_usage_mb
| filter container_name like /api-/
| stats avg(memory_usage_mb) as avg_mem by bin(5m), container_name

-- Find 5xx errors with request details
fields @timestamp, status_code, method, path, response_time, user_id
| filter status_code >= 500
| sort @timestamp desc
| limit 50
```

### CloudWatch Anomaly Detection Alarm
```yaml
# cloudwatch-anomaly-alarm.yaml (CloudFormation)
Resources:
  CPUAnomalyAlarm:
    Type: AWS::CloudWatch::AnomalyDetector
    Properties:
      MetricName: CPUUtilization
      Namespace: AWS/EC2
      Stat: Average
      Dimensions:
        - Name: InstanceId
          Value: !Ref WebServerInstance

  CPUAnomalyAlarmWatch:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: EC2-CPU-Anomaly-Detection
      AlarmDescription: "CPU usage deviates from learned baseline"
      ComparisonOperator: LessThanLowerOrGreaterThanUpperThreshold
      EvaluationPeriods: 3
      Metrics:
        - Id: cpu
          MetricStat:
            Metric:
              MetricName: CPUUtilization
              Namespace: AWS/EC2
              Dimensions:
                - Name: InstanceId
                  Value: !Ref WebServerInstance
            Period: 300
            Stat: Average
        - Id: anomaly
          Expression: "ANOMALY_DETECTION_BAND(cpu, 2)"
      ThresholdMetricId: anomaly
      AlarmActions:
        - !Ref AlertSNSTopic
```

---

## Real-Time Project: E-Commerce Monitoring Platform

### Scenario: Monitor a Production E-Commerce Application

An e-commerce company runs on EKS with 8 microservices. You are building the complete observability platform.

### Full Architecture Diagram
```
┌─────────────────────── PRODUCTION ENVIRONMENT ──────────────────────────┐
│                                                                          │
│  Users → Route53 → CloudFront (CDN) → ALB → Ingress Controller         │
│                                                │                         │
│  ┌─── EKS Cluster ────────────────────────────┴───────────────────────┐ │
│  │                                                                     │ │
│  │  ┌─── Namespace: e-commerce ─────────────────────────────────────┐ │ │
│  │  │                                                                │ │ │
│  │  │  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐  │ │ │
│  │  │  │ Frontend │ │ API       │ │ Payment  │ │ Notification   │  │ │ │
│  │  │  │ (React)  │ │ Gateway   │ │ Service  │ │ Service        │  │ │ │
│  │  │  │ 3 pods   │ │ 5 pods    │ │ 3 pods   │ │ 2 pods         │  │ │ │
│  │  │  └────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────┬─────────┘  │ │ │
│  │  │       │              │            │               │            │ │ │
│  │  │  ┌────┴─────┐ ┌─────┴─────┐ ┌────┴────┐  ┌──────┴─────────┐  │ │ │
│  │  │  │ Product  │ │ Cart      │ │ Inventory│  │ Search         │  │ │ │
│  │  │  │ Catalog  │ │ Service   │ │ Service  │  │ Service (ES)   │  │ │ │
│  │  │  │ 3 pods   │ │ 3 pods    │ │ 2 pods   │  │ 2 pods         │  │ │ │
│  │  │  └──────────┘ └───────────┘ └─────────┘  └────────────────┘  │ │ │
│  │  │                                                                │ │ │
│  │  │  DATA LAYER:                                                   │ │ │
│  │  │  RDS PostgreSQL (Multi-AZ) │ ElastiCache Redis │ SQS Queues  │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                     │ │
│  │  ┌─── Namespace: monitoring ─────────────────────────────────────┐ │ │
│  │  │                                                                │ │ │
│  │  │  Prometheus  │ Grafana   │ AlertManager │ Loki │ Tempo        │ │ │
│  │  │  (metrics)   │ (dashbd)  │ (alerts)     │(logs)│ (traces)     │ │ │
│  │  │                                                                │ │ │
│  │  │  kube-state-metrics │ node-exporter │ Promtail (DaemonSet)   │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌─── AWS Native Monitoring ────────────────────────────────────────┐   │
│  │  CloudWatch Container Insights │ X-Ray (tracing) │ CloudWatch    │   │
│  │  RDS Performance Insights      │ DevOps Guru      │ Dashboards   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌─── Alerting & Incident Response ─────────────────────────────────┐   │
│  │  AlertManager → Slack #ecom-alerts (warning) + PagerDuty (crit) │   │
│  │  CloudWatch Alarms → SNS → Lambda (auto-remediation)             │   │
│  │  Statuspage.io → Customer-facing status                          │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Step 1: Deploy Full PLG Stack (Prometheus + Loki + Grafana + Tempo)
```bash
#!/bin/bash
# deploy-observability.sh — One-click monitoring setup

# Create namespace
kubectl create namespace monitoring

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 1. Prometheus + Grafana + AlertManager
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring-values.yaml

# 2. Loki (log aggregation) + Promtail (log shipping)
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi \
  --set promtail.enabled=true \
  --set grafana.enabled=false  # We already have Grafana from step 1

# 3. Tempo (distributed tracing)
helm install tempo grafana/tempo \
  --namespace monitoring \
  --set tempo.storage.trace.backend=local

# 4. Add Loki + Tempo as data sources in Grafana
kubectl apply -f grafana-datasources.yaml

echo "✅ Full observability stack deployed!"
echo "📊 Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "🔍 Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
```

### Step 2: Application Instrumentation
```javascript
// app/metrics-middleware.js — Express.js metrics middleware
const prometheus = require('prom-client');

// Collect default Node.js metrics
prometheus.collectDefaultMetrics({ prefix: 'ecom_' });

// Custom business metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'ecom_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});

const ordersTotal = new prometheus.Counter({
  name: 'ecom_orders_total',
  help: 'Total number of orders placed',
  labelNames: ['status', 'payment_method'],
});

const cartValue = new prometheus.Histogram({
  name: 'ecom_cart_value_dollars',
  help: 'Shopping cart value in dollars at checkout',
  buckets: [10, 25, 50, 100, 250, 500, 1000],
});

const activeUsers = new prometheus.Gauge({
  name: 'ecom_active_users',
  help: 'Number of currently active users',
});

// Middleware
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.observe(
      { method: req.method, route: req.route?.path || req.path, status_code: res.statusCode },
      duration
    );
  });
  next();
}

// Metrics endpoint
function metricsEndpoint(req, res) {
  res.set('Content-Type', prometheus.register.contentType);
  prometheus.register.metrics().then(data => res.send(data));
}

module.exports = { metricsMiddleware, metricsEndpoint, ordersTotal, cartValue, activeUsers };
```

### Step 3: RED Method Dashboards (Rate, Errors, Duration)
```
  ┌──────────────────── E-Commerce RED Dashboard ────────────────────┐
  │                                                                   │
  │  📈 RATE (Requests per second)                                    │
  │  ┌─────────────────────────────────────────────┐                 │
  │  │  Total RPS ████████████████░░░  156.3 req/s │                 │
  │  │  Peak Today ████████████████████ 312.1 req/s│                 │
  │  │  Orders/min ██████░░░░░░░░░░░░░  23.4/min   │                 │
  │  └─────────────────────────────────────────────┘                 │
  │                                                                   │
  │  ❌ ERRORS (Error rate %)                                         │
  │  ┌─────────────────────────────────────────────┐                 │
  │  │  5xx Rate   ▓░░░░░░░░░░░░░░░░░░  0.12% ✅   │                 │
  │  │  4xx Rate   ████░░░░░░░░░░░░░░░  2.3%       │                 │
  │  │  Payment    ▓▓░░░░░░░░░░░░░░░░░  0.8%  ⚠️   │                 │
  │  └─────────────────────────────────────────────┘                 │
  │                                                                   │
  │  ⏱️ DURATION (Latency percentiles)                                │
  │  ┌─────────────────────────────────────────────┐                 │
  │  │  P50  ██░░░░░░░░░░░░░░░░░░░  45ms           │                 │
  │  │  P90  ████████░░░░░░░░░░░░░  189ms          │                 │
  │  │  P99  ████████████████░░░░░  423ms ✅ (<500) │                 │
  │  └─────────────────────────────────────────────┘                 │
  │                                                                   │
  │  💰 BUSINESS METRICS                                              │
  │  ┌─────────────────────────────────────────────┐                 │
  │  │  Revenue/hour  $12,340 (+15% vs yesterday)  │                 │
  │  │  Cart abandon  22.3% (normal range)         │                 │
  │  │  Search latency P99  67ms ✅                 │                 │
  │  └─────────────────────────────────────────────┘                 │
  └───────────────────────────────────────────────────────────────────┘
```

### Step 4: Complete Alerting Rules for E-Commerce
```yaml
# ecommerce-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ecommerce-alerts
  namespace: monitoring
spec:
  groups:
  - name: ecommerce.slo
    rules:
    - alert: HighErrorRate
      expr: |
        sum(rate(ecom_http_request_duration_seconds_count{status_code=~"5.."}[5m]))
        / sum(rate(ecom_http_request_duration_seconds_count[5m])) > 0.01
      for: 3m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "E-Commerce 5xx error rate > 1%"
        runbook: "https://wiki.internal/runbooks/high-error-rate"

    - alert: HighLatencyP99
      expr: |
        histogram_quantile(0.99, sum(rate(ecom_http_request_duration_seconds_bucket[5m])) by (le))
        > 0.5
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "API P99 latency > 500ms"

  - name: ecommerce.business
    rules:
    - alert: OrderDropoff
      expr: |
        sum(rate(ecom_orders_total[30m]))
        < sum(rate(ecom_orders_total[30m] offset 1d)) * 0.5
      for: 15m
      labels:
        severity: critical
        team: business
      annotations:
        summary: "Order rate dropped >50% compared to yesterday"
        description: "Possible payment gateway issue or site degradation"

    - alert: PaymentFailureSpike
      expr: |
        sum(rate(ecom_orders_total{status="failed"}[5m]))
        / sum(rate(ecom_orders_total[5m])) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Payment failure rate > 5%"
        runbook: "https://wiki.internal/runbooks/payment-failures"

    - alert: CartAbandonmentHigh
      expr: ecom_cart_abandonment_rate > 0.40
      for: 30m
      labels:
        severity: warning
        team: product
      annotations:
        summary: "Cart abandonment rate > 40% (normally ~25%)"
```

### Project Deliverables
- [ ] Full PLG stack (Prometheus + Loki + Grafana + Tempo) on EKS
- [ ] Application instrumented with custom Prometheus metrics
- [ ] RED method dashboards for all 8 microservices
- [ ] Business metrics dashboard (orders, revenue, cart abandonment)
- [ ] SLO compliance dashboard with error budget burn rate
- [ ] 15+ alerting rules (infrastructure + application + business)
- [ ] AlertManager routing: Slack (warning) + PagerDuty (critical)
- [ ] CloudWatch integration as secondary monitoring layer
- [ ] CloudWatch Logs Insights queries for ad-hoc troubleshooting
- [ ] OpenTelemetry tracing across all microservices
- [ ] Grafana datasources: Prometheus + Loki + Tempo + CloudWatch
- [ ] On-call runbooks linked from every alert annotation
- [ ] Load test with k6 to validate dashboard accuracy
- [ ] Executive dashboard for non-technical stakeholders
