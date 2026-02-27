# 21 AWS Practical Scenarios

> Each scenario is a real-world task commonly encountered in DevOps roles and asked in interviews.

## Scenarios

### 1. Automated Cross-Region Backup
**Services:** AWS Backup, S3, RDS Snapshots
- Configure AWS Backup plan with cross-region copy to eu-west-1
- Set up RDS automated snapshots with 7-day retention
- S3 Cross-Region Replication for static assets

### 2. AWS Cost Optimization
**Services:** Cost Explorer, Trusted Advisor, Shell Script
- Use Cost Explorer to identify top spending services
- Run Trusted Advisor checks for idle resources
- Automate with cost-optimizer.sh from Module 2

### 3. Bastion Host (Jump Server) Setup
**Services:** EC2, VPC, Security Groups, SSH
- Deploy bastion in public subnet
- Allow SSH only from corporate IP
- SSH agent forwarding to private instances
- Alternative: AWS Systems Manager Session Manager

### 4. Cross-Account EC2 to RDS Access
**Services:** VPC Peering, IAM Role Switching, Security Groups
- Account A: EC2 in VPC-A (10.0.0.0/16)
- Account B: RDS in VPC-B (10.1.0.0/16)
- VPC Peering connection between accounts
- Security group rules for cross-VPC access

### 5. Scalable NLB with Route53 & SSL
**Services:** NLB, ASG, ACM, Route 53
- NLB in public subnets with Elastic IPs
- ASG behind NLB with target tracking scaling
- Route 53 alias record to NLB
- ACM certificate for TLS termination

### 6. VPN Gateway vs Direct Connect
**Services:** VPN, Site-to-Site comparison
- Set up Site-to-Site VPN with virtual private gateway
- Compare with Direct Connect (cost, latency, bandwidth)
- Use case analysis for each option

### 7. EBS vs EFS — Shared Storage Demo
**Services:** EBS, EFS, EC2
- Mount EBS volume on single EC2
- Mount EFS on 3 EC2 instances simultaneously
- Performance comparison test

### 8. ECR + ECS Container Deployment
**Services:** ECR, ECS Fargate, ALB
- Push Docker image to ECR
- Create ECS Fargate service with ALB
- Auto scaling based on CPU utilization

### 9. Serverless Banking Application
**Services:** API Gateway, Lambda, S3, DynamoDB, CloudFormation
- REST API with Lambda backend
- DynamoDB for account data
- S3 for static frontend
- Full serverless architecture

### 10. Private vs Public IP Identification
**Services:** VPC, EC2
- Launch EC2 in public and private subnets
- Verify public IP assignment and private IP allocation
- `curl ifconfig.me` vs `hostname -I`

### 11. IAM Policy Design
**Services:** IAM, S3, Policy Simulator
- Design least-privilege policies for dev team
- Use IAM Policy Simulator to test
- Implement permission boundaries

### 12. IAM Cross-Account Role Switching
**Services:** IAM, STS, AWS Organizations
- Create role in Account B trusting Account A
- Switch role using AWS Console and CLI
- Implement with external ID for security

### 13. KMS Encryption Demo
**Services:** KMS, S3, EBS
- Create CMK and encrypt S3 bucket
- Encrypt EBS volumes with same key
- Key policy management

### 14. Multi-Region Transit Gateway
**Services:** Transit Gateway, VPC, Route Tables
- 3 VPCs connected via Transit Gateway
- Cross-region peering (us-east-1 ↔ eu-west-1)
- Centralized routing management

### 15. NAT Gateway Setup
**Services:** VPC, NAT-GW, Private Subnets
- Deploy NAT Gateway in public subnet
- Configure route table for private subnet
- Verify internet connectivity from private EC2

### 16. VPC Flow Logs Analysis
**Services:** VPC, CloudWatch Logs, Athena
- Enable VPC Flow Logs to CloudWatch and S3
- Query with CloudWatch Insights
- Analyze with Athena SQL queries

### 17. VPC Endpoints for S3
**Services:** VPC, Gateway Endpoint, S3
- Create Gateway endpoint for S3
- Update route table automatically
- Verify private access to S3 (no internet)

### 18. Static Website on S3 + CloudFront
**Services:** S3, CloudFront, Route 53, ACM
- Host static site on S3
- CloudFront distribution with OAC
- Custom domain with ACM certificate
- Route 53 alias record

### 19. IP Ranges & CIDR Design
**Services:** VPC, Subnets
- Design CIDR for production VPC (non-overlapping)
- Calculate subnet sizes for different tiers
- Plan for future expansion

### 20. S3 Bucket Policy Access Control
**Services:** IAM, S3 Bucket Policy
- Restrict access to specific IAM role
- Allow cross-account read access
- Deny all except VPC endpoint

### 21. ASG with SNS Notifications
**Services:** ASG, SNS, CloudWatch
- ASG with scaling notifications to email
- CloudWatch alarm triggers scaling
- Full alert chain: metric → alarm → SNS → email
