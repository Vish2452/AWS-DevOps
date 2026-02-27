# Route 53 — DNS & Domain Management

> AWS-managed DNS service. Route traffic globally with health checks and failover.

## Record Types
| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | `app.example.com → 1.2.3.4` |
| **AAAA** | IPv6 address | `app.example.com → 2001:db8::1` |
| **CNAME** | Alias to another domain | `www → app.example.com` |
| **ALIAS** | AWS-specific alias (works at zone apex) | `example.com → ALB/CloudFront` |
| **MX** | Mail server | `mail.example.com` |
| **TXT** | Text records (SPF, DKIM) | Verification |

## Routing Policies
| Policy | Use Case |
|--------|----------|
| **Simple** | Single resource |
| **Weighted** | A/B testing (80%/20% split) |
| **Latency** | Route to lowest-latency region |
| **Failover** | Active-passive DR (primary + secondary) |
| **Geolocation** | Route by user location (compliance) |
| **Multi-value** | Return multiple healthy IPs |

## Labs
```bash
# Create hosted zone
aws route53 create-hosted-zone --name example.com --caller-reference $(date +%s)

# Create A record pointing to ALB
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
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

# Create health check
aws route53 create-health-check --caller-reference $(date +%s) \
    --health-check-config '{
        "IPAddress": "1.2.3.4",
        "Port": 443,
        "Type": "HTTPS",
        "ResourcePath": "/health",
        "FullyQualifiedDomainName": "app.example.com",
        "RequestInterval": 30,
        "FailureThreshold": 3
    }'
```
