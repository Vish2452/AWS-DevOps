# Lambda — Serverless Compute (Overview)

> Run code without managing servers. Pay only for compute time consumed. Detailed deep-dive in Module 13.

## Key Concepts
- **Event-driven** — triggered by AWS services (S3, API Gateway, SQS, etc.)
- **Runtime** — Python, Node.js, Java, Go, .NET, Ruby, custom (container)
- **Handler** — function entry point (`file.function`)
- **Memory** — 128 MB to 10,240 MB (CPU scales proportionally)
- **Timeout** — max 15 minutes
- **Concurrency** — reserved vs provisioned
- **Layers** — shared libraries across functions
- **Cold start** — first invocation latency

## Common Triggers
```
S3 event → Lambda (file processing)
API Gateway → Lambda (REST API)
SQS → Lambda (queue processing)
EventBridge → Lambda (scheduled tasks)
DynamoDB Streams → Lambda (change data capture)
CloudWatch Alarms → SNS → Lambda (alerting)
```

## Quick Example
```python
# lambda_function.py
import json
import boto3

def handler(event, context):
    s3 = boto3.client('s3')
    
    # Process S3 event
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        print(f"Processing: s3://{bucket}/{key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Processed successfully')
    }
```

> **Full Lambda deep-dive with production patterns: [Module 13 →](../../13-Lambda-Glue-Data-Infra/)**
