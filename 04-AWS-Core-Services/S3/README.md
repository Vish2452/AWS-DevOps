# S3 — Simple Storage Service

> **S3 is the backbone of AWS storage. Every application, pipeline, and data lake uses S3.**

## Topics

### Core Concepts
- Buckets, objects, keys (prefixes), metadata
- Versioning — protect against accidental deletes
- Object Lock — WORM compliance

### Storage Classes
| Class | Use Case | Retrieval | Cost |
|-------|----------|-----------|------|
| **Standard** | Frequently accessed | Instant | Highest |
| **Intelligent-Tiering** | Unknown access patterns | Instant | Auto-optimized |
| **Standard-IA** | Infrequent access | Instant | Lower + retrieval fee |
| **One Zone-IA** | Infrequent, non-critical | Instant | Lowest IA |
| **Glacier Instant** | Archive with instant access | Instant | Low |
| **Glacier Flexible** | Archive | Minutes to hours | Very low |
| **Glacier Deep Archive** | Long-term archive | 12-48 hours | Cheapest |

### Access Control
- **IAM Policies** — user/role-based access
- **Bucket Policies** — resource-based, cross-account
- **ACLs** — legacy (avoid in new projects)
- **Access Points** — simplified access for shared datasets
- **Block Public Access** — account-level or bucket-level guard

### Advanced Features
- **Lifecycle Policies** — transition between storage classes, expire objects
- **Pre-signed URLs** — temporary access (upload/download)
- **S3 Event Notifications** → Lambda / SQS / SNS
- **S3 Transfer Acceleration** — fast uploads via CloudFront edge
- **Cross-Region Replication (CRR)** — disaster recovery
- **Same-Region Replication (SRR)** — compliance, log aggregation
- **S3 Select / Glacier Select** — query data in place
- **Static Website Hosting** — serve HTML/CSS/JS directly

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

### Lab 4: Static Website Hosting
```bash
# Enable website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document error.html

# Upload website files
aws s3 sync ./website/ s3://$BUCKET_NAME/ --acl public-read

# Integrate with CloudFront for HTTPS
```

---

## Interview Questions
1. What are S3 storage classes and how do you choose?
2. How do lifecycle policies work?
3. Bucket policy vs IAM policy — when to use which?
4. How to secure an S3 bucket for production?
5. What is S3 Transfer Acceleration?
6. How does Cross-Region Replication work?
7. What are pre-signed URLs and when to use them?
8. How to host a static website on S3 with CloudFront?
