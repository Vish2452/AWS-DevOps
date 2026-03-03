# ELB — Elastic Load Balancing

> Distribute traffic across targets. Choose the right load balancer for your application. The "traffic cop" of AWS.

---

## Real-World Analogy

ELB is like a **hotel reception desk**:
- 100 guests arrive → receptionist distributes them to available rooms
- If Room 301 has a broken AC (unhealthy), NO guests sent there until fixed
- **ALB:** "Are you here for conference? → Floor 3. Spa? → Floor 5" (content-based routing)
- **NLB:** "Here's your key card" → ultra-fast check-in, no questions asked
- **Sticky sessions:** "You want the same room as last time? Here you go" (cookie-based)

---

## Load Balancer Types

| Type | Layer | Protocol | Performance | Use Case | Real-World Example |
|------|-------|----------|-------------|----------|-------------------|
| **ALB** | 7 (Application) | HTTP/HTTPS/gRPC | Millions req/s | Web apps, microservices | Netflix routing `/api/` to backend, `/static/` to S3 |
| **NLB** | 4 (Transport) | TCP/UDP/TLS | 100M+ req/s, <100μs | Ultra-low latency | Gaming servers, trading platforms, IoT |
| **GLB** | 3 (Gateway) | IP | High | Firewall appliances | Route all traffic through Palo Alto firewall |

---

## ALB Features — Deep Dive

| Feature | Description | Real-World Example |
|---------|-------------|-------------------|
| **Path-based routing** | Route by URL path | `/api/*` → backend API servers, `/images/*` → S3 via Lambda |
| **Host-based routing** | Route by hostname | `api.app.com` → API service, `web.app.com` → frontend |
| **Header-based routing** | Route by HTTP headers | `X-Custom-Header: mobile` → mobile backend |
| **Query string routing** | Route by query params | `?platform=ios` → iOS API handler |
| **Target groups** | EC2, IP, Lambda | Microservice A → target group A, Service B → group B |
| **Health checks** | HTTP/HTTPS status code + path | `/health` endpoint returns 200 → instance is healthy |
| **SSL/TLS termination** | ACM certificates | Free SSL certificates, managed auto-renewal |
| **Sticky sessions** | Cookie-based affinity | User always sent to same server (stateful apps) |
| **Cross-zone** | Balance across AZs evenly | 2 instances in AZ-A + 4 in AZ-B → traffic split evenly |
| **WAF integration** | Block attacks at ALB level | Block SQL injection, rate limit per IP |
| **Authentication** | OIDC/Cognito at ALB | Users login via Google/Okta before reaching your app |

---

## Real-Time Example 1: Microservices Routing

**Scenario:** You have 4 microservices. One ALB routes to all of them based on URL path.

```
ALB: api.myapp.com
│
├── /users/*     → Target Group: user-service (3 instances)
├── /products/*  → Target Group: product-service (5 instances)
├── /orders/*    → Target Group: order-service (3 instances)
├── /payments/*  → Target Group: payment-service (2 instances)
└── /*           → Target Group: frontend (4 instances)
```

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name api-gateway-alb \
    --type application \
    --subnets subnet-pub-1 subnet-pub-2 \
    --security-groups sg-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create target groups for each microservice
for svc in user product order payment; do
    aws elbv2 create-target-group \
        --name ${svc}-service-tg \
        --protocol HTTP --port 8080 \
        --vpc-id vpc-xxxx \
        --health-check-path /health \
        --health-check-interval-seconds 15 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 3
done

# Create HTTPS listener
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $ALB_ARN \
    --protocol HTTPS --port 443 \
    --certificates CertificateArn=$CERT_ARN \
    --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN \
    --query 'Listeners[0].ListenerArn' --output text)

# Add path-based routing rules
aws elbv2 create-rule --listener-arn $LISTENER_ARN \
    --priority 10 \
    --conditions Field=path-pattern,Values='/users/*' \
    --actions Type=forward,TargetGroupArn=$USER_TG_ARN

aws elbv2 create-rule --listener-arn $LISTENER_ARN \
    --priority 20 \
    --conditions Field=path-pattern,Values='/products/*' \
    --actions Type=forward,TargetGroupArn=$PRODUCT_TG_ARN
```

**Why this matters:** Without ALB, you'd need a separate load balancer (and separate DNS) for each service. ALB consolidates everything behind one URL, reducing costs and complexity.

---

## Real-Time Example 2: Blue-Green Deployment with ALB

**Scenario:** Deploy v2.0 safely. Run both versions, gradually shift traffic.

```
Phase 1 (Current):
ALB → Target Group Blue (v1.0) → 5 instances [100% traffic]

Phase 2 (Deploy):
ALB → Target Group Blue (v1.0) → 5 instances [90% traffic]
    → Target Group Green (v2.0) → 2 instances [10% traffic]

Phase 3 (Shift):
ALB → Target Group Green (v2.0) → 5 instances [100% traffic]
    → Target Group Blue (v1.0) → 0 instances [decommission]
```

```bash
# Weighted target group routing (90/10 split)
aws elbv2 modify-rule --rule-arn $RULE_ARN \
    --actions '[
        {
            "Type": "forward",
            "ForwardConfig": {
                "TargetGroups": [
                    {"TargetGroupArn": "'$BLUE_TG_ARN'", "Weight": 90},
                    {"TargetGroupArn": "'$GREEN_TG_ARN'", "Weight": 10}
                ],
                "TargetGroupStickinessConfig": {
                    "Enabled": true,
                    "DurationSeconds": 3600
                }
            }
        }
    ]'
```

---

## Real-Time Example 3: NLB for Gaming/Real-Time Applications

**Scenario:** You're building a multiplayer game. Players need ultra-low latency (<1ms) connections via TCP.

```
Players worldwide → NLB (static IP per AZ) → Game servers
                    │
                    ├── Uses TCP passthrough (preserves player's source IP)
                    ├── Handles millions of concurrent connections
                    ├── Static IP: Players can add to firewall allowlist
                    └── Health checks: UDP ping every 10 seconds
```

```bash
# Create NLB with Elastic IPs
NLB_ARN=$(aws elbv2 create-load-balancer \
    --name game-nlb \
    --type network \
    --subnet-mappings SubnetId=subnet-1,AllocationId=eipalloc-xxxx \
                      SubnetId=subnet-2,AllocationId=eipalloc-yyyy \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create TCP target group
aws elbv2 create-target-group \
    --name game-servers \
    --protocol TCP --port 7777 \
    --vpc-id vpc-xxxx \
    --health-check-protocol TCP \
    --health-check-interval-seconds 10

# Create TCP listener
aws elbv2 create-listener --load-balancer-arn $NLB_ARN \
    --protocol TCP --port 7777 \
    --default-actions Type=forward,TargetGroupArn=$GAME_TG_ARN
```

---

## ALB vs NLB Decision Matrix

| Scenario | Choose | Why |
|----------|--------|-----|
| REST API / Web App | ALB | Path/host routing, HTTP features |
| WebSocket | ALB or NLB | ALB supports WebSocket natively |
| gRPC | ALB | HTTP/2 support |
| Static IP required | NLB | ALB IPs change, NLB has static IPs |
| VPN/gaming | NLB | TCP/UDP passthrough, ultra-low latency |
| Lambda backend | ALB | Direct Lambda integration |
| AWS PrivateLink | NLB | Only NLB supports PrivateLink |
| Third-party firewall | GLB | Transparent network appliance insertion |

---

## Health Check Configuration

```
Health Check Flow:
ALB sends GET /health every 15 seconds
    │
    ├── Response 200 → Healthy ✅ (2 consecutive = healthy)
    ├── Response 500 → Unhealthy ❌ (3 consecutive = remove from rotation)
    └── Timeout → Unhealthy ❌
    
Unhealthy instance:
    → ALB stops sending traffic
    → ASG detects unhealthy → terminates and replaces instance
    → New instance passes health check → ALB adds back to rotation
```

---

## Labs

### Lab 1: Create ALB with Path-Based Routing
```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name prod-alb --type application \
    --subnets subnet-pub-1 subnet-pub-2 \
    --security-groups sg-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name web-targets --protocol HTTP --port 80 \
    --vpc-id vpc-xxxx \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --healthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

# Register targets
aws elbv2 register-targets --target-group-arn $TG_ARN \
    --targets Id=i-xxxx Id=i-yyyy

# Create HTTPS listener with ACM cert
aws elbv2 create-listener --load-balancer-arn $ALB_ARN \
    --protocol HTTPS --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:ACCT:certificate/xxxx \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

### Lab 2: ALB Authentication with Cognito
```bash
# Create listener rule that requires Cognito login
aws elbv2 create-rule --listener-arn $LISTENER_ARN \
    --priority 5 \
    --conditions Field=path-pattern,Values='/admin/*' \
    --actions '[{
        "Type": "authenticate-cognito",
        "AuthenticateCognitoConfig": {
            "UserPoolArn": "arn:aws:cognito-idp:us-east-1:ACCT:userpool/us-east-1_xxx",
            "UserPoolClientId": "client-id",
            "UserPoolDomain": "myapp"
        },
        "Order": 1
    }, {
        "Type": "forward",
        "TargetGroupArn": "'$ADMIN_TG_ARN'",
        "Order": 2
    }]'
```

### Lab 3: Connection Draining and Deregistration
```bash
# Set deregistration delay (connection draining)
aws elbv2 modify-target-group-attributes \
    --target-group-arn $TG_ARN \
    --attributes Key=deregistration_delay.timeout_seconds,Value=30

# During deployments, ALB waits 30 seconds for active connections
# to complete before removing the instance
```

---

## Interview Questions

1. **ALB vs NLB — when to use each?**
   > ALB: Layer 7, HTTP/HTTPS, path/host routing, WebSocket, ideal for web apps and microservices. NLB: Layer 4, TCP/UDP, ultra-low latency (<100μs), static IPs, ideal for gaming, VPN, and real-time apps.

2. **How do health checks work?**
   > LB sends periodic requests (HTTP/TCP) to targets. If a target fails N consecutive checks, it's marked unhealthy and removed from rotation. When it passes again, it's added back. This happens automatically — no manual intervention.

3. **What is sticky session and when to use it?**
   > ALB sends the same user to the same target using a cookie. Use for stateful apps that store session data locally. Better approach: use Redis/ElastiCache for session storage and avoid stickiness (enables true load balancing).

4. **How does SSL/TLS termination work with ALB?**
   > ALB decrypts HTTPS traffic (using ACM certificate), inspects it (for routing rules), then forwards to targets over HTTP. This offloads CPU-intensive TLS work from your application servers. For end-to-end encryption, configure ALB to forward via HTTPS to targets.

5. **Explain cross-zone load balancing.**
   > Without cross-zone: AZ-A has 2 instances, AZ-B has 4. Each AZ gets 50% traffic. AZ-A instances get 25% each, AZ-B instances get 12.5% each (uneven). With cross-zone: all 6 instances get ~16.7% each (even). ALB has cross-zone enabled by default.

6. **How would you implement a canary deployment with ALB?**
   > Create two target groups (current + new version). Use weighted target group routing: 95% to current, 5% to canary. Monitor error rates. If healthy, shift to 50/50, then 100% new. ALB handles this natively with no additional services.

7. **What is connection draining and why is it important?**
   > When removing an instance from the target group (during deployment/scaling), ALB stops sending new connections but waits for existing connections to complete (default 300 sec). Prevents dropping active user requests mid-transaction.

8. **Can ALB invoke Lambda directly?**
   > Yes. ALB can have Lambda functions as targets. The request is converted to a Lambda event, and the response is converted back to HTTP. Use for lightweight APIs or serverless backends without needing API Gateway.
