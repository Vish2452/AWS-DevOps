# Route 53 — DNS & Domain Management

> AWS-managed DNS service. Route traffic globally with health checks, failover, and intelligent routing. The "GPS navigator" of the internet.

---

## Real-World Analogy

Route 53 is like the **contact directory on your phone**:
- You type "Mom" → phone knows the actual number is +1-555-123-4567
- Route 53 translates `www.myapp.com` → `54.23.1.100` (IP address)
- **Routing policies** are like choosing the best route on Google Maps:
  - **Latency-based** = "Take the fastest route"
  - **Failover** = "If highway is blocked, take the back road automatically"
  - **Weighted** = "Send 80% of traffic through highway, 20% through side road"
  - **Geolocation** = "Indian users go to India office, US users go to US office"

---

## Record Types

| Type | Purpose | Example | When to Use |
|------|---------|---------|-------------|
| **A** | IPv4 address | `app.example.com → 1.2.3.4` | Point to EC2, ALB |
| **AAAA** | IPv6 address | `app.example.com → 2001:db8::1` | IPv6-enabled resources |
| **CNAME** | Alias to another domain | `www → app.example.com` | Point subdomain to another domain |
| **ALIAS** | AWS-specific alias | `example.com → ALB/CloudFront` | Zone apex (root domain), free queries |
| **MX** | Mail server | `mail.example.com → priority 10` | Email configuration |
| **TXT** | Text records | `v=spf1 include:_spf.google.com` | SPF, DKIM, domain verification |
| **NS** | Name server | Delegates DNS zone | Subdomain delegation |
| **SOA** | Start of Authority | Zone metadata | Auto-created with hosted zone |

### CNAME vs ALIAS — Important Difference
```
CNAME:
- Cannot be used at zone apex (example.com) ❌
- Can point to ANY domain
- DNS query charges apply
- Example: www.myapp.com → myapp-123.us-east-1.elb.amazonaws.com

ALIAS:
- CAN be used at zone apex (example.com) ✅
- Only points to AWS resources (ALB, CloudFront, S3, etc.)
- FREE DNS queries for AWS resources
- Example: myapp.com → d123456.cloudfront.net
```

---

## Routing Policies — Deep Dive

| Policy | Use Case | Real-World Example |
|--------|----------|-------------------|
| **Simple** | Single resource | Small blog → one EC2 instance |
| **Weighted** | A/B testing, gradual migration | Send 10% traffic to new version, 90% to old |
| **Latency** | Route to lowest-latency region | User in London → EU-West-1, user in Tokyo → AP-Northeast-1 |
| **Failover** | Active-passive DR | Primary in US-East-1, secondary in EU-West-1 |
| **Geolocation** | Route by user location | Comply with GDPR: European users → EU servers |
| **Geoproximity** | Route by geographic distance + bias | Steer more traffic to specific region |
| **Multi-value** | Return multiple healthy IPs | Simple load balancing across 8 IP addresses |
| **IP-based** | Route by client IP range | Corporate users → internal servers, others → public |

---

## Real-Time Example 1: Blue-Green Deployment with Weighted Routing

**Scenario:** You're deploying a new version of your app. Instead of switching all users at once, gradually shift traffic.

```
Week 1:  v1 (blue) = 100%   v2 (green) = 0%     ← New version deployed but no traffic
Week 2:  v1 (blue) = 90%    v2 (green) = 10%     ← 10% canary traffic
Week 3:  v1 (blue) = 50%    v2 (green) = 50%     ← 50/50 split, monitoring metrics
Week 4:  v1 (blue) = 0%     v2 (green) = 100%    ← Full cutover, v1 decommissioned
```

```bash
# Create weighted records
# v1 (blue) — 90% of traffic
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "blue",
                "Weight": 90,
                "AliasTarget": {
                    "HostedZoneId": "ALB_ZONE_ID",
                    "DNSName": "blue-alb.us-east-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'

# v2 (green) — 10% of traffic
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "green",
                "Weight": 10,
                "AliasTarget": {
                    "HostedZoneId": "ALB_ZONE_ID",
                    "DNSName": "green-alb.us-east-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'
```

**Explanation:** This is how Netflix, Amazon, and large companies deploy safely. If the new version has bugs, only 10% of users are affected. Monitor error rates, latency, and user feedback before increasing traffic.

---

## Real-Time Example 2: Disaster Recovery with Failover Routing

**Scenario:** Your primary app runs in US-East-1. If that region goes down (rare but happens!), automatically route to EU-West-1.

```
Normal operation:
User → Route53 → Health Check ✅ → US-East-1 (primary ALB)

During US-East-1 outage:
User → Route53 → Health Check ❌ → EU-West-1 (failover ALB)
```

```bash
# Create health check for primary
HEALTH_CHECK_ID=$(aws route53 create-health-check \
    --caller-reference $(date +%s) \
    --health-check-config '{
        "Type": "HTTPS",
        "FullyQualifiedDomainName": "primary-alb.us-east-1.elb.amazonaws.com",
        "Port": 443,
        "ResourcePath": "/health",
        "RequestInterval": 10,
        "FailureThreshold": 3
    }' --query 'HealthCheck.Id' --output text)

# Primary record (failover = PRIMARY)
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "primary",
                "Failover": "PRIMARY",
                "HealthCheckId": "'$HEALTH_CHECK_ID'",
                "AliasTarget": {
                    "HostedZoneId": "ALB_ZONE_ID",
                    "DNSName": "primary-alb.us-east-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'

# Secondary record (failover = SECONDARY)
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "secondary",
                "Failover": "SECONDARY",
                "AliasTarget": {
                    "HostedZoneId": "EU_ALB_ZONE_ID",
                    "DNSName": "dr-alb.eu-west-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'
```

**Explanation:** Route 53 health checks ping your primary every 10 seconds. If 3 consecutive checks fail (30 seconds), it automatically routes all traffic to the DR site. Users may not even notice the outage.

---

## Real-Time Example 3: Geolocation Routing for Compliance

**Scenario:** GDPR requires European user data to stay in Europe. Indian users should hit servers in Mumbai for best performance.

```
European user → Route53 (detects EU location) → EU-West-1 servers (GDPR compliant)
Indian user   → Route53 (detects IN location) → AP-South-1 servers (low latency)
US user       → Route53 (detects US location) → US-East-1 servers
Others        → Route53 (default)             → US-East-1 servers
```

```bash
# European users → EU servers
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "europe",
                "GeoLocation": {"ContinentCode": "EU"},
                "AliasTarget": {
                    "HostedZoneId": "EU_ALB_ZONE",
                    "DNSName": "eu-alb.eu-west-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'

# Indian users → Mumbai servers
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "SetIdentifier": "india",
                "GeoLocation": {"CountryCode": "IN"},
                "AliasTarget": {
                    "HostedZoneId": "IN_ALB_ZONE",
                    "DNSName": "in-alb.ap-south-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'
```

---

## Labs

### Lab 1: Create Hosted Zone and DNS Record
```bash
# Create hosted zone
ZONE_ID=$(aws route53 create-hosted-zone --name example.com \
    --caller-reference $(date +%s) \
    --query 'HostedZone.Id' --output text)

# Create A record pointing to ALB
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "app.example.com",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "ALB_ZONE_ID",
                    "DNSName": "prod-alb-1234.us-east-1.elb.amazonaws.com",
                    "EvaluateTargetHealth": true
                }
            }
        }]
    }'
```

### Lab 2: Create Health Check with Alarm
```bash
# Create health check
HEALTH_ID=$(aws route53 create-health-check --caller-reference $(date +%s) \
    --health-check-config '{
        "IPAddress": "1.2.3.4",
        "Port": 443,
        "Type": "HTTPS",
        "ResourcePath": "/health",
        "FullyQualifiedDomainName": "app.example.com",
        "RequestInterval": 30,
        "FailureThreshold": 3
    }' --query 'HealthCheck.Id' --output text)

# Create CloudWatch alarm for health check failure
aws cloudwatch put-metric-alarm --alarm-name "Route53-HealthCheck-Failed" \
    --namespace "AWS/Route53" \
    --metric-name "HealthCheckStatus" \
    --dimensions Name=HealthCheckId,Value=$HEALTH_ID \
    --statistic Minimum --period 60 --threshold 1 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCT:alerts
```

### Lab 3: Domain Registration and SSL
```bash
# Register a domain (costs real money!)
aws route53domains register-domain \
    --domain-name mydevopsapp.com \
    --duration-in-years 1 \
    --admin-contact '{...}' \
    --registrant-contact '{...}' \
    --tech-contact '{...}'

# Request SSL certificate
aws acm request-certificate \
    --domain-name "mydevopsapp.com" \
    --subject-alternative-names "*.mydevopsapp.com" \
    --validation-method DNS
```

---

## Interview Questions

1. **What is Route 53 and why is it named "Route 53"?**
   > Route 53 is AWS's managed DNS service. Port 53 is the standard DNS port. It provides domain registration, DNS routing, and health checking.

2. **What is the difference between CNAME and ALIAS records?**
   > CNAME cannot be used at zone apex (naked domain), costs per query, works with any domain. ALIAS works at zone apex, is free for AWS resources, but only points to AWS services (ALB, CloudFront, S3, etc.).

3. **Explain latency-based routing with a real example.**
   > App deployed in US-East-1 and EU-West-1. Route 53 measures latency from the user's DNS resolver to each region. A user in London gets routed to EU-West-1 (50ms) instead of US-East-1 (150ms).

4. **How would you implement disaster recovery using Route 53?**
   > Failover routing with health checks. Primary record points to US-East-1 with health check. Secondary points to DR site in EU-West-1. If health check fails (3 consecutive failures), Route 53 auto-routes to DR. RTO can be under 60 seconds.

5. **What is the difference between Geolocation and Latency-based routing?**
   > Geolocation routes based on the user's physical location (for compliance like GDPR). Latency routes to the fastest region. A user in Germany might have lower latency to US-East-1 than EU-West-1, but GDPR requires geolocation routing to EU.

6. **How do Route 53 health checks work?**
   > Route 53 sends requests to your endpoint from multiple locations worldwide every 10 or 30 seconds. If the endpoint fails FailureThreshold consecutive checks, it's marked unhealthy and routing changes. You can check HTTP status codes and response body content.

7. **How would you do a blue-green deployment with Route 53?**
   > Use weighted routing. Start with blue=100%, green=0%. Gradually shift: 90/10 → 50/50 → 0/100. Monitor errors at each stage. If issues, quickly set green=0%, blue=100% to rollback.

8. **Can Route 53 be used as a load balancer?**
   > Route 53 provides DNS-level load balancing (weighted, multi-value, latency). But it's NOT a replacement for ELB. DNS has TTL caching, so changes take time to propagate. ELB provides real-time, health-check-based load balancing. Use both together.
