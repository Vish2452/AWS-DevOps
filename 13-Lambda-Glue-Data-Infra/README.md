# Module 13 — AWS Lambda, Glue & Data Infrastructure (1 Week)

> **Objective:** Build serverless event-driven architectures with Lambda, implement ETL pipelines with AWS Glue, and orchestrate workflows with Step Functions.

---

## ⚡ Real-World Analogy: Serverless is Like a Taxi vs. Owning a Car

```
🚗 EC2 (Traditional Server) = OWNING A CAR:
   • You buy it ($$$), even when parked in the garage
   • You pay insurance, maintenance, fuel
   • You drive it to work (8 hours), it sits idle the other 16 hours
   • You STILL pay for parking at night!
   • Monthly cost: $200 even if you drive 10 miles

🚕 Lambda (Serverless) = USING A TAXI:
   • No car to buy or maintain
   • Taxi appears when you need it (event trigger)
   • Pay ONLY for the ride (per millisecond of execution)
   • No passengers? Taxi disappears. Cost = $0!
   • Monthly cost: $3 for 10 rides
```

### Lambda + Glue + Step Functions = Smart Factory
```
  ┌──────────────────────────────────────────────────┐
  │  ⚡ Lambda = Individual ROBOT WORKERS                │
  │     Each robot does ONE specific job:               │
  │     - Robot A: Processes incoming orders             │
  │     - Robot B: Resizes uploaded photos               │
  │     - Robot C: Sends welcome emails                  │
  │     They activate only when needed, sleep otherwise. │
  │                                                      │
  │  🔄 Glue = ASSEMBLY LINE for data                     │
  │     Raw materials (messy data) come in:              │
  │     CSV files, JSON logs, database exports            │
  │     Glue cleans, transforms, and organizes them       │
  │     into neat packages (Parquet in S3 data lake).     │
  │                                                      │
  │  📊 Step Functions = FACTORY MANAGER                   │
  │     Orchestrates the workflow:                       │
  │     "First do A, then B and C in parallel,           │
  │      if B fails retry 3 times, then do D."           │
  │     Like a project manager with a flowchart.          │
  └──────────────────────────────────────────────────┘
```

### Real-World Example: Photo Sharing App
```
  User uploads photo to S3
       │
       ▼ (S3 Event triggers Lambda)
  Lambda ➀: Resize photo (thumbnail + full)
       │
       ▼
  Lambda ➁: Scan for inappropriate content (Rekognition)
       │
       ├── ✅ Safe → Lambda ➂: Save metadata to DynamoDB
       │                     → Lambda ➃: Notify followers via SNS
       │
       └── ❌ Flagged → Lambda ➄: Move to review queue
                          → Lambda ➅: Alert admin

  Cost for 100,000 photos/month: ~$5 (not $500 for running EC2 24/7!)
```

### Glue ETL = Data Cleaning Service
```
  BEFORE (Raw Data = Messy Room):
    - 50 CSV files in different formats
    - Some have "N/A", others have "null", others have blanks
    - Dates: "01/15/2024", "2024-01-15", "Jan 15 2024"
    - Duplicates everywhere

  AFTER Glue ETL (Clean Room):
    - 1 clean Parquet file in S3 data lake
    - Standardized formats
    - Duplicates removed
    - Ready for analytics with Athena ($5 per TB scanned!)
```

---

## Part 1: AWS Lambda — Production Patterns

### Lambda Architecture
```
Event Sources → Lambda Function → Destinations
     │                │                │
  API Gateway     Handler Code     DynamoDB
  S3 Events       (Python/Node)    S3 Output
  SQS Queue       max 15 min       SNS/SQS
  EventBridge     max 10GB mem     Step Functions
  DynamoDB Stream max 10,240 MB    CloudWatch Logs
  CloudWatch Events
```

### Lambda Function (Python)
```python
# lambda_function.py
import json
import boto3
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('processed-events')

def lambda_handler(event, context):
    """Process S3 events — triggered when file is uploaded."""
    logger.info(f"Event: {json.dumps(event)}")

    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        size = record['s3']['object']['size']

        logger.info(f"Processing: s3://{bucket}/{key} ({size} bytes)")

        # Download and process
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        lines = content.strip().split('\n')

        # Store metadata in DynamoDB
        table.put_item(Item={
            'file_key': key,
            'bucket': bucket,
            'line_count': len(lines),
            'size_bytes': size,
            'processed_at': datetime.utcnow().isoformat(),
            'status': 'completed'
        })

        logger.info(f"Processed {len(lines)} lines from {key}")

    return {
        'statusCode': 200,
        'body': json.dumps({'message': f'Processed {len(event["Records"])} files'})
    }
```

### Lambda with API Gateway
```python
# api_handler.py
import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return str(obj)
        return super().default(obj)

def lambda_handler(event, context):
    http_method = event['httpMethod']
    path = event['path']

    if http_method == 'GET' and path == '/users':
        result = table.scan()
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(result['Items'], cls=DecimalEncoder)
        }

    elif http_method == 'POST' and path == '/users':
        body = json.loads(event['body'])
        table.put_item(Item=body)
        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'User created'})
        }

    return {'statusCode': 404, 'body': json.dumps({'error': 'Not found'})}
```

### Lambda Layers & Environment
```bash
# Create a layer for shared dependencies
mkdir -p python/lib/python3.12/site-packages
pip install requests pandas -t python/lib/python3.12/site-packages/
zip -r layer.zip python/

aws lambda publish-layer-version \
  --layer-name shared-utils \
  --zip-file fileb://layer.zip \
  --compatible-runtimes python3.12

# Environment variables (use SSM/Secrets Manager for secrets)
aws lambda update-function-configuration \
  --function-name my-function \
  --environment "Variables={ENV=prod,TABLE_NAME=users,LOG_LEVEL=INFO}"
```

### Terraform for Lambda
```hcl
resource "aws_lambda_function" "processor" {
  filename         = "lambda.zip"
  function_name    = "${var.project}-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.events.name
      ENV        = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tracing_config {
    mode = "Active"  # X-Ray tracing
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.input.arn
  function_name                      = aws_lambda_function.processor.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  function_response_types            = ["ReportBatchItemFailures"]
}
```

---

## Part 2: AWS Glue — ETL Pipelines

### Glue Architecture
```
Data Sources → Glue Crawler → Data Catalog → Glue Job → Target
     │              │              │              │          │
  S3 (raw)     Discover       Schema         PySpark     S3 (processed)
  RDS          schema &       registry       Transform   Redshift
  DynamoDB     partitions     (Hive)         Clean       RDS
  JDBC                        Tables         Aggregate   Athena queries
```

### Glue ETL Job (PySpark)
```python
# glue_etl_job.py
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, year, month, to_timestamp, when

# Initialize
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_PATH', 'TARGET_PATH'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read raw data from S3
raw_df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(args['SOURCE_PATH'])

print(f"Raw records: {raw_df.count()}")

# Transform: clean, filter, enrich
cleaned_df = raw_df \
    .filter(col("email").isNotNull()) \
    .filter(col("amount") > 0) \
    .withColumn("transaction_date", to_timestamp(col("date"), "yyyy-MM-dd")) \
    .withColumn("year", year(col("transaction_date"))) \
    .withColumn("month", month(col("transaction_date"))) \
    .withColumn("category", when(col("amount") > 1000, "high")
                            .when(col("amount") > 100, "medium")
                            .otherwise("low")) \
    .dropDuplicates(["transaction_id"])

print(f"Cleaned records: {cleaned_df.count()}")

# Write partitioned Parquet to S3
cleaned_df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(args['TARGET_PATH'])

job.commit()
```

### Glue Crawler (Terraform)
```hcl
resource "aws_glue_catalog_database" "analytics" {
  name = "${var.project}-analytics"
}

resource "aws_glue_crawler" "raw_data" {
  database_name = aws_glue_catalog_database.analytics.name
  name          = "${var.project}-raw-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.id}/raw/"
  }

  schedule = "cron(0 1 * * ? *)"  # Daily at 1 AM

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}
```

---

## Part 3: AWS Step Functions — Workflow Orchestration

### State Machine Definition
```json
{
  "Comment": "Data Processing Pipeline",
  "StartAt": "ValidateInput",
  "States": {
    "ValidateInput": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456:function:validate-input",
      "Next": "ProcessChoice",
      "Catch": [{
        "ErrorEquals": ["ValidationError"],
        "Next": "NotifyFailure"
      }]
    },
    "ProcessChoice": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.fileSize",
          "NumericGreaterThan": 1000000,
          "Next": "LargeFileProcess"
        }
      ],
      "Default": "SmallFileProcess"
    },
    "LargeFileProcess": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "large-file-etl",
        "Arguments": {
          "--SOURCE_PATH.$": "$.s3Path",
          "--TARGET_PATH": "s3://output-bucket/processed/"
        }
      },
      "Next": "NotifySuccess"
    },
    "SmallFileProcess": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456:function:process-small",
      "Next": "NotifySuccess"
    },
    "NotifySuccess": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:us-east-1:123456:pipeline-notifications",
        "Message.$": "States.Format('Pipeline completed for {}', $.fileName)"
      },
      "End": true
    },
    "NotifyFailure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:us-east-1:123456:pipeline-failures",
        "Message.$": "States.Format('Pipeline FAILED: {}', $.error)"
      },
      "End": true
    }
  }
}
```

---

## Real-Time Project: Serverless Data Pipeline

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Serverless Data Pipeline                   │
│                                                              │
│  S3 Upload → EventBridge → Step Functions                    │
│                                  │                           │
│                    ┌─────────────┼─────────────┐             │
│                    │             │             │              │
│               Validate      ETL (Glue)    Transform          │
│               (Lambda)      PySpark       (Lambda)           │
│                    │             │             │              │
│                    └─────────────┼─────────────┘             │
│                                  │                           │
│                            S3 (Parquet)                      │
│                                  │                           │
│                         Glue Crawler → Catalog               │
│                                  │                           │
│                            Athena Queries                    │
│                                  │                           │
│                         QuickSight Dashboards                │
│                                                              │
│  Monitoring: CloudWatch + X-Ray + SNS Alerts                 │
└──────────────────────────────────────────────────────────────┘
```

### Project Structure
```
serverless-data-pipeline/
├── terraform/
│   ├── main.tf
│   ├── lambda.tf         # Lambda functions
│   ├── glue.tf           # Glue jobs & crawlers
│   ├── step-functions.tf # State machine
│   ├── s3.tf             # Data lake buckets
│   ├── iam.tf            # IAM roles
│   └── eventbridge.tf    # Event rules
├── lambda/
│   ├── validate/
│   │   └── handler.py
│   ├── transform/
│   │   └── handler.py
│   └── notify/
│       └── handler.py
├── glue/
│   └── etl_job.py
├── step-functions/
│   └── pipeline.asl.json
└── tests/
    ├── test_validate.py
    └── test_transform.py
```

### Deliverables
- [ ] Lambda functions (validate, transform, notify) with proper IAM
- [ ] Glue ETL job converting CSV → partitioned Parquet
- [ ] Glue Crawler auto-discovering schema
- [ ] Step Functions state machine orchestrating pipeline
- [ ] EventBridge rule triggering on S3 upload
- [ ] Dead letter queues for failed Lambda invocations
- [ ] X-Ray tracing across all Lambda functions
- [ ] Athena queries on processed data
- [ ] CloudWatch alarms for job failures
- [ ] Terraform for all infrastructure
- [ ] Unit tests for Lambda handlers
