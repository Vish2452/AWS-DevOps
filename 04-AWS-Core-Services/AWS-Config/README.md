# AWS Config — Configuration Compliance & Audit

> Continuously monitor and record AWS resource configurations. Detect non-compliant resources and auto-remediate.

---

## Real-World Analogy

AWS Config is like a **building code inspector**:
- Continuously inspects every room (resource) in your building (account)
- Checks against building codes (Config rules): fire exits, sprinklers, electrical standards
- Records every change made to any room (configuration history)
- Can auto-fix violations (auto-remediation): found an open window? Close it automatically
- Provides a full timeline of changes for any room

---

## Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Configuration Recorder** | Records all resource configs | "Track all EC2, S3, IAM changes" |
| **Config Rules** | Compliance checks | "S3 buckets must have encryption" |
| **Managed Rules** | AWS pre-built rules (300+) | `s3-bucket-public-read-prohibited` |
| **Custom Rules** | Lambda-based custom checks | "All EC2 must have tag CostCenter" |
| **Conformance Packs** | Group of rules (compliance framework) | PCI-DSS, HIPAA, CIS Benchmarks |
| **Remediation** | Auto-fix non-compliant resources | "If S3 public → make private automatically" |
| **Configuration Timeline** | History of resource changes | "Who changed this SG at 3 AM?" |
| **Aggregator** | Multi-account/region view | Central compliance dashboard |

---

## Real-Time Example 1: Security Compliance Automation

**Scenario:** Your security team requires: S3 buckets must be encrypted, EBS volumes must be encrypted, security groups must not allow 0.0.0.0/0 on port 22. Auto-remediate violations.

```
┌─────────────────────────────────────────────────────────────┐
│              AWS Config Compliance Flow                       │
│                                                              │
│  Resource Change → Config detects → Evaluate rule            │
│                                     │                        │
│                          ┌──────────┼──────────┐             │
│                          │                     │             │
│                    COMPLIANT              NON-COMPLIANT       │
│                    (✅ log it)           (❌ trigger fix)     │
│                                              │               │
│                                     Auto-Remediation         │
│                                     (SSM Automation)         │
│                                              │               │
│                                     Fix + notify via SNS     │
└─────────────────────────────────────────────────────────────┘
```

```bash
# Enable Config
aws configservice put-configuration-recorder --configuration-recorder '{
    "name": "default",
    "roleARN": "arn:aws:iam::ACCT:role/AWSConfigRole",
    "recordingGroup": {
        "allSupported": true,
        "includeGlobalResourceTypes": true
    }
}'

aws configservice put-delivery-channel --delivery-channel '{
    "name": "default",
    "s3BucketName": "config-logs-bucket",
    "snsTopicARN": "arn:aws:sns:us-east-1:ACCT:config-alerts",
    "configSnapshotDeliveryProperties": {"deliveryFrequency": "Six_Hours"}
}'

aws configservice start-configuration-recorder --configuration-recorder-name default

# Rule 1: S3 buckets must have encryption
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "s3-encryption-required",
    "Source": {
        "Owner": "AWS",
        "SourceIdentifier": "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    },
    "Scope": {"ComplianceResourceTypes": ["AWS::S3::Bucket"]}
}'

# Rule 2: EBS volumes must be encrypted
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "ebs-encryption-required",
    "Source": {
        "Owner": "AWS",
        "SourceIdentifier": "ENCRYPTED_VOLUMES"
    }
}'

# Rule 3: No SSH from 0.0.0.0/0
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "no-unrestricted-ssh",
    "Source": {
        "Owner": "AWS",
        "SourceIdentifier": "INCOMING_SSH_DISABLED"
    }
}'

# Auto-remediation: Block public S3 buckets automatically
aws configservice put-remediation-configurations --remediation-configurations '[{
    "ConfigRuleName": "s3-encryption-required",
    "TargetType": "SSM_DOCUMENT",
    "TargetId": "AWS-EnableS3BucketEncryption",
    "Parameters": {
        "BucketName": {"ResourceValue": {"Value": "RESOURCE_ID"}},
        "SSEAlgorithm": {"StaticValue": {"Values": ["AES256"]}}
    },
    "Automatic": true,
    "MaximumAutomaticAttempts": 3,
    "RetryAttemptSeconds": 60
}]'
```

---

## Real-Time Example 2: Investigate Security Incident

**Scenario:** At 3 AM, someone modified a production security group to allow all traffic (0.0.0.0/0). Use Config to investigate.

```bash
# Who changed the security group and when?
aws configservice get-resource-config-history \
    --resource-type AWS::EC2::SecurityGroup \
    --resource-id sg-xxxx \
    --limit 10

# Returns timeline:
# 3:02 AM - Configuration changed: Added rule 0.0.0.0/0 port 0-65535
# 2:58 AM - Previous compliant configuration
# Shows: WHO (via CloudTrail correlation), WHAT changed, WHEN

# Check all non-compliant resources right now
aws configservice get-compliance-details-by-config-rule \
    --config-rule-name no-unrestricted-ssh \
    --compliance-types NON_COMPLIANT
```

---

## Real-Time Example 3: Multi-Account Compliance Dashboard

**Scenario:** You manage 20 AWS accounts via AWS Organizations. Need a single dashboard showing compliance across all accounts.

```bash
# Create aggregator in central account
aws configservice put-configuration-aggregator \
    --configuration-aggregator-name "OrgAggregator" \
    --organization-aggregation-source '{
        "RoleArn": "arn:aws:iam::ACCT:role/ConfigOrgRole",
        "AllAwsRegions": true
    }'

# Query aggregate compliance
aws configservice get-aggregate-compliance-details-by-config-rule \
    --configuration-aggregator-name "OrgAggregator" \
    --config-rule-name s3-encryption-required \
    --compliance-type NON_COMPLIANT \
    --account-id 222222222222
```

---

## Essential Config Rules for DevOps

| Rule | What It Checks | Remediation |
|------|---------------|-------------|
| `s3-bucket-public-read-prohibited` | No public S3 buckets | Enable block public access |
| `encrypted-volumes` | EBS volumes encrypted | Enable default encryption |
| `incoming-ssh-disabled` | No SSH from 0.0.0.0/0 | Remove the SG rule |
| `rds-instance-public-access-check` | No public RDS | Modify to private |
| `iam-root-access-key-check` | No root access keys | Delete root keys |
| `multi-region-cloud-trail-enabled` | CloudTrail active | Enable CloudTrail |
| `vpc-flow-logs-enabled` | VPC flow logs active | Enable flow logs |
| `required-tags` | Resources have required tags | Auto-tag |

---

## Labs

### Lab 1: Enable Config and Add Rules
```bash
# Enable Config (as shown above)
# Add compliance rules
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "required-tags",
    "Source": {"Owner": "AWS", "SourceIdentifier": "REQUIRED_TAGS"},
    "InputParameters": "{\"tag1Key\": \"Environment\", \"tag2Key\": \"CostCenter\"}"
}'

# Check compliance
aws configservice describe-compliance-by-config-rule
```

### Lab 2: Conformance Pack (CIS Benchmark)
```bash
# Deploy CIS AWS Foundations Benchmark
aws configservice put-conformance-pack \
    --conformance-pack-name "CIS-Benchmark" \
    --template-s3-uri s3://config-templates/cis-benchmark.yaml

# Check pack compliance
aws configservice get-conformance-pack-compliance-summary \
    --conformance-pack-names "CIS-Benchmark"
```

---

## Interview Questions

1. **What is AWS Config and how is it different from CloudTrail?**
   > **AWS Config:** Records WHAT the resource configuration looks like at any point in time. Evaluates compliance rules. Shows configuration timeline. **CloudTrail:** Records WHO made WHAT API call and WHEN. Together: CloudTrail tells you "Alice called ModifySecurityGroup at 3 AM," Config shows you "Before and after the security group configuration."

2. **How does auto-remediation work?**
   > When a resource is non-compliant, Config can trigger an SSM Automation document to fix it automatically. Example: S3 bucket without encryption → auto-enable encryption. Set MaximumAutomaticAttempts and RetryAttemptSeconds. Always test remediation in dev first.

3. **What are conformance packs?**
   > Pre-packaged collections of Config rules and remediation actions for specific compliance frameworks (PCI-DSS, HIPAA, CIS Benchmarks, SOC2). Deploy a pack → get dozens of rules configured automatically. Can create custom packs for your organization's standards.

4. **How to use Config across multiple accounts?**
   > Enable Config Aggregator in a central account. Use AWS Organizations integration for automatic enrollment. Central account sees compliance status across all accounts and regions in one dashboard. Each account still needs Config enabled locally.

5. **What is the configuration timeline?**
   > A complete history of every configuration change for a resource. Shows: who changed it (via CloudTrail), what changed (old vs new config), when it changed, and compliance status at each point. Essential for incident investigation and audit.

6. **How does Config handle cost?**
   > $0.003 per configuration item recorded. $0.001 per rule evaluation per resource. Cost can grow with many resources and rules. Optimize: record only necessary resource types, use periodic rules (vs change-triggered) for non-critical checks, aggregate in fewer regions.
