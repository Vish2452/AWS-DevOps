# Python for DevOps (3 Weeks)

> **Objective:** Master Python for AWS automation, serverless Lambda functions, FinOps cost optimization, and security-driven projects. Build production CLI tools and event-driven pipelines.

---

## 🐍 Real-World Analogy: Python is a Swiss Army Knife for DevOps

If every DevOps tool is a specialist worker, **Python is the versatile intern who can do anything**:

```
🛠️ Without Python (manual labor):
   • Check 50 AWS accounts for unused resources → 3 days of clicking
   • Generate monthly cost report              → 4 hours in Excel
   • Rotate 200 IAM access keys                → Full day of manual work
   • Scan S3 buckets for public access          → 2 hours per account

🐍 With Python (automation):
   • Check 50 AWS accounts for unused resources → boto3 script: 5 minutes
   • Generate monthly cost report              → Lambda runs overnight: $0.01
   • Rotate 200 IAM access keys                → Automated: 30 seconds
   • Scan S3 buckets for public access          → 1 script, all accounts: 2 min
```

### Python in the DevOps Toolchain
```
  ┌──────────────────────────────────────────────────┐
  │  🏗️  Infrastructure: boto3 (AWS SDK for Python)       │
  │      Create EC2, manage S3, query RDS               │
  │                                                      │
  │  ⚡ Serverless: AWS Lambda (Python runtime)           │
  │      Event-driven functions, pay per millisecond     │
  │                                                      │
  │  💰 FinOps: Cost optimization scripts                 │
  │      Find zombie resources, right-size instances      │
  │      "This script saved us $18,000/month!"            │
  │                                                      │
  │  🛡️ Security: Automated compliance scanning           │
  │      Check security groups, scan for public S3        │
  │                                                      │
  │  📊 Monitoring: Custom CloudWatch metrics              │
  │      Parse logs, create dashboards, trigger alerts    │
  │                                                      │
  │  🤖 ChatOps: Slack bots for automation                 │
  │      "@bot deploy v2.3 to production"                 │
  └──────────────────────────────────────────────────┘
```

### boto3 = Python Talks to AWS
```
  Think of boto3 as a TV REMOTE CONTROL for AWS:

  Without remote (AWS Console): Walk to the TV, press buttons manually.
  With remote (boto3):          Press buttons from the couch.

  import boto3
  ec2 = boto3.client('ec2')           # Pick up the remote
  ec2.stop_instances(InstanceIds=[..]) # Press the STOP button
  
  That's it! You just stopped a server with 3 lines of Python.

  Now imagine: Run this for ALL 500 dev servers every Friday at 6 PM.
  = Save $12,000/month in idle compute costs!
```

---

## Week 1 — Python Fundamentals & AWS Automation

### Topics
- Python fundamentals: variables, data types, operators
- Data structures: lists, tuples, dicts, sets
- Loops, conditionals, functions, decorators
- Virtual environments (`venv`, `pip`, `requirements.txt`)
- File handling: read/write, JSON/YAML parsing
- Error handling: try/except/finally, custom exceptions
- Essential libraries: `boto3`, `requests`, `os`, `subprocess`, `pathlib`
- CLI tools with `argparse`
- Making API calls with `requests`

### Hands-On: AWS Resource Creator
```python
#!/usr/bin/env python3
"""Create AWS resources programmatically with boto3."""

import boto3
import json
import argparse
from botocore.exceptions import ClientError

def create_vpc(ec2, cidr_block, name):
    """Create a VPC with DNS support."""
    vpc = ec2.create_vpc(CidrBlock=cidr_block)
    vpc.wait_until_available()
    vpc.create_tags(Tags=[{'Key': 'Name', 'Value': name}])
    vpc.modify_attribute(EnableDnsHostnames={'Value': True})
    print(f"✓ VPC created: {vpc.id} ({cidr_block})")
    return vpc

def create_subnet(ec2, vpc_id, cidr, az, name, public=False):
    """Create a subnet in the given VPC."""
    subnet = ec2.create_subnet(
        VpcId=vpc_id, CidrBlock=cidr, AvailabilityZone=az
    )
    subnet.create_tags(Tags=[{'Key': 'Name', 'Value': name}])
    if public:
        subnet.meta.client.modify_subnet_attribute(
            SubnetId=subnet.id,
            MapPublicIpOnLaunch={'Value': True}
        )
    print(f"✓ Subnet created: {subnet.id} ({cidr}) in {az}")
    return subnet

def create_security_group(ec2, vpc_id, name, description):
    """Create a security group with common rules."""
    sg = ec2.create_security_group(
        GroupName=name, Description=description, VpcId=vpc_id
    )
    sg.authorize_ingress(IpPermissions=[
        {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80,
         'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'HTTP'}]},
        {'IpProtocol': 'tcp', 'FromPort': 443, 'ToPort': 443,
         'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'HTTPS'}]},
    ])
    print(f"✓ Security Group created: {sg.id}")
    return sg

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='AWS Resource Creator')
    parser.add_argument('--region', default='us-east-1')
    parser.add_argument('--project', required=True)
    args = parser.parse_args()

    ec2 = boto3.resource('ec2', region_name=args.region)
    vpc = create_vpc(ec2, '10.0.0.0/16', f'{args.project}-vpc')
    create_subnet(ec2, vpc.id, '10.0.1.0/24', f'{args.region}a',
                  f'{args.project}-public-1', public=True)
    create_security_group(ec2, vpc.id, f'{args.project}-sg', 'Web traffic')
```

### Hands-On: Cloud Usage Report Generator
```python
#!/usr/bin/env python3
"""Generate a cloud usage report from an AWS account."""

import boto3
import json
from datetime import datetime, timedelta

class AWSReporter:
    def __init__(self, region='us-east-1'):
        self.region = region
        self.session = boto3.Session(region_name=region)

    def get_ec2_summary(self):
        ec2 = self.session.client('ec2')
        instances = ec2.describe_instances()
        summary = {'running': 0, 'stopped': 0, 'total': 0, 'types': {}}

        for res in instances['Reservations']:
            for inst in res['Instances']:
                summary['total'] += 1
                state = inst['State']['Name']
                itype = inst['InstanceType']
                summary[state] = summary.get(state, 0) + 1
                summary['types'][itype] = summary['types'].get(itype, 0) + 1

        return summary

    def get_s3_summary(self):
        s3 = self.session.client('s3')
        buckets = s3.list_buckets()['Buckets']
        return {
            'total_buckets': len(buckets),
            'buckets': [b['Name'] for b in buckets]
        }

    def get_rds_summary(self):
        rds = self.session.client('rds')
        instances = rds.describe_db_instances()['DBInstances']
        return [{
            'id': db['DBInstanceIdentifier'],
            'engine': db['Engine'],
            'class': db['DBInstanceClass'],
            'status': db['DBInstanceStatus'],
            'multi_az': db['MultiAZ']
        } for db in instances]

    def get_cost_summary(self, days=30):
        ce = self.session.client('ce', region_name='us-east-1')
        end = datetime.utcnow().strftime('%Y-%m-%d')
        start = (datetime.utcnow() - timedelta(days=days)).strftime('%Y-%m-%d')

        result = ce.get_cost_and_usage(
            TimePeriod={'Start': start, 'End': end},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )

        costs = []
        for period in result['ResultsByTime']:
            for group in period['Groups']:
                costs.append({
                    'service': group['Keys'][0],
                    'cost': float(group['Metrics']['UnblendedCost']['Amount'])
                })

        return sorted(costs, key=lambda x: x['cost'], reverse=True)[:10]

    def generate_report(self):
        report = {
            'generated_at': datetime.utcnow().isoformat(),
            'region': self.region,
            'ec2': self.get_ec2_summary(),
            's3': self.get_s3_summary(),
            'rds': self.get_rds_summary(),
            'top_costs': self.get_cost_summary()
        }
        return report

if __name__ == '__main__':
    reporter = AWSReporter()
    report = reporter.generate_report()
    print(json.dumps(report, indent=2, default=str))
```

### Hands-On: REST API CRUD with `requests`
```python
#!/usr/bin/env python3
"""REST API CRUD operations."""
import requests

BASE_URL = "https://jsonplaceholder.typicode.com"

# CREATE
resp = requests.post(f"{BASE_URL}/posts", json={
    "title": "DevOps Post", "body": "Python automation", "userId": 1
})
print(f"CREATE: {resp.status_code} → {resp.json()['id']}")

# READ
resp = requests.get(f"{BASE_URL}/posts/1")
print(f"READ:   {resp.json()['title']}")

# UPDATE
resp = requests.put(f"{BASE_URL}/posts/1", json={
    "title": "Updated", "body": "New content", "userId": 1
})
print(f"UPDATE: {resp.status_code}")

# DELETE
resp = requests.delete(f"{BASE_URL}/posts/1")
print(f"DELETE: {resp.status_code}")
```

---

## Week 2 — Lambda & Serverless Automation

### Lambda with Event-Driven Architecture
```
┌─────────────┐    ┌────────────┐    ┌─────────────┐
│ EventBridge │───▶│   Lambda   │───▶│  SES Email  │
│ (cron: 9AM) │    │ (report)   │    │  (team)     │
└─────────────┘    └────────────┘    └─────────────┘

┌─────────────┐    ┌────────────┐    ┌─────────────┐
│ S3 Upload   │───▶│   Lambda   │───▶│  S3 Output  │
│ (trigger)   │    │ (process)  │    │  (results)  │
└─────────────┘    └────────────┘    └─────────────┘

┌─────────────┐    ┌────────────┐    ┌─────────────┐
│ EventBridge │───▶│   Lambda   │───▶│  IAM API    │
│ (cron: Mon) │    │ (rotate)   │    │  (new keys) │
└─────────────┘    └────────────┘    └─────────────┘
```

### Project: Cloud Report Email Automation
```python
# lambda_function.py — Send cloud report via SES
import boto3
import json
from datetime import datetime

ses = boto3.client('ses')
ec2 = boto3.client('ec2')
rds = boto3.client('rds')
ce = boto3.client('ce', region_name='us-east-1')

def lambda_handler(event, context):
    # Gather data
    instances = ec2.describe_instances()
    running = sum(
        1 for r in instances['Reservations']
        for i in r['Instances'] if i['State']['Name'] == 'running'
    )

    databases = rds.describe_db_instances()['DBInstances']

    # Build HTML report
    html = f"""
    <h2>Daily Cloud Report - {datetime.utcnow().strftime('%Y-%m-%d')}</h2>
    <table border="1" cellpadding="8">
      <tr><td><b>Running EC2 Instances</b></td><td>{running}</td></tr>
      <tr><td><b>RDS Databases</b></td><td>{len(databases)}</td></tr>
    </table>
    <h3>RDS Details</h3>
    <table border="1" cellpadding="8">
      <tr><th>ID</th><th>Engine</th><th>Class</th><th>Status</th></tr>
      {''.join(f"<tr><td>{db['DBInstanceIdentifier']}</td><td>{db['Engine']}</td><td>{db['DBInstanceClass']}</td><td>{db['DBInstanceStatus']}</td></tr>" for db in databases)}
    </table>
    """

    # Send via SES
    ses.send_email(
        Source='devops@company.com',
        Destination={'ToAddresses': ['team@company.com']},
        Message={
            'Subject': {'Data': f'Daily Cloud Report - {datetime.utcnow().strftime("%Y-%m-%d")}'},
            'Body': {'Html': {'Data': html}}
        }
    )

    return {'statusCode': 200, 'body': 'Report sent'}
```

### Project: IAM Key Rotation
```python
# iam_key_rotation.py
import boto3
from datetime import datetime, timezone

iam = boto3.client('iam')
ses = boto3.client('ses')
MAX_KEY_AGE_DAYS = 90

def lambda_handler(event, context):
    users = iam.list_users()['Users']
    findings = []

    for user in users:
        keys = iam.list_access_keys(UserName=user['UserName'])['AccessKeyMetadata']
        for key in keys:
            if key['Status'] != 'Active':
                continue
            age = (datetime.now(timezone.utc) - key['CreateDate']).days
            if age > MAX_KEY_AGE_DAYS:
                # Deactivate old key
                iam.update_access_key(
                    UserName=user['UserName'],
                    AccessKeyId=key['AccessKeyId'],
                    Status='Inactive'
                )
                findings.append({
                    'user': user['UserName'],
                    'key_id': key['AccessKeyId'],
                    'age_days': age,
                    'action': 'DEACTIVATED'
                })

    if findings:
        # Notify via SES
        body = '\n'.join(
            f"User: {f['user']}, Key: {f['key_id']}, Age: {f['age_days']}d → {f['action']}"
            for f in findings
        )
        ses.send_email(
            Source='security@company.com',
            Destination={'ToAddresses': ['security-team@company.com']},
            Message={
                'Subject': {'Data': f'IAM Key Rotation Report - {len(findings)} keys rotated'},
                'Body': {'Text': {'Data': body}}
            }
        )

    return {'rotated': len(findings), 'details': findings}
```

### Project: Image Processing Pipeline (Multi-Lambda)
```python
# Lambda 1: Trigger on S3 upload → validate image
# Lambda 2: Resize image (uses Pillow from Lambda Layer)
# Lambda 3: Generate thumbnail + store metadata in DynamoDB

# Lambda Layer for dependencies
# layers/pillow/python/PIL/...

# resize_handler.py
import boto3
import os
from PIL import Image
from io import BytesIO

s3 = boto3.client('s3')
OUTPUT_BUCKET = os.environ['OUTPUT_BUCKET']

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        # Download original
        response = s3.get_object(Bucket=bucket, Key=key)
        img = Image.open(BytesIO(response['Body'].read()))

        # Resize to multiple dimensions
        sizes = {'large': (1200, 800), 'medium': (600, 400), 'thumb': (150, 150)}

        for label, dimensions in sizes.items():
            resized = img.copy()
            resized.thumbnail(dimensions, Image.LANCZOS)

            buffer = BytesIO()
            resized.save(buffer, format='JPEG', quality=85)
            buffer.seek(0)

            output_key = f"processed/{label}/{os.path.basename(key)}"
            s3.put_object(
                Bucket=OUTPUT_BUCKET, Key=output_key,
                Body=buffer, ContentType='image/jpeg'
            )

    return {'statusCode': 200}
```

### Deploy Lambda with Terraform
```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/report"
  output_path = "${path.module}/.build/report.zip"
}

resource "aws_lambda_function" "report" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${var.project}-daily-report"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      TEAM_EMAIL = var.team_email
      ENV        = var.environment
    }
  }
}

# EventBridge cron trigger (daily at 9 AM UTC)
resource "aws_cloudwatch_event_rule" "daily" {
  name                = "${var.project}-daily-report"
  schedule_expression = "cron(0 9 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.daily.name
  arn  = aws_lambda_function.report.arn
}

resource "aws_lambda_permission" "eventbridge" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
```

---

## Week 3 — FinOps & Security-Driven Projects

### Project: RDS Cost Analysis & Migration Automation
```python
#!/usr/bin/env python3
"""RDS cost analysis and optimization recommendations."""

import boto3
from datetime import datetime, timedelta

class RDSOptimizer:
    def __init__(self, region='us-east-1'):
        self.rds = boto3.client('rds', region_name=region)
        self.cw = boto3.client('cloudwatch', region_name=region)
        self.region = region

    def analyze_utilization(self, days=14):
        instances = self.rds.describe_db_instances()['DBInstances']
        recommendations = []

        for db in instances:
            db_id = db['DBInstanceIdentifier']
            db_class = db['DBInstanceClass']

            # Check average CPU over the period
            cpu = self.cw.get_metric_statistics(
                Namespace='AWS/RDS',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_id}],
                StartTime=datetime.utcnow() - timedelta(days=days),
                EndTime=datetime.utcnow(),
                Period=3600, Statistics=['Average']
            )

            avg_cpu = 0
            if cpu['Datapoints']:
                avg_cpu = sum(d['Average'] for d in cpu['Datapoints']) / len(cpu['Datapoints'])

            # Check connections
            conns = self.cw.get_metric_statistics(
                Namespace='AWS/RDS',
                MetricName='DatabaseConnections',
                Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_id}],
                StartTime=datetime.utcnow() - timedelta(days=days),
                EndTime=datetime.utcnow(),
                Period=3600, Statistics=['Maximum']
            )

            max_conns = max((d['Maximum'] for d in conns['Datapoints']), default=0)

            rec = {
                'instance': db_id,
                'class': db_class,
                'engine': db['Engine'],
                'multi_az': db['MultiAZ'],
                'avg_cpu': round(avg_cpu, 1),
                'max_connections': int(max_conns),
                'recommendations': []
            }

            if avg_cpu < 20:
                rec['recommendations'].append(f'DOWNSIZE: Avg CPU {avg_cpu}% — consider smaller instance')
            if avg_cpu > 80:
                rec['recommendations'].append(f'UPSIZE: Avg CPU {avg_cpu}% — instance under pressure')
            if not db['MultiAZ'] and db.get('DBInstanceStatus') == 'available':
                rec['recommendations'].append('ENABLE Multi-AZ for production workloads')
            if max_conns < 5:
                rec['recommendations'].append('LOW USAGE: Consider reserved instance or shutdown')

            recommendations.append(rec)

        return recommendations

if __name__ == '__main__':
    optimizer = RDSOptimizer()
    for rec in optimizer.analyze_utilization():
        print(f"\n{'='*50}")
        print(f"Instance: {rec['instance']} ({rec['class']})")
        print(f"Engine: {rec['engine']} | Multi-AZ: {rec['multi_az']}")
        print(f"Avg CPU: {rec['avg_cpu']}% | Max Connections: {rec['max_connections']}")
        for r in rec['recommendations']:
            print(f"  → {r}")
```

### Project: Inbound File Scanning with ClamAV on ECS
```python
# ClamAV Scanner — runs as ECS task triggered by S3 event
import boto3
import subprocess
import os
import logging

logger = logging.getLogger()
s3 = boto3.client('s3')
sns = boto3.client('sns')

QUARANTINE_BUCKET = os.environ['QUARANTINE_BUCKET']
CLEAN_BUCKET = os.environ['CLEAN_BUCKET']
ALERT_TOPIC = os.environ['ALERT_TOPIC_ARN']

def scan_file(bucket, key):
    """Download file from S3, scan with ClamAV, route accordingly."""
    local_path = f'/tmp/{os.path.basename(key)}'

    # Download
    s3.download_file(bucket, key, local_path)
    logger.info(f"Downloaded s3://{bucket}/{key}")

    # Scan with ClamAV
    result = subprocess.run(
        ['clamscan', '--no-summary', local_path],
        capture_output=True, text=True
    )

    if result.returncode == 0:
        # Clean — move to clean bucket
        s3.upload_file(local_path, CLEAN_BUCKET, key)
        s3.delete_object(Bucket=bucket, Key=key)
        logger.info(f"CLEAN: {key} → {CLEAN_BUCKET}")
        return {'status': 'clean', 'file': key}
    else:
        # Infected — quarantine
        s3.upload_file(local_path, QUARANTINE_BUCKET, f"quarantine/{key}")
        s3.delete_object(Bucket=bucket, Key=key)

        # Alert
        sns.publish(
            TopicArn=ALERT_TOPIC,
            Subject=f'MALWARE DETECTED: {key}',
            Message=f'ClamAV detected malware in {key}\nOutput: {result.stdout}'
        )
        logger.warning(f"INFECTED: {key} → quarantine")
        return {'status': 'infected', 'file': key, 'details': result.stdout}

    # Cleanup
    os.remove(local_path)
```

---

## Deliverables
- [ ] Python virtual environment with `requirements.txt`
- [ ] AWS resource creator CLI tool (boto3 + argparse)
- [ ] Cloud usage report generator
- [ ] REST API CRUD with `requests`
- [ ] Lambda: daily cloud report → SES email
- [ ] Lambda: IAM key rotation (EventBridge cron)
- [ ] Lambda: image processing pipeline with layers
- [ ] All Lambdas deployed with Terraform
- [ ] RDS cost analyzer with optimization recommendations
- [ ] ClamAV file scanner on ECS (Terraform deployed)
- [ ] Database migration automation with rollback
- [ ] CloudWatch monitoring for all Lambda functions
