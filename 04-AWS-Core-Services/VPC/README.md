# VPC — Virtual Private Cloud

> **Every AWS architecture lives inside a VPC. Networking is the #1 technical interview topic for DevOps.** A VPC is your own isolated section of the AWS cloud.

---

## Real-World Analogy

A VPC is like building your own **corporate office campus**:
- **VPC** = The entire campus with a fence (your private network)
- **Subnets** = Buildings within the campus (public-facing lobby, private offices, secure data room)
- **Route Tables** = Road signs directing traffic between buildings
- **Internet Gateway** = The main gate connecting campus to the public road
- **NAT Gateway** = A mail room — internal staff can send mail out, but outsiders can't walk in
- **Security Groups** = Door locks on each room (stateful — if you enter, you can exit)
- **NACLs** = Security checkpoints at building entrances (stateless — check both entry and exit)
- **VPC Peering** = A private walkway between two campuses
- **Transit Gateway** = A central hub connecting ALL campuses

---

## Topics

### VPC Components
- **VPC** — isolated network in AWS (default: 172.31.0.0/16)
- **Subnets** — public (internet-facing) vs private (internal only)
- **Route Tables** — traffic routing rules
- **Internet Gateway (IGW)** — allows public internet access
- **NAT Gateway** — allows private subnets to access internet (outbound only)
- **Elastic IP** — static public IP address

### Security
- **Security Groups** — stateful firewall at instance level
- **Network ACLs** — stateless firewall at subnet level
- **VPC Flow Logs** — capture network traffic for analysis

### Security Groups vs NACLs

| Feature | Security Group | Network ACL |
|---------|---------------|-------------|
| **Level** | Instance (ENI) | Subnet |
| **State** | Stateful (return traffic auto-allowed) | Stateless (must allow both directions) |
| **Rules** | Allow only | Allow AND Deny |
| **Evaluation** | All rules evaluated | Rules evaluated in order (lowest # first) |
| **Default** | Deny all inbound, Allow all outbound | Allow all inbound and outbound |
| **Applies to** | Only instances assigned to it | All instances in the subnet |

### Connectivity
- **VPC Peering** — connect two VPCs (no transitive routing)
- **Transit Gateway** — hub-and-spoke for multiple VPCs
- **VPC Endpoints** — private access to AWS services
  - Gateway Endpoints: S3, DynamoDB (free)
  - Interface Endpoints: all other services (PrivateLink, ~$7.20/month + data)
- **VPN Gateway** — encrypted tunnel to on-premises
- **Direct Connect** — dedicated physical connection (1/10/100 Gbps)
- **Bastion Host / Session Manager** — secure access to private instances

### CIDR Design for Production
```
Production VPC:     10.0.0.0/16   (65,536 IPs)
│
├── Public Subnets (Load Balancers, Bastion)
│   ├── 10.0.1.0/24   (251 usable IPs) — AZ-a
│   ├── 10.0.2.0/24   (251 usable IPs) — AZ-b
│   └── 10.0.3.0/24   (251 usable IPs) — AZ-c
│
├── Private Subnets (Application Servers, ECS/EKS)
│   ├── 10.0.10.0/24  (251 usable IPs) — AZ-a
│   ├── 10.0.20.0/24  (251 usable IPs) — AZ-b
│   └── 10.0.30.0/24  (251 usable IPs) — AZ-c
│
├── Database Subnets (RDS, ElastiCache)
│   ├── 10.0.100.0/24 (251 usable IPs) — AZ-a
│   ├── 10.0.200.0/24 (251 usable IPs) — AZ-b
│   └── 10.0.201.0/24 (251 usable IPs) — AZ-c
│
└── Reserved for future (10.0.40.0/24 – 10.0.99.0/24)

Note: AWS reserves 5 IPs per subnet (first 4 + last 1)
      /24 = 256 total - 5 reserved = 251 usable
```

---

## Real-Time Example 1: 3-Tier Application VPC Architecture

**Scenario:** Deploy a production e-commerce application with web servers, application servers, and databases. Full HA across 3 AZs.

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │     IGW     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
    ┌─────────▼────┐  ┌───▼──────┐  ┌──▼─────────┐
    │ Public Sub-a │  │Public-b  │  │ Public-c   │
    │ 10.0.1.0/24  │  │10.0.2.0  │  │10.0.3.0   │
    │   [ALB]      │  │  [ALB]   │  │  [ALB]     │
    │   [NAT GW]   │  │          │  │            │
    └──────┬───────┘  └────┬─────┘  └─────┬──────┘
           │               │              │
    ┌──────▼───────┐  ┌────▼─────┐  ┌─────▼──────┐
    │Private Sub-a │  │Private-b │  │ Private-c  │
    │ 10.0.10.0/24 │  │10.0.20.0 │  │10.0.30.0  │
    │   [App EC2]  │  │ [App EC2]│  │ [App EC2]  │
    │   [ECS Tasks]│  │ [ECS]    │  │ [ECS]      │
    └──────┬───────┘  └────┬─────┘  └─────┬──────┘
           │               │              │
    ┌──────▼───────┐  ┌────▼─────┐  ┌─────▼──────┐
    │ DB Sub-a     │  │ DB Sub-b │  │ DB Sub-c   │
    │ 10.0.100.0   │  │10.0.200.0│  │10.0.201.0  │
    │ [RDS Primary]│  │[RDS Read]│  │[ElastiCache]│
    └──────────────┘  └──────────┘  └─────────────┘

Security:
- Public subnets: SG allows 80/443 from 0.0.0.0/0
- Private subnets: SG allows traffic only from ALB SG
- DB subnets: SG allows 3306/5432 only from App SG
- NACLs: Block known malicious IP ranges at subnet level
```

```bash
# Complete VPC setup script
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=prod-vpc}]' \
    --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# Public subnets
PUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=public-a},{Key=Tier,Value=public}]' \
    --query 'Subnet.SubnetId' --output text)

PUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=public-b},{Key=Tier,Value=public}]' \
    --query 'Subnet.SubnetId' --output text)

# Private subnets
PRIV_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.10.0/24 \
    --availability-zone us-east-1a --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=private-app-a}]' \
    --query 'Subnet.SubnetId' --output text)

PRIV_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.20.0/24 \
    --availability-zone us-east-1b --tag-specifications \
    'ResourceType=subnet,Tags=[{Key=Name,Value=private-app-b}]' \
    --query 'Subnet.SubnetId' --output text)

# Database subnets
DB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.100.0/24 \
    --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)

DB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.200.0/24 \
    --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# Internet Gateway
IGW=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID

# NAT Gateway (in public subnet)
EIP=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id $PUB_A --allocation-id $EIP \
    --query 'NatGateway.NatGatewayId' --output text)

# Route tables
PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_A
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_B

PRIV_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIV_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_A
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_B
```

---

## Real-Time Example 2: Multi-VPC with Transit Gateway

**Scenario:** Your company has 4 AWS accounts (Dev, QA, Prod, Shared Services). Each has its own VPC. You need them to communicate without creating N×N peering connections.

```
Without Transit Gateway (6 peering connections needed for 4 VPCs):
  Dev ←──→ QA    Dev ←──→ Prod    Dev ←──→ Shared
  QA ←──→ Prod   QA ←──→ Shared   Prod ←──→ Shared

With Transit Gateway (4 connections — hub and spoke):
                    ┌──────────────────┐
                    │  Transit Gateway │
                    │  (Hub)           │
                    └──┬───┬───┬───┬──┘
                       │   │   │   │
              ┌────────┘   │   │   └────────┐
              │            │   │            │
    ┌─────────▼──┐  ┌─────▼───▼──┐  ┌──────▼─────┐  ┌──────────┐
    │ Dev VPC    │  │ QA VPC     │  │ Prod VPC   │  │ Shared   │
    │ 10.1.0.0  │  │ 10.2.0.0   │  │ 10.3.0.0   │  │ 10.0.0.0 │
    │            │  │            │  │            │  │ (DNS,    │
    │            │  │            │  │            │  │  Tools,  │
    │            │  │            │  │            │  │  VPN)    │
    └────────────┘  └────────────┘  └────────────┘  └──────────┘

    Route table in each VPC:
    10.0.0.0/8 → Transit Gateway (reaches all other VPCs)

    TGW route table can enforce:
    - Dev CANNOT talk to Prod directly
    - All VPCs CAN reach Shared Services
    - Prod is isolated from Dev/QA
```

```bash
# Create Transit Gateway
TGW_ID=$(aws ec2 create-transit-gateway \
    --description "Central hub for all VPCs" \
    --options AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=enable \
    --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=central-tgw}]' \
    --query 'TransitGateway.TransitGatewayId' --output text)

# Attach each VPC
aws ec2 create-transit-gateway-vpc-attachment \
    --transit-gateway-id $TGW_ID \
    --vpc-id $DEV_VPC_ID \
    --subnet-ids $DEV_PRIV_SUBNET_A $DEV_PRIV_SUBNET_B

aws ec2 create-transit-gateway-vpc-attachment \
    --transit-gateway-id $TGW_ID \
    --vpc-id $PROD_VPC_ID \
    --subnet-ids $PROD_PRIV_SUBNET_A $PROD_PRIV_SUBNET_B

# Add route in VPC route tables pointing to TGW
aws ec2 create-route --route-table-id $DEV_PRIV_RT \
    --destination-cidr-block 10.0.0.0/8 --transit-gateway-id $TGW_ID
```

---

## Real-Time Example 3: VPC Endpoints for Secure S3 Access

**Scenario:** Your EC2 instances in private subnets access S3 frequently. Currently traffic goes: EC2 → NAT Gateway → Internet → S3. This is slow and costs NAT data transfer fees ($0.045/GB). VPC Endpoints eliminate this.

```
BEFORE (via NAT Gateway — costly):
EC2 (private) → NAT GW ($0.045/GB) → Internet → S3
Cost: 1TB/month = $45 NAT charges

AFTER (via VPC Gateway Endpoint — FREE):
EC2 (private) → VPC Endpoint → S3 (stays within AWS network)
Cost: $0 (Gateway endpoints are free!)

Savings: $45/TB/month
Additional benefit: Traffic never leaves AWS network (more secure)
```

```bash
# Create Gateway Endpoint for S3 (FREE)
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.s3 \
    --route-table-ids $PRIV_RT \
    --vpc-endpoint-type Gateway

# Create Interface Endpoint for SSM (for Session Manager — no bastion needed)
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ssm \
    --vpc-endpoint-type Interface \
    --subnet-ids $PRIV_A $PRIV_B \
    --security-group-ids $ENDPOINT_SG \
    --private-dns-enabled

# Also need these for full SSM Session Manager support:
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ssmmessages \
    --vpc-endpoint-type Interface --subnet-ids $PRIV_A $PRIV_B \
    --security-group-ids $ENDPOINT_SG --private-dns-enabled

aws ec2 create-vpc-endpoint --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ec2messages \
    --vpc-endpoint-type Interface --subnet-ids $PRIV_A $PRIV_B \
    --security-group-ids $ENDPOINT_SG --private-dns-enabled

# Endpoint policy — restrict to specific bucket
cat > endpoint-policy.json << 'EOF'
{
    "Statement": [{
        "Effect": "Allow",
        "Principal": "*",
        "Action": ["s3:GetObject", "s3:PutObject"],
        "Resource": ["arn:aws:s3:::my-app-bucket/*"]
    }]
}
EOF
```

---

## Hands-On Labs

### Lab 1: Create Production VPC
```bash
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=prod-vpc}]' \
    --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

PUB_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)

PRIV_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.10.0/24 --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)

IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUBNET

EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_ID=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUBNET \
    --allocation-id $EIP_ALLOC --query 'NatGateway.NatGatewayId' --output text)

PRIV_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIV_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_ID
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_SUBNET
```

### Lab 2: Security Groups vs NACLs
```bash
SG_ID=$(aws ec2 create-security-group --group-name web-sg \
    --description "Web server SG" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 443 --cidr 0.0.0.0/0

NACL_ID=$(aws ec2 create-network-acl --vpc-id $VPC_ID --query 'NetworkAcl.NetworkAclId' --output text)
aws ec2 create-network-acl-entry --network-acl-id $NACL_ID \
    --rule-number 100 --protocol tcp --port-range From=80,To=80 --cidr-block 0.0.0.0/0 --ingress --rule-action allow
aws ec2 create-network-acl-entry --network-acl-id $NACL_ID \
    --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --egress --rule-action allow
```

### Lab 3: VPC Flow Logs
```bash
# Create CloudWatch log group for VPC Flow Logs
aws logs create-log-group --log-group-name /vpc/flow-logs/prod

# Enable VPC Flow Logs
aws ec2 create-flow-logs \
    --resource-type VPC \
    --resource-ids $VPC_ID \
    --traffic-type ALL \
    --log-destination-type cloud-watch-logs \
    --log-group-name /vpc/flow-logs/prod \
    --deliver-logs-permission-arn arn:aws:iam::ACCT:role/VPCFlowLogsRole

# Query flow logs for rejected traffic (security analysis)
aws logs filter-log-events \
    --log-group-name /vpc/flow-logs/prod \
    --filter-pattern "REJECT" \
    --start-time $(date -d '1 hour ago' +%s)000
```

### Lab 4: VPC Endpoint for S3
```bash
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.s3 \
    --route-table-ids $PRIV_RT \
    --vpc-endpoint-type Gateway
```

---

## VPC Connectivity Decision Guide

| Need | Solution | Cost | Latency | Use When |
|------|----------|------|---------|----------|
| 2 VPCs, same region | VPC Peering | Free (data transfer only) | Lowest | Simple, non-transitive |
| 2 VPCs, cross-region | VPC Peering (cross-region) | $0.01/GB | Low | Simple cross-region |
| 3+ VPCs | Transit Gateway | $0.05/hr + $0.02/GB | Low | Hub-and-spoke, centralized |
| On-premises (quick) | Site-to-Site VPN | $0.05/hr | Variable (internet) | Small office, backup |
| On-premises (dedicated) | Direct Connect | $0.30/port-hr | Lowest | Large data, consistent latency |
| AWS services privately | VPC Endpoints | Free (GW) / $0.01/hr (IF) | Low | Avoid NAT costs, security |

---

## Interview Questions

1. **Explain the difference between Security Groups and NACLs.**
   > **Security Groups** are stateful (return traffic auto-allowed), operate at instance level, only have allow rules, and evaluate all rules together. **NACLs** are stateless (must explicitly allow return traffic on ephemeral ports), operate at subnet level, have allow AND deny rules, and evaluate rules in number order (first match wins). Use SGs as primary firewall, NACLs as additional subnet-level defense.

2. **How does NAT Gateway enable internet access for private subnets?**
   > NAT Gateway sits in a public subnet (has public IP). Private subnet route table has `0.0.0.0/0 → NAT Gateway`. When private EC2 sends traffic to internet: (1) Packet goes to NAT GW, (2) NAT replaces source IP with its own public IP, (3) Response comes back to NAT GW, (4) NAT translates back to private IP and forwards. Outbound-only — external hosts cannot initiate connections to private instances.

3. **What is VPC Peering and what are its limitations?**
   > Connects two VPCs using private IP addresses as if in the same network. Limitations: (1) **No transitive routing** — if A↔B and B↔C are peered, A cannot reach C through B, (2) CIDR blocks cannot overlap, (3) One peering per VPC pair, (4) Cannot reference SGs across regions. For 3+ VPCs, use Transit Gateway instead.

4. **When would you use Transit Gateway vs VPC Peering?**
   > **VPC Peering:** 2-3 VPCs, simple setup, lowest latency, free (data charges only). **Transit Gateway:** 3+ VPCs, hub-and-spoke model, centralized route management, supports VPN and Direct Connect attachments, can implement network segmentation with multiple route tables. TGW costs $0.05/hr + $0.02/GB but greatly simplifies complex networks.

5. **Explain VPC endpoints — Gateway vs Interface.**
   > **Gateway endpoints** (S3, DynamoDB): Add a route to your route table, FREE, no ENI. **Interface endpoints** (all other services): Creates ENI in your subnet with private IP, costs ~$7.20/month + $0.01/GB, uses PrivateLink. Both keep traffic within AWS network (never goes to internet). Interface endpoints support security groups and can be accessed cross-VPC.

6. **How to design a VPC CIDR for a multi-tier application?**
   > Use /16 for flexibility (65K IPs). Divide into tiers: public (/24 per AZ for LBs), private (/24 per AZ for apps), database (/24 per AZ for RDS). Use 3 AZs for HA. Leave space for growth. Never overlap with other VPCs or on-premises networks. Example: 10.0.0.0/16 with 10.0.1-3.0/24 (public), 10.0.10-30.0/24 (private), 10.0.100-201.0/24 (database).

7. **What are VPC Flow Logs and how to analyze them?**
   > Capture IP traffic metadata (source/dest IP, ports, protocol, action, bytes). Can be sent to CloudWatch Logs, S3, or Kinesis Firehose. Analyze with: CloudWatch Insights for quick queries, Athena for S3-stored logs, or third-party tools. Use cases: troubleshooting connectivity, detecting port scanning, identifying top talkers, compliance auditing. Note: they capture metadata only, not packet content.

8. **Bastion Host vs Session Manager — which to use?**
   > **Session Manager (recommended):** No SSH keys, no port 22, IAM-based access, logging/auditing built-in, no bastion host to maintain, works through VPC endpoints (no internet needed). **Bastion Host:** Legacy approach, requires maintaining/patching an EC2, needs port 22 open, key management overhead. Always prefer Session Manager for new architectures.
