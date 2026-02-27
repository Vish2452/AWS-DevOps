# VPC — Virtual Private Cloud

> **Every AWS architecture lives inside a VPC. Networking is the #1 technical interview topic for DevOps.**

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

### Connectivity
- **VPC Peering** — connect two VPCs (no transitive routing)
- **Transit Gateway** — hub-and-spoke for multiple VPCs
- **VPC Endpoints** — private access to AWS services
  - Gateway Endpoints: S3, DynamoDB
  - Interface Endpoints: all other services (PrivateLink)
- **VPN Gateway** — encrypted tunnel to on-premises
- **Direct Connect** — dedicated physical connection
- **Bastion Host / Session Manager** — secure access to private instances

### CIDR Design
```
Production VPC:     10.0.0.0/16   (65,536 IPs)
├── Public Subnet:  10.0.1.0/24   (256 IPs) — AZ-a
├── Public Subnet:  10.0.2.0/24   (256 IPs) — AZ-b
├── Private Subnet: 10.0.10.0/24  (256 IPs) — AZ-a (app)
├── Private Subnet: 10.0.20.0/24  (256 IPs) — AZ-b (app)
├── DB Subnet:      10.0.100.0/24 (256 IPs) — AZ-a (database)
└── DB Subnet:      10.0.200.0/24 (256 IPs) — AZ-b (database)
```

---

## Hands-On Labs

### Lab 1: Create Production VPC
```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=prod-vpc}]' \
    --query 'Vpc.VpcId' --output text)

# Enable DNS
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# Create subnets
PUB_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)

PRIV_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.10.0/24 --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)

# Create and attach Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Route table for public subnet
PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUBNET

# NAT Gateway for private subnet
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_ID=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUBNET \
    --allocation-id $EIP_ALLOC --query 'NatGateway.NatGatewayId' --output text)

# Route table for private subnet
PRIV_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIV_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_ID
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_SUBNET
```

### Lab 2: Security Groups vs NACLs
```bash
# Security Group (stateful — allows return traffic automatically)
SG_ID=$(aws ec2 create-security-group --group-name web-sg \
    --description "Web server SG" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 443 --cidr 0.0.0.0/0

# NACL (stateless — must allow both inbound AND outbound)
NACL_ID=$(aws ec2 create-network-acl --vpc-id $VPC_ID --query 'NetworkAcl.NetworkAclId' --output text)
# Allow HTTP in
aws ec2 create-network-acl-entry --network-acl-id $NACL_ID \
    --rule-number 100 --protocol tcp --port-range From=80,To=80 --cidr-block 0.0.0.0/0 --ingress --rule-action allow
# Allow ephemeral ports out (for return traffic)
aws ec2 create-network-acl-entry --network-acl-id $NACL_ID \
    --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --egress --rule-action allow
```

### Lab 3: VPC Endpoint for S3
```bash
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.s3 \
    --route-table-ids $PRIV_RT \
    --vpc-endpoint-type Gateway
```

---

## Interview Questions
1. Explain the difference between Security Groups and NACLs
2. How does NAT Gateway enable internet access for private subnets?
3. What is VPC Peering and what are its limitations?
4. When would you use Transit Gateway vs VPC Peering?
5. Explain VPC endpoints — Gateway vs Interface
6. How to design a VPC CIDR for a multi-tier application?
7. What are VPC Flow Logs and how to analyze them?
8. Bastion Host vs Session Manager — which to use?
