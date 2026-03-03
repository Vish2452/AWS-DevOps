# API Gateway — Fully Managed API Service

> Create, publish, maintain, monitor, and secure REST, HTTP, and WebSocket APIs at any scale. The "front door" for your backend services.

---

## Real-World Analogy

API Gateway is like a **hotel concierge**:
- Guests (clients) make requests to the concierge (API Gateway)
- Concierge validates identity (authentication), checks permissions (authorization)
- Routes requests to the right department (backend service)
- Rate limits demanding guests ("Sir, one request at a time")
- Caches common answers ("Yes, breakfast is 7-10 AM" — no need to call kitchen every time)
- Transforms requests/responses as needed

---

## API Types

| Type | Protocol | Use Case | Cost | Latency |
|------|----------|----------|------|---------|
| **REST API** | REST | Full-featured, caching, WAF | $3.50/million | ~30ms overhead |
| **HTTP API** | REST | Simple proxy, cheaper, faster | $1.00/million | ~10ms overhead |
| **WebSocket** | WebSocket | Real-time: chat, dashboards | $1.00/million msg | Persistent connection |

**Quick Decision:** Use HTTP API unless you need caching, WAF, usage plans, or request validation (then REST API).

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Stage** | Deployment version | `dev`, `staging`, `prod` |
| **Resource** | URL path | `/users`, `/orders/{id}` |
| **Method** | HTTP verb | GET, POST, PUT, DELETE |
| **Integration** | Backend connection | Lambda, HTTP endpoint, AWS service |
| **Authorizer** | Authentication | Cognito, Lambda, IAM, JWT |
| **Throttling** | Rate limiting | 10,000 req/sec (default), per-API/stage/method |
| **Usage Plan** | API key quotas | Free tier: 1000/day, Pro: 100,000/day |
| **CORS** | Cross-origin settings | Allow browser JS to call your API |

---

## Real-Time Example 1: Serverless REST API for Mobile App

**Scenario:** Build a REST API for a todo mobile app with authentication, CRUD operations, and rate limiting.

```
┌─────────────┐     ┌───────────────┐     ┌──────────┐     ┌──────────────┐
│  Mobile App │────▶│  API Gateway  │────▶│  Lambda  │────▶│  DynamoDB   │
│  (React     │     │  (REST API)   │     │  (CRUD)  │     │  (todos     │
│   Native)   │     │               │     │          │     │   table)    │
└─────────────┘     │  - JWT Auth   │     └──────────┘     └──────────────┘
                    │  - Rate Limit │
                    │  - Caching    │
                    │  - CORS       │
                    └───────────────┘

Endpoints:
GET    /todos          → Lambda → DynamoDB scan by userId
POST   /todos          → Lambda → DynamoDB putItem
GET    /todos/{id}     → Lambda → DynamoDB getItem
PUT    /todos/{id}     → Lambda → DynamoDB updateItem
DELETE /todos/{id}     → Lambda → DynamoDB deleteItem
```

```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api --name "Todo-API" \
    --description "Todo app backend" \
    --endpoint-configuration types=REGIONAL \
    --query 'id' --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID \
    --query 'items[0].id' --output text)

# Create /todos resource
TODOS_ID=$(aws apigateway create-resource --rest-api-id $API_ID \
    --parent-id $ROOT_ID --path-part todos \
    --query 'id' --output text)

# Create GET method with Lambda integration
aws apigateway put-method --rest-api-id $API_ID \
    --resource-id $TODOS_ID --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $AUTH_ID

aws apigateway put-integration --rest-api-id $API_ID \
    --resource-id $TODOS_ID --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCT:function:todoHandler/invocations

# Deploy to 'prod' stage
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod \
    --stage-description "Production" \
    --description "v1.0"

# Enable caching on prod stage (0.5GB cache)
aws apigateway update-stage --rest-api-id $API_ID --stage-name prod \
    --patch-operations op=replace,path=/cacheClusterEnabled,value=true \
    op=replace,path=/cacheClusterSize,value=0.5
```

---

## Real-Time Example 2: API Key Management with Usage Plans

**Scenario:** You're offering a public API. Free tier gets 1,000 requests/day, Pro tier gets 100,000/day.

```bash
# Create usage plans
FREE_PLAN=$(aws apigateway create-usage-plan --name "Free Tier" \
    --throttle burstLimit=10,rateLimit=5 \
    --quota limit=1000,period=DAY \
    --api-stages apiId=$API_ID,stage=prod \
    --query 'id' --output text)

PRO_PLAN=$(aws apigateway create-usage-plan --name "Pro Tier" \
    --throttle burstLimit=100,rateLimit=50 \
    --quota limit=100000,period=DAY \
    --api-stages apiId=$API_ID,stage=prod \
    --query 'id' --output text)

# Create API keys for customers
KEY_ID=$(aws apigateway create-api-key --name "customer-acme" \
    --enabled --query 'id' --output text)

# Associate key with usage plan
aws apigateway create-usage-plan-key \
    --usage-plan-id $PRO_PLAN \
    --key-id $KEY_ID \
    --key-type API_KEY

# Check usage
aws apigateway get-usage --usage-plan-id $PRO_PLAN \
    --start-date 2026-01-01 --end-date 2026-01-31 \
    --key-id $KEY_ID
```

---

## Real-Time Example 3: WebSocket API for Real-Time Chat

**Scenario:** Build a real-time chat application where messages are pushed to connected clients instantly.

```
┌─────────────────────────────────────────────────────────────┐
│                  WebSocket API Flow                         │
│                                                             │
│  Client ──$connect──▶ API GW ──▶ Lambda (save connectionId)│
│  Client ──sendMessage──▶ API GW ──▶ Lambda (broadcast)     │
│  Client ◀──message────── API GW ◀── Lambda (push to all)   │
│  Client ──$disconnect──▶ API GW ──▶ Lambda (remove conn)   │
└─────────────────────────────────────────────────────────────┘

DynamoDB Connections Table:
┌──────────────────┬──────────┬─────────────┐
│ connectionId     │ roomId   │ username    │
├──────────────────┼──────────┼─────────────┤
│ abc123           │ room-1   │ Alice       │
│ def456           │ room-1   │ Bob         │
│ ghi789           │ room-2   │ Charlie     │
└──────────────────┴──────────┴─────────────┘
```

```bash
# Create WebSocket API
WS_API=$(aws apigatewayv2 create-api --name "Chat-WebSocket" \
    --protocol-type WEBSOCKET \
    --route-selection-expression '$request.body.action' \
    --query 'ApiId' --output text)

# Create routes
aws apigatewayv2 create-route --api-id $WS_API \
    --route-key '$connect' \
    --target integrations/$CONNECT_INTEGRATION

aws apigatewayv2 create-route --api-id $WS_API \
    --route-key '$disconnect' \
    --target integrations/$DISCONNECT_INTEGRATION

aws apigatewayv2 create-route --api-id $WS_API \
    --route-key 'sendMessage' \
    --target integrations/$MESSAGE_INTEGRATION
```

---

## Labs

### Lab 1: Create HTTP API with Lambda
```bash
# Simplest API (HTTP API — cheaper and faster than REST)
aws apigatewayv2 create-api --name "Simple-API" \
    --protocol-type HTTP \
    --target arn:aws:lambda:us-east-1:ACCT:function:myHandler

# This creates API + default route + Lambda integration in one command!
# URL: https://{api-id}.execute-api.us-east-1.amazonaws.com/
```

### Lab 2: Custom Domain
```bash
# Create custom domain
aws apigateway create-domain-name \
    --domain-name api.mycompany.com \
    --regional-certificate-arn arn:aws:acm:us-east-1:ACCT:certificate/xxx \
    --endpoint-configuration types=REGIONAL

# Map to API stage
aws apigateway create-base-path-mapping \
    --domain-name api.mycompany.com \
    --rest-api-id $API_ID \
    --stage prod \
    --base-path v1

# Result: https://api.mycompany.com/v1/todos
```

---

## Interview Questions

1. **REST API vs HTTP API — when to use each?**
   > HTTP API: 70% cheaper, lower latency (~10ms vs ~30ms), supports JWT authorizers, OIDC. Use for simple Lambda/HTTP proxy. REST API: caching, WAF integration, usage plans with API keys, request/response transformation, input validation. Use when you need these advanced features.

2. **How does API Gateway handle authentication?**
   > Four options: (1) **IAM** — for AWS-to-AWS calls (signed requests), (2) **Cognito** — for user authentication (JWT tokens), (3) **Lambda Authorizer** — custom auth logic (verify custom tokens, check database), (4) **API Keys** — for tracking/throttling (not security). Most common: Cognito for user-facing, IAM for service-to-service.

3. **What is API Gateway throttling?**
   > Default: 10,000 requests/sec per region (account-level). Can set per-API, per-stage, and per-method throttling. Burst limit handles spikes. When exceeded, returns 429 Too Many Requests. Usage plans add per-customer throttling with API keys. Protects backends from traffic spikes.

4. **How does API Gateway caching work?**
   > REST API only. Caches responses for a TTL (default: 300s). Cache key = full request URL. Reduces Lambda invocations/backend calls. Cache sizes: 0.5GB to 237GB. Cost: $0.02-0.25/hour. Can invalidate with `Cache-Control: max-age=0` header. Per-method cache settings possible.

5. **What are stages in API Gateway?**
   > Stages are named deployments (dev, staging, prod). Each stage gets its own URL, can have different settings (caching, throttling, stage variables), and different Lambda aliases. Deploy changes → create deployment → update stage. Allows canary deployments (10% traffic to new version).

6. **How would you implement rate limiting per customer?**
   > Create Usage Plans with throttle and quota settings. Create API Keys for each customer. Associate keys with usage plans. Free plan: 5 req/sec, 1000/day. Pro plan: 50 req/sec, 100K/day. API Gateway enforces limits automatically and returns 429 when exceeded.

7. **REST API vs WebSocket API — when to use WebSocket?**
   > REST: request-response pattern, client initiates every call. WebSocket: persistent bidirectional connection, server can push to client. Use WebSocket for: real-time chat, live dashboards, gaming, collaborative editing, stock tickers. WebSocket is cheaper for frequent updates vs repeated REST polling.

8. **How to handle CORS in API Gateway?**
   > For HTTP API: enable CORS in API settings (allows origins, methods, headers). For REST API: add OPTIONS method with mock integration returning CORS headers, AND add CORS headers in your Lambda response. Common mistake: forgetting CORS headers in Lambda response even when OPTIONS is configured.
