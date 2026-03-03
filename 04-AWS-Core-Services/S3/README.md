# S3 — Simple Storage Service

> **S3 is the backbone of AWS storage. Every application, pipeline, and data lake uses S3.** Unlimited storage with 99.999999999% (11 9's) durability.

---

## Real-World Analogy

S3 is like a **massive, intelligent filing cabinet in the cloud**:
- **Bucket** = a labeled drawer (globally unique name)
- **Object** = a file inside the drawer (up to 5TB)
- **Key** = the file path/name (e.g., `images/photo.jpg`)
- **Storage classes** = different drawer materials (premium, standard, archive cold storage)
- **Versioning** = keeping every revision of every document
- **Lifecycle policies** = automatic rules like "move to basement storage after 30 days"

---

## Topics

### Core Concepts
- Buckets, objects, keys (prefixes), metadata
- Versioning — protect against accidental deletes
- Object Lock — WORM compliance
- **Consistency:** S3 provides strong read-after-write consistency for all operations

### Storage Classes

| Class | Availability | Min Storage | Retrieval | Cost (GB/mo) | Best For |
|-------|-------------|-------------|-----------|-------------|----------|
| **Standard** | 99.99% | None | Instant | $0.023 | Frequently accessed data |
| **Intelligent-Tiering** | 99.9% | None | Instant | $0.023 + monitoring | Unknown access patterns |
| **Standard-IA** | 99.9% | 30 days | Instant | $0.0125 + retrieval | Monthly access, backups |
| **One Zone-IA** | 99.5% | 30 days | Instant | $0.01 | Recreatable data |
| **Glacier Instant** | 99.9% | 90 days | Instant | $0.004 | Archive with instant access |
| **Glacier Flexible** | 99.99% | 90 days | 1-5 min to 12 hrs | $0.0036 | Compliance archives |
| **Glacier Deep Archive** | 99.99% | 180 days | 12-48 hours | $0.00099 | 7-10 year retention |

### Access Control (Layered Security)
```
Account Level: S3 Block Public Access (master switch)
     │
Bucket Level: Bucket Policy (resource-based, JSON)
     │
Object Level: ACLs (legacy — avoid), Object Ownership
     │
Access Points: Simplified policies for shared datasets
     │
IAM Level: IAM Policies (identity-based)
```

### Advanced Features
- **Lifecycle Policies** — transition between storage classes, expire objects
- **Pre-signed URLs** — temporary access (upload/download)
- **S3 Event Notifications** → Lambda / SQS / SNS / EventBridge
- **S3 Transfer Acceleration** — fast uploads via CloudFront edge
- **Cross-Region Replication (CRR)** — disaster recovery
- **Same-Region Replication (SRR)** — compliance, log aggregation
- **S3 Select / Glacier Select** — query data in place (SQL on S3)
- **Static Website Hosting** — serve HTML/CSS/JS directly
- **Multipart Upload** — required for files > 5GB, recommended > 100MB
- **S3 Object Lambda** — transform data on retrieval
- **S3 Batch Operations** — bulk operations on billions of objects

---

## Real-Time Example 1: Media Company — Cost Optimization with Lifecycle Policies

**Scenario:** Your media company stores 50TB of video content on S3. Analytics show:
- Videos < 30 days old: accessed frequently (streaming)
- Videos 30-90 days old: accessed occasionally (search results)
- Videos > 90 days: rarely accessed (archive)
- Videos > 1 year: never accessed but must keep for 7 years (legal)

**Current cost (all Standard): 50TB × $0.023 = $1,150/month**

```
         Upload              30 days             90 days            365 days
    ───────┼───────────────────┼──────────────────┼──────────────────┼──────────
           │                   │                  │                  │
    S3 Standard ──────▶ Standard-IA ──────▶ Glacier Instant ──▶ Glacier Deep
    ($0.023/GB)        ($0.0125/GB)        ($0.004/GB)         ($0.00099/GB)

    Estimated monthly cost after lifecycle:
    10TB × $0.023 + 15TB × $0.0125 + 15TB × $0.004 + 10TB × $0.00099
    = $230 + $187 + $60 + $9.90
    = $486.90/month (58% savings!)
```

```bash
# Lifecycle policy configuration
cat > lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "MediaLifecycle",
            "Status": "Enabled",
            "Filter": {"Prefix": "videos/"},
            "Transitions": [
                {"Days": 30, "StorageClass": "STANDARD_IA"},
                {"Days": 90, "StorageClass": "GLACIER_IR"},
                {"Days": 365, "StorageClass": "DEEP_ARCHIVE"}
            ]
        },
        {
            "ID": "DeleteTempUploads",
            "Status": "Enabled",
            "Filter": {"Prefix": "temp-uploads/"},
            "Expiration": {"Days": 3}
        },
        {
            "ID": "CleanupIncompleteUploads",
            "Status": "Enabled",
            "Filter": {},
            "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 7}
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket media-content-bucket \
    --lifecycle-configuration file://lifecycle.json
```

---

## Real-Time Example 2: Secure File Upload with Pre-signed URLs

**Scenario:** Your mobile app needs to upload user profile photos directly to S3 without routing through your backend server (which would be slow and expensive). Use pre-signed URLs.

```
┌──────────┐         ┌──────────────┐         ┌──────────┐
│  Mobile  │──(1)──▶│  Backend API  │         │    S3    │
│   App    │         │  (Lambda)     │         │  Bucket  │
│          │◀──(2)──│               │         │          │
│          │         └──────────────┘         │          │
│          │──────────(3) Direct Upload──────▶│          │
│          │                                   │          │
│          │◀─────────(4) S3 Event ──────────│          │
│          │               ↓                   │          │
│          │          Lambda: resize           │          │
│          │          + create thumbnail       │          │
└──────────┘                                   └──────────┘

(1) "I want to upload profile.jpg"
(2) Returns pre-signed URL (valid 5 minutes)
(3) App uploads directly to S3 (fast, no backend load)
(4) S3 triggers Lambda to create thumbnails
```

```bash
# Generate pre-signed URL for upload (valid 5 minutes)
aws s3 presign s3://user-uploads/profiles/user-123/photo.jpg \
    --expires-in 300

# Or using the API (more control):
# In your Lambda/backend:
# import boto3
# s3 = boto3.client('s3')
# url = s3.generate_presigned_url('put_object',
#     Params={'Bucket': 'user-uploads', 'Key': 'profiles/user-123/photo.jpg',
#             'ContentType': 'image/jpeg'},
#     ExpiresIn=300)

# S3 Event Notification to trigger thumbnail Lambda
aws s3api put-bucket-notification-configuration \
    --bucket user-uploads \
    --notification-configuration '{
        "LambdaFunctionConfigurations": [{
            "LambdaFunctionArn": "arn:aws:lambda:us-east-1:ACCT:function:create-thumbnail",
            "Events": ["s3:ObjectCreated:*"],
            "Filter": {
                "Key": {"FilterRules": [{"Name": "prefix", "Value": "profiles/"}]}
            }
        }]
    }'
```

---

## Real-Time Example 3: Data Lake with Cross-Region Replication

**Scenario:** Your analytics team builds a data lake on S3. Requirements:
1. All raw data lands in us-east-1 (primary)
2. Replicate to eu-west-1 for European analysts (GDPR compliance)
3. Different teams access different prefixes via S3 Access Points

```bash
# Step 1: Enable versioning (required for replication)
aws s3api put-bucket-versioning --bucket data-lake-primary \
    --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket data-lake-eu-replica \
    --versioning-configuration Status=Enabled

# Step 2: Create replication rule
cat > replication.json << 'EOF'
{
    "Role": "arn:aws:iam::ACCT:role/S3ReplicationRole",
    "Rules": [
        {
            "ID": "ReplicateToEU",
            "Status": "Enabled",
            "Priority": 1,
            "Filter": {},
            "Destination": {
                "Bucket": "arn:aws:s3:::data-lake-eu-replica",
                "StorageClass": "STANDARD_IA",
                "EncryptionConfiguration": {
                    "ReplicaKmsKeyID": "arn:aws:kms:eu-west-1:ACCT:key/eu-key-id"
                }
            },
            "SourceSelectionCriteria": {
                "SseKmsEncryptedObjects": {"Status": "Enabled"}
            },
            "DeleteMarkerReplication": {"Status": "Enabled"}
        }
    ]
}
EOF

aws s3api put-bucket-replication --bucket data-lake-primary \
    --replication-configuration file://replication.json

# Step 3: Create Access Points for different teams
aws s3control create-access-point \
    --account-id ACCT \
    --name analytics-team-ap \
    --bucket data-lake-primary \
    --vpc-configuration VpcId=vpc-xxxx

# Step 4: Access Point policy (analytics can only read their prefix)
cat > ap-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {"AWS": "arn:aws:iam::ACCT:role/AnalyticsTeamRole"},
        "Action": ["s3:GetObject", "s3:ListBucket"],
        "Resource": [
            "arn:aws:s3:us-east-1:ACCT:accesspoint/analytics-team-ap",
            "arn:aws:s3:us-east-1:ACCT:accesspoint/analytics-team-ap/object/analytics/*"
        ]
    }]
}
EOF
```

---

## Hands-On Labs

### Lab 1: Create Bucket with Versioning
```bash
BUCKET_NAME="devops-bootcamp-$(date +%s)"

aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1
aws s3api put-bucket-versioning --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Test versioning
echo "version 1" > test.txt && aws s3 cp test.txt s3://$BUCKET_NAME/test.txt
echo "version 2" > test.txt && aws s3 cp test.txt s3://$BUCKET_NAME/test.txt

# List versions
aws s3api list-object-versions --bucket $BUCKET_NAME --prefix test.txt
```

### Lab 2: Lifecycle Policy
```bash
cat > lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "TransitionToIA",
            "Status": "Enabled",
            "Filter": {"Prefix": "logs/"},
            "Transitions": [
                {"Days": 30, "StorageClass": "STANDARD_IA"},
                {"Days": 90, "StorageClass": "GLACIER"}
            ],
            "Expiration": {"Days": 365}
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket $BUCKET_NAME --lifecycle-configuration file://lifecycle.json
```

### Lab 3: Bucket Policy for Cross-Account Access
```bash
cat > bucket-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CrossAccountRead",
            "Effect": "Allow",
            "Principal": {"AWS": "arn:aws:iam::ACCOUNT_B_ID:root"},
            "Action": ["s3:GetObject", "s3:ListBucket"],
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME",
                "arn:aws:s3:::BUCKET_NAME/*"
            ]
        }
    ]
}
EOF
```

### Lab 4: Static Website with CloudFront
```bash
# Enable website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document error.html

# Upload website files
aws s3 sync ./website/ s3://$BUCKET_NAME/

# Create CloudFront OAC (Origin Access Control) for secure access
aws cloudfront create-origin-access-control --origin-access-control-config '{
    "Name": "S3-OAC",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "always",
    "SigningProtocol": "sigv4"
}'
```

---

## S3 Security Checklist

| Check | Command | Why |
|-------|---------|-----|
| Block public access | `aws s3api put-public-access-block` | Prevent data leaks |
| Enable versioning | `aws s3api put-bucket-versioning` | Protect against deletes |
| Enable encryption | `aws s3api put-bucket-encryption` | Data at rest security |
| Enable access logging | `aws s3api put-bucket-logging` | Audit trail |
| Enable MFA delete | Requires root account | Prevent version deletion |
| Lock down bucket policy | Explicit deny for unwanted actions | Defense in depth |

---

## Interview Questions

1. **What are S3 storage classes and how do you choose?**
   > 7 classes from hot to cold. Standard for frequent access, Intelligent-Tiering for unknown patterns (auto-moves between tiers), Standard-IA for monthly access, Glacier Instant for rare but immediate access, Deep Archive for ~$1/TB/month long-term. Choose based on access frequency, retrieval time requirements, and minimum storage duration.

2. **How do lifecycle policies work?**
   > Rules that automatically transition objects between storage classes or expire them. Example: Move logs to IA after 30 days, Glacier after 90 days, delete after 365 days. Also handles: deleting incomplete multipart uploads, expiring old versions. Saves significant cost without manual intervention.

3. **Bucket policy vs IAM policy — when to use which?**
   > **Bucket policy** (resource-based): when you need cross-account access, want to enforce conditions on the bucket itself (like "only from VPC"), or need public access. **IAM policy** (identity-based): when managing what specific users/roles can do across multiple resources. They work together — both must allow access (unless same account where either can grant).

4. **How to secure an S3 bucket for production?**
   > (1) Enable S3 Block Public Access at account level, (2) Enable versioning + MFA Delete, (3) Enable default encryption (SSE-S3 or SSE-KMS), (4) Use bucket policy with least privilege, (5) Enable access logging, (6) Use VPC endpoints for private access, (7) Enable Object Lock for compliance, (8) Use IAM Access Analyzer.

5. **What is S3 Transfer Acceleration?**
   > Uses CloudFront edge locations to speed up uploads. Client uploads to nearest edge location, then AWS backbone (much faster than public internet) transfers to the bucket region. Costs extra $0.04-0.08/GB. Use when uploading from far away (e.g., Asia users uploading to us-east-1). Can improve upload speed by 50-500%.

6. **How does Cross-Region Replication work?**
   > Requires versioning on both buckets. Replicates new objects asynchronously (usually < 15 min, 99.99% within 15 min with RTC). Can replicate to different storage class, different account, change ownership. Use cases: DR, compliance (data sovereignty), latency reduction. Costs: storage in destination + data transfer.

7. **What are pre-signed URLs and when to use them?**
   > Temporary URLs with embedded authentication. Generated by someone with S3 access, shared with anyone (no AWS credentials needed). Use for: direct file uploads from browsers/mobile (bypass backend), temporary download links, sharing files with external partners. Default expiry: up to 7 days (IAM user) or 12 hours (IAM role).

8. **How to host a static website on S3 with CloudFront?**
   > (1) Create bucket, upload HTML/CSS/JS, (2) Enable static website hosting, (3) Create CloudFront distribution with S3 as origin, (4) Use Origin Access Control (OAC) so only CloudFront can read the bucket (keep bucket private), (5) Add custom domain with Route53 + ACM certificate. Benefits: global CDN, HTTPS, caching, DDoS protection via Shield.
