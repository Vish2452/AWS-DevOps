# KMS — Key Management Service

> Centralized key management for encryption across AWS services.

## Key Types
| Type | Management | Rotation | Use Case |
|------|-----------|----------|----------|
| **AWS Managed** | AWS | Auto (yearly) | Default service encryption |
| **Customer Managed (CMK)** | You | Configurable | Custom encryption requirements |
| **AWS Owned** | AWS | Internal | Shared across accounts |

## Envelope Encryption
```
Data Key (plaintext) → encrypts your data
KMS Master Key → encrypts the Data Key
Store: encrypted data + encrypted Data Key
Decrypt: KMS decrypts Data Key → Data Key decrypts data
```

## KMS Integration
- **S3** — server-side encryption (SSE-KMS)
- **EBS** — volume encryption
- **RDS** — database encryption at rest
- **Secrets Manager** — secret encryption
- **Lambda** — environment variable encryption
- **CloudTrail** — log encryption

## Labs
```bash
# Create CMK
KEY_ID=$(aws kms create-key \
    --description "Application encryption key" \
    --key-usage ENCRYPT_DECRYPT \
    --query 'KeyMetadata.KeyId' --output text)

aws kms create-alias --alias-name alias/app-key --target-key-id $KEY_ID

# Encrypt data
aws kms encrypt --key-id alias/app-key \
    --plaintext fileb://secret.txt \
    --output text --query CiphertextBlob | base64 --decode > secret.encrypted

# Enable auto-rotation
aws kms enable-key-rotation --key-id $KEY_ID
```
