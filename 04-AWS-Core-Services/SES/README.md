# SES — Simple Email Service

> Scalable email sending and receiving. Transactional emails, marketing campaigns, and notifications at scale. The "post office" of AWS.

---

## Real-World Analogy

SES is like a **high-tech post office**:
- You write a letter (compose email)
- Hand it to the post office (SES API/SMTP)
- They handle delivery, tracking, and return-to-sender
- They manage your reputation (IP warming, bounce handling)
- You get delivery reports (open rates, bounces, complaints)

---

## How SES Works

```
Your Application
      │
      ├── API (aws ses send-email)
      │   or
      ├── SMTP (smtp.amazonaws.com:587)
      │
      ▼
┌──────────────┐     ┌──────────┐     ┌───────────┐
│     SES      │────▶│ Content  │────▶│ Recipient │
│  (accepts)   │     │ Filter   │     │  Mail     │
│              │     │ (spam,   │     │  Server   │
│              │     │  virus)  │     │           │
└──────────────┘     └──────────┘     └───────────┘
      │
      ▼
┌──────────────┐
│ Notifications│
│ (SNS/S3/     │
│  CloudWatch) │
│ - Bounces    │
│ - Complaints │
│ - Deliveries │
└──────────────┘
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Verified Identity** | Email address or domain you've proven you own |
| **Sandbox Mode** | Default: can only send to verified addresses (request production access) |
| **Sending Quota** | Max emails/day and emails/second (starts at 200/day in sandbox) |
| **Configuration Set** | Group of rules for tracking opens, clicks, bounces |
| **Dedicated IP** | Your own IP address for sending (better reputation control) |
| **IP Warming** | Gradual increase of sending volume on new IPs |
| **Suppression List** | Automatically stops sending to addresses that bounced/complained |
| **DKIM** | DomainKeys Identified Mail — email authentication |
| **SPF** | Sender Policy Framework — authorize SES to send on your behalf |
| **DMARC** | Domain-based Message Authentication — policy for failed auth |

---

## Real-Time Example 1: Transactional Email Pipeline

**Scenario:** E-commerce platform sends order confirmations, shipping notifications, and password resets.

```bash
# Step 1: Verify domain
aws ses verify-domain-identity --domain mycompany.com

# Get DKIM tokens and add to Route53
aws ses get-identity-dkim-attributes --identities mycompany.com

# Step 2: Create configuration set for tracking
aws sesv2 create-configuration-set \
    --configuration-set-name transactional-emails

# Add SNS event destination for bounces and complaints
aws sesv2 create-configuration-set-event-destination \
    --configuration-set-name transactional-emails \
    --event-destination-name bounce-handler \
    --event-destination '{
      "Enabled": true,
      "MatchingEventTypes": ["BOUNCE", "COMPLAINT"],
      "SnsDestination": {
        "TopicArn": "arn:aws:sns:us-east-1:ACCT:email-bounces"
      }
    }'

# Step 3: Send email via CLI
aws ses send-email \
    --from "orders@mycompany.com" \
    --destination '{"ToAddresses":["customer@example.com"]}' \
    --message '{
      "Subject": {"Data": "Order Confirmed #12345"},
      "Body": {
        "Html": {
          "Data": "<h1>Thank you!</h1><p>Your order #12345 has been confirmed.</p>"
        }
      }
    }'
```

```python
# Python boto3 example for transactional emails
import boto3

ses = boto3.client('ses', region_name='us-east-1')

def send_order_confirmation(to_email, order_id, items):
    response = ses.send_templated_email(
        Source='orders@mycompany.com',
        Destination={'ToAddresses': [to_email]},
        Template='OrderConfirmation',
        TemplateData=json.dumps({
            'order_id': order_id,
            'items': items,
            'total': sum(i['price'] for i in items)
        }),
        ConfigurationSetName='transactional-emails'
    )
    return response['MessageId']
```

---

## Real-Time Example 2: DevOps Alert Emails

**Scenario:** Send formatted alert emails when infrastructure issues are detected.

```python
# Lambda function: send SES email on CloudWatch alarm
import boto3
import json

ses = boto3.client('ses')

def lambda_handler(event, context):
    # Parse SNS message from CloudWatch alarm
    message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = message['AlarmName']
    reason = message['NewStateReason']
    
    ses.send_email(
        Source='alerts@mycompany.com',
        Destination={
            'ToAddresses': ['devops-team@mycompany.com']
        },
        Message={
            'Subject': {
                'Data': f'🚨 ALARM: {alarm_name}'
            },
            'Body': {
                'Html': {
                    'Data': f'''
                    <h2 style="color:red">⚠️ CloudWatch Alarm Triggered</h2>
                    <table border="1" cellpadding="8">
                        <tr><td><b>Alarm</b></td><td>{alarm_name}</td></tr>
                        <tr><td><b>Reason</b></td><td>{reason}</td></tr>
                        <tr><td><b>Region</b></td><td>{message.get("Region","")}</td></tr>
                        <tr><td><b>Time</b></td><td>{message.get("StateChangeTime","")}</td></tr>
                    </table>
                    <p><a href="https://console.aws.amazon.com/cloudwatch/">View in CloudWatch</a></p>
                    '''
                }
            }
        }
    )
```

---

## Real-Time Example 3: Bulk Marketing with Templates

**Scenario:** Send personalized marketing emails to 100,000 subscribers using SES templates.

```bash
# Create email template
aws ses create-template --template '{
  "TemplateName": "WeeklySale",
  "SubjectPart": "{{name}}, check out this weeks deals!",
  "HtmlPart": "<h1>Hi {{name}}!</h1><p>Here are deals just for you in {{city}}:</p><ul>{{#each deals}}<li>{{this.item}} - {{this.price}}</li>{{/each}}</ul>",
  "TextPart": "Hi {{name}}, check our deals at mycompany.com/sale"
}'

# Send bulk using SES v2 (handles throttling)
aws sesv2 send-bulk-email \
    --from-email-address marketing@mycompany.com \
    --default-content '{
      "Template": {
        "TemplateName": "WeeklySale"
      }
    }' \
    --bulk-email-entries '[
      {"Destination":{"ToAddresses":["user1@example.com"]},"ReplacementEmailContent":{"ReplacementTemplate":{"ReplacementTemplateData":"{\"name\":\"Alice\",\"city\":\"NYC\"}"}}},
      {"Destination":{"ToAddresses":["user2@example.com"]},"ReplacementEmailContent":{"ReplacementTemplate":{"ReplacementTemplateData":"{\"name\":\"Bob\",\"city\":\"LA\"}"}}}
    ]'
```

---

## SES via SMTP (for existing applications)

```bash
# SMTP Configuration:
# Server: email-smtp.us-east-1.amazonaws.com
# Port: 587 (TLS) or 465 (SSL)
# Username/Password: generate SMTP credentials in SES console

# Create SMTP credentials
aws ses create-smtp-credentials --iam-user-name ses-smtp-user

# Test with swaks
swaks --to test@example.com \
    --from sender@mycompany.com \
    --server email-smtp.us-east-1.amazonaws.com \
    --port 587 \
    --tls \
    --auth-user SMTP_USER \
    --auth-password SMTP_PASS
```

---

## Labs

### Lab 1: Verify Identity and Send First Email
```bash
# Verify an email address
aws ses verify-email-identity --email-address your-email@gmail.com
# Check verification status
aws ses get-identity-verification-attributes --identities your-email@gmail.com
# Send a test email (sandbox: to/from must be verified)
aws ses send-email --from your-email@gmail.com --destination '{"ToAddresses":["your-email@gmail.com"]}' --message '{"Subject":{"Data":"SES Test"},"Body":{"Text":{"Data":"Hello from SES!"}}}'
```

### Lab 2: Create and Use Email Templates
```bash
# Create a template with variables
# Send templated email with replacement data
# Update template and resend
# List and delete templates
```

### Lab 3: Set Up Bounce and Complaint Handling
```bash
# Create SNS topic for bounces
# Create configuration set with event destination
# Create Lambda to process bounce notifications
# Update suppression list based on bounces
# Monitor sending statistics
aws ses get-send-statistics
aws ses get-send-quota
```

---

## Interview Questions

1. **What is SES and when would you use it?**
   → Scalable email service for transactional, notification, and marketing emails. Use when your application needs to send emails at scale with delivery tracking.

2. **What is SES Sandbox mode?**
   → Default restriction: only send to verified email addresses, 200 emails/day limit. Must request production access (provide use case, expected volume, bounce handling plan).

3. **How do you improve email deliverability?**
   → Verify domain with DKIM, SPF, DMARC. Use dedicated IPs with proper warming. Handle bounces/complaints promptly. Maintain clean mailing lists.

4. **SES vs SNS for notifications — which to use?**
   → SES: rich HTML emails, marketing, transactional. SNS: simple notifications to multiple channels (email, SMS, Lambda, SQS). Use SNS for alerts, SES for formatted emails.

5. **How does SES handle bounces and complaints?**
   → Configuration sets with SNS/CloudWatch/Firehose destinations. Automatic suppression list. Hard bounces remove addresses. Complaints from ISPs tracked.

6. **Can SES receive emails?**
   → Yes. Create receipt rules in SES to receive emails on verified domains. Actions: Lambda, S3, SNS, WorkMail. Used for support tickets, auto-processing.

7. **What is DKIM and why is it important?**
   → DomainKeys Identified Mail — cryptographic signature proving email came from your domain. Prevents spoofing, improves deliverability. SES generates DKIM keys automatically.

8. **How do you send bulk emails efficiently with SES?**
   → Use `SendBulkTemplatedEmail` API, templates with variables, respect sending quota, implement exponential backoff, monitor bounce/complaint rates (keep below 5%/0.1%).
