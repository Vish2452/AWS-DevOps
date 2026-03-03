# Lambda — Serverless Compute

> Run code without managing servers. Pay only for compute time consumed. The "vending machine" of AWS — zero cost when idle, instant response when needed.

---

## Real-World Analogy

Lambda is like a **vending machine** vs EC2 which is a **restaurant**:
- **Restaurant (EC2):** You hire a chef, rent kitchen space, pay rent 24/7 even when no customers
- **Vending machine (Lambda):** Customer presses button → gets snack → you pay per snack sold. No customers? Zero cost!
- **Cold start** = the vending machine was in sleep mode, takes 2 seconds to wake up
- **Provisioned concurrency** = keeping the machine warmed up for busy times

---

## Key Concepts

| Concept | Description | Real-Time Example |
|---------|-------------|-------------------|
| **Event-driven** | Triggered by AWS services | S3 upload → Lambda resizes image automatically |
| **Runtime** | Python, Node.js, Java, Go, .NET, Ruby, container | Choose based on team's expertise |
| **Handler** | Function entry point | `index.handler` = file `index.py`, function `handler()` |
| **Memory** | 128 MB to 10,240 MB | CPU scales proportionally — more memory = more CPU |
| **Timeout** | Max 15 minutes | If your task takes longer, use Step Functions or ECS |
| **Concurrency** | Parallel executions | 1000 users hitting API → 1000 Lambda instances run simultaneously |
| **Reserved Concurrency** | Guaranteed capacity for a function | Ensure payment function always has 100 slots available |
| **Provisioned Concurrency** | Pre-warmed instances, no cold start | Critical API: 0ms cold start for first 50 concurrent requests |
| **Layers** | Shared libraries across functions | `numpy`, `pandas` layer shared by 20 data functions |
| **Aliases & Versions** | Deployment management | `prod` alias → v5, `staging` alias → v6. Shift traffic gradually |
| **Destinations** | Route success/failure to different services | Success → SQS, Failure → SNS for alerting |
| **VPC Access** | Lambda inside your VPC | Access private RDS database from Lambda |

---

## Common Triggers & Architecture Patterns

```
📸 S3 Upload → Lambda → Process image (resize, thumbnail, watermark)
🌐 API Gateway → Lambda → REST API (CRUD operations)
📬 SQS → Lambda → Process messages (order processing)
⏰ EventBridge → Lambda → Scheduled tasks (daily reports, cleanup)
📊 DynamoDB Streams → Lambda → React to data changes (audit log)
🔔 SNS → Lambda → Process notifications (auto-remediation)
📋 CloudWatch Alarm → SNS → Lambda → Auto-fix issues
🔄 Kinesis → Lambda → Real-time stream processing
```

---

## Real-Time Example 1: Image Processing Pipeline (Instagram/Pinterest Style)

**Scenario:** Users upload photos to your app. You need to automatically create thumbnails, add watermarks, and extract metadata.

```python
# lambda_function.py — Triggered when image uploaded to S3
import boto3
from PIL import Image
import io

s3 = boto3.client('s3')

def handler(event, context):
    # Get the uploaded image details
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    print(f"Processing: s3://{bucket}/{key}")
    
    # Download original image
    response = s3.get_object(Bucket=bucket, Key=key)
    image = Image.open(io.BytesIO(response['Body'].read()))
    
    # Create thumbnail (200x200)
    thumbnail = image.copy()
    thumbnail.thumbnail((200, 200))
    
    # Save thumbnail to S3
    buffer = io.BytesIO()
    thumbnail.save(buffer, 'JPEG', quality=85)
    buffer.seek(0)
    
    s3.put_object(
        Bucket=bucket,
        Key=f"thumbnails/{key}",
        Body=buffer,
        ContentType='image/jpeg'
    )
    
    # Create medium size (800x800) for feed
    medium = image.copy()
    medium.thumbnail((800, 800))
    buffer = io.BytesIO()
    medium.save(buffer, 'JPEG', quality=90)
    buffer.seek(0)
    
    s3.put_object(
        Bucket=bucket,
        Key=f"medium/{key}",
        Body=buffer,
        ContentType='image/jpeg'
    )
    
    return {
        'statusCode': 200,
        'body': f'Processed {key}: thumbnail + medium created'
    }
```

**Architecture:**
```
User uploads photo → S3 "uploads/" bucket
         │
         ▼ (S3 Event Notification)
    Lambda: image-processor
         │
         ├── thumbnails/photo.jpg (200x200)
         ├── medium/photo.jpg (800x800)
         └── metadata saved to DynamoDB
```

**Cost comparison:**
- EC2 (t3.medium running 24/7): ~$30/month even with 0 uploads
- Lambda: 10,000 images × 3 sec each × 512MB = **$0.25/month**

---

## Real-Time Example 2: Serverless REST API (Todo App)

**Scenario:** Build a REST API for a todo application without any servers.

```python
# lambda_function.py — API Gateway integration
import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('todos')

def handler(event, context):
    http_method = event['httpMethod']
    
    if http_method == 'GET':
        # List all todos
        result = table.scan()
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(result['Items'], default=str)
        }
    
    elif http_method == 'POST':
        # Create todo
        body = json.loads(event['body'])
        table.put_item(Item={
            'id': body['id'],
            'title': body['title'],
            'completed': False,
            'createdAt': '2026-03-02T10:00:00Z'
        })
        return {'statusCode': 201, 'body': json.dumps({'message': 'Created'})}
    
    elif http_method == 'DELETE':
        # Delete todo
        todo_id = event['pathParameters']['id']
        table.delete_item(Key={'id': todo_id})
        return {'statusCode': 200, 'body': json.dumps({'message': 'Deleted'})}
```

**Architecture:**
```
Client → API Gateway → Lambda → DynamoDB
         (REST API)    (Logic)   (Database)

GET    /todos       → List all todos
POST   /todos       → Create a todo
DELETE /todos/{id}  → Delete a todo
```

**Why this is powerful:** Zero servers to manage, auto-scales to millions of requests, pay only for what you use. A startup can serve 1M daily users for under $50/month.

---

## Real-Time Example 3: Automated Security Remediation

**Scenario:** Someone accidentally makes an S3 bucket public. Lambda automatically detects and fixes it.

```python
# auto-remediate-s3.py — Triggered by EventBridge
import boto3

s3 = boto3.client('s3')

def handler(event, context):
    # EventBridge sends S3 bucket policy change events
    bucket_name = event['detail']['requestParameters']['bucketName']
    
    print(f"Checking bucket: {bucket_name}")
    
    # Check if public access is enabled
    try:
        acl = s3.get_bucket_acl(Bucket=bucket_name)
        for grant in acl['Grants']:
            grantee = grant.get('Grantee', {})
            if grantee.get('URI') == 'http://acs.amazonaws.com/groups/global/AllUsers':
                print(f"⚠️ Bucket {bucket_name} is PUBLIC! Remediating...")
                
                # Block all public access
                s3.put_public_access_block(
                    Bucket=bucket_name,
                    PublicAccessBlockConfiguration={
                        'BlockPublicAcls': True,
                        'IgnorePublicAcls': True,
                        'BlockPublicPolicy': True,
                        'RestrictPublicBuckets': True
                    }
                )
                
                # Notify security team
                sns = boto3.client('sns')
                sns.publish(
                    TopicArn='arn:aws:sns:us-east-1:ACCT:security-alerts',
                    Subject=f'S3 Bucket Auto-Remediated: {bucket_name}',
                    Message=f'Bucket {bucket_name} was made public and has been automatically secured.'
                )
                
                return {'status': 'remediated'}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        raise
```

---

## Lambda Limits & Optimization

| Limit | Value | Workaround |
|-------|-------|------------|
| **Timeout** | 15 minutes max | Use Step Functions for longer workflows |
| **Memory** | 10,240 MB max | Use ECS/Fargate for compute-heavy tasks |
| **Package size** | 50 MB (zip), 10 GB (container) | Use layers, container images |
| **Concurrency** | 1,000 default (can increase) | Request limit increase via support |
| **Tmp storage** | 10 GB `/tmp` | Use S3 for larger files |

### Reducing Cold Starts
```
Cold Start Causes:
1. First invocation after idle → Lambda creates new container
2. VPC-attached functions → ENI creation adds 2-10 seconds
3. Large packages → longer download time

Solutions:
1. Provisioned Concurrency → pre-warm N instances ($$$)
2. Keep functions small → faster download
3. Use ARM (Graviton) → 20% cheaper, faster start
4. Initialize outside handler → reuse across invocations
```

```python
# ✅ GOOD: Initialize outside handler (reused across invocations)
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')  # Created once, reused

def handler(event, context):
    # This runs every invocation
    return table.get_item(Key={'id': event['userId']})

# ❌ BAD: Initialize inside handler (created every time)
def handler(event, context):
    dynamodb = boto3.resource('dynamodb')  # Slow! Created every time
    table = dynamodb.Table('users')
    return table.get_item(Key={'id': event['userId']})
```

---

## Labs

### Lab 1: Deploy a Lambda Function
```bash
# Create function
aws lambda create-function \
    --function-name image-processor \
    --runtime python3.12 \
    --handler lambda_function.handler \
    --role arn:aws:iam::ACCT:role/LambdaS3Role \
    --zip-file fileb://function.zip \
    --memory-size 512 --timeout 30 \
    --environment Variables='{BUCKET_NAME=my-app-uploads}'

# Add S3 trigger
aws lambda add-permission \
    --function-name image-processor \
    --statement-id s3-trigger \
    --action lambda:InvokeFunction \
    --principal s3.amazonaws.com \
    --source-arn arn:aws:s3:::my-app-uploads
```

### Lab 2: Create Lambda with Layers
```bash
# Create a layer with shared dependencies
cd layer && pip install Pillow -t python/lib/python3.12/site-packages/ && cd ..
zip -r pillow-layer.zip python/

aws lambda publish-layer-version \
    --layer-name pillow-layer \
    --zip-file fileb://pillow-layer.zip \
    --compatible-runtimes python3.12

# Attach layer to function
aws lambda update-function-configuration \
    --function-name image-processor \
    --layers arn:aws:lambda:us-east-1:ACCT:layer:pillow-layer:1
```

### Lab 3: Traffic Shifting with Aliases
```bash
# Publish a version
aws lambda publish-version --function-name my-api

# Create alias pointing to v1
aws lambda create-alias --function-name my-api \
    --name prod --function-version 1

# Shift 10% traffic to v2 (canary deployment)
aws lambda update-alias --function-name my-api \
    --name prod --function-version 2 \
    --routing-config AdditionalVersionWeights='{"1": 0.9}'
```

---

## Interview Questions

1. **What is Lambda and when would you use it?**
   > Serverless compute — run code without managing servers. Use for event-driven tasks (S3 file processing, API backends, scheduled jobs). Don't use for long-running processes (>15 min) or high-compute ML workloads.

2. **What is a cold start and how do you minimize it?**
   > First invocation after idle creates a new container (0.5-10 seconds). Minimize by: keep packages small, initialize SDK clients outside handler, use Provisioned Concurrency for critical paths, use ARM runtime.

3. **How does Lambda pricing work? Give a real example.**
   > $0.20 per 1M requests + $0.0000166667 per GB-second. Example: 1M invocations × 512MB × 200ms = $1.67/month. Compare to t3.medium running 24/7: $30/month. Lambda is 18x cheaper for bursty workloads.

4. **What is the maximum timeout for Lambda and what do you do if you need more?**
   > 15 minutes. For longer tasks: use Step Functions to orchestrate multiple Lambdas, ECS Fargate for batch jobs, or break the task into smaller chunks processed via SQS.

5. **Explain Lambda Layers with a use case.**
   > Shared code/libraries packaged separately. Example: pandas+numpy layer shared by 20 data processing functions. Update the layer once → all functions get the update. Reduces deployment package size.

6. **How do you deploy Lambda safely to production?**
   > Use aliases with weighted traffic shifting. v1 alias gets 90%, v2 gets 10%. Monitor errors. If v2 is healthy, shift to 50/50, then fully to v2. CodeDeploy can automate this with auto-rollback.

7. **What is the difference between Reserved and Provisioned Concurrency?**
   > Reserved: limits max concurrent executions for a function (protects other functions from being throttled). Provisioned: pre-warms N instances (eliminates cold starts). Reserved is free, Provisioned costs money.

8. **How does Lambda access resources in a VPC (like RDS)?**
   > Attach Lambda to VPC subnets and security groups. Lambda creates an ENI in your VPC. For internet access, route through NAT Gateway. Use RDS Proxy for connection pooling (Lambda can create thousands of DB connections).

> **Full Lambda deep-dive with production patterns: [Module 13 →](../../13-Lambda-Glue-Data-Infra/)**
