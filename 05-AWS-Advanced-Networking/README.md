# Module 5 — AWS Advanced Networking (2 Weeks)

> **Objective:** Design and implement production-grade multi-region network architecture. Networking is the #1 interview differentiator.

> **📖 [Real-World Architecture Diagrams & Flow Guide →](networking-architecture-guide.md)** — 10 production architectures with step-by-step traffic flow explanations, CIDR design, troubleshooting checklist, and cost breakdown.

---

## 🌍 Real-World Analogy: Networking is Like a City's Road System

Imagine AWS Networking as **building an entire city's transportation system**:

```
🏙️ YOUR CITY (AWS Region)
│
├── 🏘️ VPC = Your private neighborhood
│   Has its own roads (subnets), gates (security groups),
│   and address system (CIDR block like 10.0.0.0/16).
│
├── 🛣️ Subnets = Streets in your neighborhood
│   PUBLIC STREET  = Has direct road to the highway (Internet Gateway)
│   PRIVATE STREET = No highway access — residents use a shuttle bus (NAT Gateway)
│
├── 🔁 Transit Gateway = Central Bus Station
│   Instead of building a direct road between every neighborhood,
│   ALL neighborhoods connect to ONE central hub.
│   "NYC → Central Hub → LA" instead of "NYC → LA" + "NYC → Chicago" + ...
│   Saves massive cost when you have 10+ VPCs!
│
├── 🤝 VPC Peering = Private tunnel between two neighborhoods
│   Direct, fast, but NOT transitive:
│   "A connects to B, B connects to C" does NOT mean A can reach C!
│
├── 🔐 VPN = Encrypted tunnel to your on-premise office
│   Like a secret underground tunnel from your office building
│   to your cloud neighborhood. Encrypted, secure, over the internet.
│
├── 🚄 Direct Connect = Private highway (dedicated fiber)
│   Instead of using public internet, you lay your OWN cable.
│   Faster (1-100 Gbps), more reliable, but expensive ($$$).
│
├── 📹 VPC Flow Logs = Traffic cameras on every road
│   Records every car (packet) that passes: origin, destination, allowed/denied.
│   Essential for security audits and troubleshooting.
│
└── 🚪 VPC Endpoints = Private back door to AWS services
    Instead of going through the internet to reach S3,
    build a private hallway directly inside your building.
    Faster, cheaper, more secure.
```

### Real Example: Multi-Region Company Network
```
                    ┌─── HEADQUARTERS (On-Premise) ───┐
                    │   Office in New York              │
                    └──────────┬───────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │ Direct Connect (fiber)│
                    │ OR VPN (encrypted)    │
                    └──────────┬───────────┘
                               │
               ┌───────────────┼───────────────┐
               │               │               │
        ┌──────┴──────┐ ┌─────┴──────┐ ┌──────┴──────┐
        │  US-East    │ │  EU-West   │ │  AP-South   │
        │  VPC        │ │  VPC       │ │  VPC        │
        └──────┬──────┘ └─────┬──────┘ └──────┬──────┘
               │               │               │
               └───────────────┼───────────────┘
                               │
                    Transit Gateway (Hub)
                    Connects ALL VPCs together
```

| Real-World Concept | AWS Service | Why It Matters |
|---|---|---|
| Private neighborhood | VPC | Isolates your resources from others |
| Highway on-ramp | Internet Gateway | Connects public subnet to internet |
| Shuttle bus | NAT Gateway | Lets private resources access internet (outbound only) |
| Central bus station | Transit Gateway | Hub connecting 10+ VPCs efficiently |
| Secret tunnel | VPN | Encrypted link to your office |
| Private fiber cable | Direct Connect | Dedicated, fast, reliable (enterprise) |
| Traffic cameras | VPC Flow Logs | See all network traffic for security |
| Private back door | VPC Endpoints | Access AWS services without internet |

---

## Topics

### Transit Gateway
- Hub-and-spoke architecture for multiple VPCs
- Transit Gateway route tables and associations
- Cross-region peering
- Centralized egress through shared VPC

### VPC Peering (Deep Dive)
- Cross-account and cross-region peering
- Non-transitive routing — limitations
- DNS resolution across peered VPCs

### VPN & Direct Connect
- Site-to-Site VPN — virtual private gateway, customer gateway
- Direct Connect — dedicated 1/10/100 Gbps connections
- VPN as backup for Direct Connect

### VPC Flow Logs Analysis
- Capture to CloudWatch Logs or S3
- Query with CloudWatch Insights
- Analyze with Athena (Parquet for cost optimization)

### Advanced Endpoints
- Gateway Endpoints (S3, DynamoDB) — free
- Interface Endpoints (PrivateLink) — ENI-based
- Endpoint policies for access control

---

## Real-Time Project: Multi-Region VPC Architecture with Transit Gateway

### Architecture
```
                    ┌──────────────────┐
                    │  Transit Gateway  │
                    │   us-east-1      │
                    └──┬───┬───┬───────┘
                       │   │   │
          ┌────────────┘   │   └────────────┐
          │                │                │
   ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
   │  VPC-Prod    │ │  VPC-Dev    │ │  VPC-Shared │
   │ 10.0.0.0/16 │ │ 10.1.0.0/16│ │ 10.2.0.0/16│
   │             │ │             │ │  NAT GW     │
   │ EC2 + RDS   │ │ EC2 + dev   │ │  Bastion    │
   └─────────────┘ └─────────────┘ │  VPN GW     │
                                    └─────────────┘
                                          │
                    ┌──────────────────────┘
                    │  Transit Gateway Peering
                    │
              ┌─────▼───────┐
              │ Transit GW   │
              │ eu-west-1    │
              │  ┌─────────┐ │
              │  │ VPC-DR   │ │
              │  │10.3.0.0/16│
              │  └─────────┘ │
              └──────────────┘
```

### Implementation

#### Step 1: Create Transit Gateway
```bash
# Create Transit Gateway
TGW_ID=$(aws ec2 create-transit-gateway \
    --description "Production Transit Gateway" \
    --options '{
        "AmazonSideAsn": 64512,
        "AutoAcceptSharedAttachments": "enable",
        "DefaultRouteTableAssociation": "enable",
        "DefaultRouteTablePropagation": "enable",
        "DnsSupport": "enable"
    }' \
    --query 'TransitGateway.TransitGatewayId' --output text)

# Attach VPCs
aws ec2 create-transit-gateway-vpc-attachment \
    --transit-gateway-id $TGW_ID \
    --vpc-id vpc-prod \
    --subnet-ids subnet-prod-priv-1 subnet-prod-priv-2

aws ec2 create-transit-gateway-vpc-attachment \
    --transit-gateway-id $TGW_ID \
    --vpc-id vpc-dev \
    --subnet-ids subnet-dev-priv-1

aws ec2 create-transit-gateway-vpc-attachment \
    --transit-gateway-id $TGW_ID \
    --vpc-id vpc-shared \
    --subnet-ids subnet-shared-priv-1
```

#### Step 2: VPC Flow Logs → Athena Analysis
```bash
# Enable flow logs to S3
aws ec2 create-flow-logs \
    --resource-type VPC --resource-ids vpc-prod \
    --traffic-type ALL \
    --log-destination-type s3 \
    --log-destination arn:aws:s3:::flow-logs-bucket/vpc-prod/ \
    --log-format '${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}'
```

```sql
-- Athena query: Top rejected traffic
SELECT srcaddr, dstaddr, dstport, protocol, SUM(packets) as total_packets
FROM vpc_flow_logs
WHERE action = 'REJECT'
  AND date = '2026-02-27'
GROUP BY srcaddr, dstaddr, dstport, protocol
ORDER BY total_packets DESC
LIMIT 20;
```

#### Step 3: Cross-Account RDS Access
```bash
# Account A (EC2) → VPC Peering → Account B (RDS)
# 1. Create VPC Peering from Account A
aws ec2 create-vpc-peering-connection \
    --vpc-id vpc-a --peer-vpc-id vpc-b --peer-owner-id ACCOUNT_B_ID

# 2. Accept in Account B
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id pcx-xxxx

# 3. Update route tables in both VPCs
# 4. Update RDS security group to allow Account A CIDR
```

### Deliverables
- [ ] 3 VPCs connected via Transit Gateway in us-east-1
- [ ] Cross-region TGW peering to eu-west-1 (DR)
- [ ] VPC Flow Logs → S3 → Athena analysis
- [ ] VPN Gateway for on-premises simulation
- [ ] VPC Endpoints for S3 and DynamoDB
- [ ] NAT Gateway in shared VPC for centralized egress
- [ ] Bastion Host with Session Manager alternative
- [ ] Cross-account RDS access demonstrated
- [ ] Network architecture documented
