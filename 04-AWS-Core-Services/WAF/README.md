# WAF — Web Application Firewall

> Protect web applications from common exploits (SQL injection, XSS, DDoS). Works with CloudFront, ALB, API Gateway, and AppSync.

---

## Real-World Analogy

WAF is like a **nightclub bouncer**:
- Checks everyone at the door (every HTTP request)
- Has a list of banned people (IP blocklist)
- Checks for fake IDs (SQL injection, XSS patterns)
- Limits how many people enter per minute (rate limiting)
- VIP list gets in automatically (IP allowlist)
- Can use external threat intelligence (managed rule groups)

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Web ACL** | Collection of rules applied to resources | "Block SQLi, rate limit, geo-block" |
| **Rule** | Condition + action (Allow/Block/Count) | "Block if request contains SQL patterns" |
| **Rule Group** | Reusable set of rules | AWS Managed: `AWSManagedRulesCommonRuleSet` |
| **IP Set** | List of IP addresses | Blocklist of known malicious IPs |
| **Rate-based Rule** | Block IPs exceeding threshold | "Block if >2000 requests in 5 minutes" |
| **Managed Rules** | Pre-built by AWS or marketplace | OWASP Top 10, Bot control, IP reputation |
| **Custom Rules** | Write your own matching logic | "Block requests from country X to /admin" |

---

## Real-Time Example 1: Protect E-Commerce Website

**Scenario:** Your e-commerce site faces SQL injection attempts, brute-force login attacks, and bot traffic. Set up comprehensive WAF protection.

```
Internet Traffic
       │
┌──────▼──────────────────────────────────────────────┐
│                    AWS WAF                           │
│                                                      │
│  Rule 1: AWS Managed - Common Rules (SQLi, XSS)    │
│  Rule 2: AWS Managed - IP Reputation (known bad)    │
│  Rule 3: Rate Limit /login to 100 req/5min per IP  │
│  Rule 4: Block countries not in target market       │
│  Rule 5: Custom - Block requests with no User-Agent│
│  Rule 6: Bot Control (block scrapers)               │
│                                                      │
│  Action per rule: BLOCK / ALLOW / COUNT             │
└──────┬──────────────────────────────────────────────┘
       │
       ▼ (Clean traffic only)
   CloudFront / ALB
       │
       ▼
   Application
```

```bash
# Create IP set for blocklist
IP_SET_ID=$(aws wafv2 create-ip-set --name "Blocklist" \
    --scope REGIONAL --ip-address-version IPV4 \
    --addresses "198.51.100.0/24" "203.0.113.50/32" \
    --query 'Summary.Id' --output text)

# Create Web ACL with managed + custom rules
aws wafv2 create-web-acl --name "ecommerce-protection" \
    --scope REGIONAL \
    --default-action '{"Allow": {}}' \
    --rules '[
        {
            "Name": "AWSCommonRules",
            "Priority": 1,
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesCommonRuleSet"
                }
            },
            "OverrideAction": {"None": {}},
            "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "CommonRules"}
        },
        {
            "Name": "AWSIPReputation",
            "Priority": 2,
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesAmazonIpReputationList"
                }
            },
            "OverrideAction": {"None": {}},
            "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "IPReputation"}
        },
        {
            "Name": "RateLimitLogin",
            "Priority": 3,
            "Statement": {
                "RateBasedStatement": {
                    "Limit": 100,
                    "AggregateKeyType": "IP",
                    "ScopeDownStatement": {
                        "ByteMatchStatement": {
                            "SearchString": "/login",
                            "FieldToMatch": {"UriPath": {}},
                            "TextTransformations": [{"Priority": 0, "Type": "LOWERCASE"}],
                            "PositionalConstraint": "STARTS_WITH"
                        }
                    }
                }
            },
            "Action": {"Block": {}},
            "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "LoginRateLimit"}
        },
        {
            "Name": "BlockBadIPs",
            "Priority": 4,
            "Statement": {
                "IPSetReferenceStatement": {"ARN": "arn:aws:wafv2:us-east-1:ACCT:regional/ipset/Blocklist/'$IP_SET_ID'"}
            },
            "Action": {"Block": {}},
            "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "BlockedIPs"}
        }
    ]' \
    --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=ecommerce-waf

# Associate with ALB
aws wafv2 associate-web-acl \
    --web-acl-arn arn:aws:wafv2:us-east-1:ACCT:regional/webacl/ecommerce-protection/xxx \
    --resource-arn arn:aws:elasticloadbalancing:us-east-1:ACCT:loadbalancer/app/my-alb/xxx
```

---

## Real-Time Example 2: Geo-Blocking + Rate Limiting

**Scenario:** Your SaaS app only serves US, UK, and India. Block all other countries and rate limit to prevent abuse.

```bash
# Geo-match rule: Block non-target countries
# Rate limit: Max 2000 requests per 5 minutes per IP

# This is configured within the Web ACL rules:
# Rule: GeoBlock
# Statement: NOT GeoMatch(US, GB, IN) → BLOCK

# Rule: GlobalRateLimit  
# Statement: RateBasedRule, Limit=2000, AggregateByIP → BLOCK
```

---

## AWS Shield Integration

| Feature | Shield Standard | Shield Advanced |
|---------|----------------|-----------------|
| **Cost** | Free (automatic) | $3,000/month + data transfer |
| **Protection** | Layer 3/4 DDoS | Layer 3/4/7 DDoS |
| **Response team** | No | 24/7 DDoS Response Team |
| **Cost protection** | No | Yes (credits for scaling costs during attack) |
| **WAF included** | No | Yes (WAF fees included) |

---

## Labs

### Lab 1: Create Basic WAF
```bash
# Quick protection with managed rules
aws wafv2 create-web-acl --name "basic-protection" \
    --scope REGIONAL --default-action '{"Allow": {}}' \
    --rules '[{
        "Name": "OWASP",
        "Priority": 1,
        "Statement": {
            "ManagedRuleGroupStatement": {
                "VendorName": "AWS",
                "Name": "AWSManagedRulesCommonRuleSet"
            }
        },
        "OverrideAction": {"None": {}},
        "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "OWASP"}
    }]' \
    --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=basic-waf
```

### Lab 2: Monitor WAF Metrics
```bash
# Check blocked requests
aws cloudwatch get-metric-statistics --namespace AWS/WAFV2 \
    --metric-name BlockedRequests --dimensions Name=WebACL,Value=ecommerce-protection \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 --statistics Sum

# Get sampled requests
aws wafv2 get-sampled-requests --web-acl-arn $WEB_ACL_ARN \
    --rule-metric-name CommonRules --scope REGIONAL \
    --time-window StartTime=$(date -u -d '1 hour ago' +%s),EndTime=$(date -u +%s) \
    --max-items 100
```

---

## Interview Questions

1. **What is AWS WAF and what attacks does it protect against?**
   > WAF is a web application firewall inspecting HTTP/HTTPS requests. Protects against: SQL injection, cross-site scripting (XSS), HTTP floods, bot traffic, IP reputation threats, and custom patterns. Works at Layer 7 with CloudFront, ALB, API Gateway.

2. **What are managed rule groups?**
   > Pre-built rule sets maintained by AWS or third-party vendors. AWS provides: Common Rules (OWASP Top 10), IP Reputation, Bot Control, SQLi/XSS detection, Known Bad Inputs. They're regularly updated with new threat patterns. You can override individual rules within managed groups.

3. **How does rate-based rule work?**
   > Counts requests from each source IP over a 5-minute window. If an IP exceeds the threshold (minimum: 100), it's blocked for the remainder of the window. Can scope down to specific URLs (e.g., only rate limit /login). Used to prevent brute force, web scraping, and DDoS.

4. **WAF vs Shield vs NACLs — what's the difference?**
   > **WAF:** Layer 7, inspects HTTP content (SQLi, XSS, bot). **Shield:** DDoS protection, Layer 3/4 (network floods). **NACLs:** Layer 3/4, simple IP/port rules at subnet level. Use all three together: NACLs for network-level blocking, Shield for volumetric DDoS, WAF for application-layer attacks.

5. **How to handle false positives?**
   > Start with rules in COUNT mode (log but don't block). Analyze sampled requests for false positives. Move confirmed rules to BLOCK mode. For managed rules, override specific rules within the group to COUNT. Use label-based rules for fine-grained control.

6. **How to block specific countries?**
   > Use geo-match condition in a WAF rule. Can block or allow by country code. Combine with other conditions: "Block requests from X country to /admin but allow /api." Works with CloudFront for global enforcement or ALB for regional.
