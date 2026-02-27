# ELB — Elastic Load Balancing

> Distribute traffic across targets. Choose the right load balancer for your application.

## Load Balancer Types
| Type | Layer | Protocol | Use Case |
|------|-------|----------|----------|
| **ALB** | 7 (Application) | HTTP/HTTPS/gRPC | Web apps, microservices, path routing |
| **NLB** | 4 (Transport) | TCP/UDP/TLS | Ultra-low latency, static IP, gaming |
| **GLB** | 3 (Gateway) | IP | Third-party appliances (firewalls) |

## ALB Features
- **Path-based routing:** `/api/*` → backend, `/static/*` → S3
- **Host-based routing:** `api.example.com` → service A, `web.example.com` → service B
- **Target groups:** EC2, IP, Lambda
- **Health checks:** HTTP status code, path, interval
- **SSL/TLS termination** with ACM certificates
- **Sticky sessions** — cookie-based affinity
- **Cross-zone load balancing** — even distribution across AZs

## NLB Features
- **Static IP** per AZ (or Elastic IP)
- **Ultra-low latency** (millions of requests/sec)
- **TCP/UDP passthrough** — preserves source IP
- **Best for:** WebSocket, IoT, gaming, non-HTTP protocols

## Labs
```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name prod-alb \
    --type application \
    --subnets subnet-pub-1 subnet-pub-2 \
    --security-groups sg-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name web-targets \
    --protocol HTTP --port 80 \
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

# Path-based routing rule
aws elbv2 create-rule --listener-arn $LISTENER_ARN --priority 10 \
    --conditions Field=path-pattern,Values='/api/*' \
    --actions Type=forward,TargetGroupArn=$API_TG_ARN
```

## Interview Questions
1. ALB vs NLB — when to use each?
2. How do health checks work?
3. What is sticky session and when to use it?
4. How to configure SSL/TLS with ACM?
5. Explain path-based vs host-based routing
