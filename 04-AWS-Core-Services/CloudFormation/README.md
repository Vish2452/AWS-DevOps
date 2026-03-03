# CloudFormation — Infrastructure as Code (AWS Native)

> Model and provision all your AWS resources using JSON/YAML templates. The "blueprint" service for AWS infrastructure. Declare what you want, CloudFormation builds it.

---

## Real-World Analogy

CloudFormation is like an **architect's blueprint for a building**:
- You draw the blueprint (template) — rooms, wiring, plumbing
- Give it to the construction company (CloudFormation)
- They build exactly what's on the blueprint (stack)
- Want to modify? Update the blueprint → construction company makes changes
- Want to tear down? Delete the blueprint → everything is demolished cleanly
- Version control your blueprints → reproducible infrastructure

---

## How CloudFormation Works

```
                Template (YAML/JSON)
                      │
                      ▼
              ┌───────────────┐
              │ CloudFormation │
              │    Service     │
              └───────┬───────┘
                      │
            ┌─────────┼─────────┐
            ▼         ▼         ▼
        ┌──────┐  ┌──────┐  ┌──────┐
        │ VPC  │  │ EC2  │  │ RDS  │
        │      │  │      │  │      │
        └──────┘  └──────┘  └──────┘
                  = Stack

    Template → Stack → Resources
    Update Template → Change Set → Update Stack
    Delete Stack → All resources deleted
```

---

## Template Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'My infrastructure template'

# 1. Parameters — Input values (like function arguments)
Parameters:
  EnvironmentType:
    Type: String
    AllowedValues: [dev, staging, prod]
    Default: dev

# 2. Mappings — Static lookup tables
Mappings:
  RegionAMI:
    us-east-1:
      HVM64: ami-0c55b159cbfafe1f0
    us-west-2:
      HVM64: ami-0d1cd67c26f5fca19

# 3. Conditions — Conditional resource creation
Conditions:
  IsProd: !Equals [!Ref EnvironmentType, prod]

# 4. Resources — AWS resources to create (REQUIRED)
Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16

# 5. Outputs — Values to export/display
Outputs:
  VPCId:
    Value: !Ref MyVPC
    Export:
      Name: !Sub "${AWS::StackName}-VPCId"
```

### Template Sections

| Section | Required | Description |
|---------|----------|-------------|
| **AWSTemplateFormatVersion** | No | Template version (always `2010-09-09`) |
| **Description** | No | Text description of the template |
| **Parameters** | No | Input values provided at stack creation |
| **Mappings** | No | Static key-value lookup tables |
| **Conditions** | No | Conditionally create resources |
| **Resources** | **Yes** | AWS resources to provision |
| **Outputs** | No | Values to display/export after creation |
| **Metadata** | No | Additional info (e.g., AWS::CloudFormation::Interface) |
| **Transform** | No | Macros and SAM transforms |

---

## Intrinsic Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `!Ref` | Reference a parameter or resource | `!Ref MyVPC` → VPC ID |
| `!GetAtt` | Get resource attribute | `!GetAtt MyEC2.PublicIp` |
| `!Sub` | String substitution | `!Sub "arn:aws:s3:::${BucketName}"` |
| `!Join` | Join strings | `!Join ["-", [prod, web, sg]]` |
| `!Select` | Pick from list | `!Select [0, !GetAZs ""]` |
| `!Split` | Split string to list | `!Split [",", "a,b,c"]` |
| `!If` | Conditional value | `!If [IsProd, t3.large, t3.micro]` |
| `!FindInMap` | Lookup from Mappings | `!FindInMap [RegionAMI, !Ref AWS::Region, HVM64]` |
| `!ImportValue` | Import from another stack | `!ImportValue NetworkStack-VPCId` |
| `!GetAZs` | Get AZs in region | `!GetAZs ""` |
| `!Cidr` | Generate CIDR blocks | `!Cidr [!Ref VPCCidr, 6, 8]` |

---

## Real-Time Example 1: Production VPC with Subnets

**Scenario:** Create a production VPC with public/private subnets, NAT Gateway, and route tables.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Production VPC with public and private subnets

Parameters:
  VPCCidr:
    Type: String
    Default: '10.0.0.0/16'
  Environment:
    Type: String
    AllowedValues: [dev, staging, prod]

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VPCCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub "${Environment}-vpc"

  # Internet Gateway
  IGW:
    Type: AWS::EC2::InternetGateway
  IGWAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref IGW

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [0, !Cidr [!Ref VPCCidr, 6, 8]]
      AvailabilityZone: !Select [0, !GetAZs ""]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub "${Environment}-public-1"

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [1, !Cidr [!Ref VPCCidr, 6, 8]]
      AvailabilityZone: !Select [1, !GetAZs ""]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub "${Environment}-public-2"

  # Private Subnets
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [2, !Cidr [!Ref VPCCidr, 6, 8]]
      AvailabilityZone: !Select [0, !GetAZs ""]
      Tags:
        - Key: Name
          Value: !Sub "${Environment}-private-1"

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: !Select [3, !Cidr [!Ref VPCCidr, 6, 8]]
      AvailabilityZone: !Select [1, !GetAZs ""]
      Tags:
        - Key: Name
          Value: !Sub "${Environment}-private-2"

  # NAT Gateway
  NatEIP:
    Type: AWS::EC2::EIP
    DependsOn: IGWAttachment
  NatGateway:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatEIP.AllocationId
      SubnetId: !Ref PublicSubnet1

  # Route Tables
  PublicRT:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: IGWAttachment
    Properties:
      RouteTableId: !Ref PublicRT
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref IGW
  PublicSubnet1RTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRT
  PublicSubnet2RTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref PublicRT

  PrivateRT:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
  PrivateRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRT
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway
  PrivateSubnet1RTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet1
      RouteTableId: !Ref PrivateRT
  PrivateSubnet2RTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet2
      RouteTableId: !Ref PrivateRT

Outputs:
  VPCId:
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}-VPCId"
  PublicSubnets:
    Value: !Join [",", [!Ref PublicSubnet1, !Ref PublicSubnet2]]
    Export:
      Name: !Sub "${AWS::StackName}-PublicSubnets"
  PrivateSubnets:
    Value: !Join [",", [!Ref PrivateSubnet1, !Ref PrivateSubnet2]]
    Export:
      Name: !Sub "${AWS::StackName}-PrivateSubnets"
```

```bash
# Deploy the stack
aws cloudformation create-stack \
    --stack-name prod-vpc \
    --template-body file://vpc-template.yaml \
    --parameters ParameterKey=Environment,ParameterValue=prod

# Monitor stack creation
aws cloudformation describe-stack-events \
    --stack-name prod-vpc \
    --query 'StackEvents[*].[Timestamp,ResourceType,ResourceStatus]' \
    --output table

# Get outputs
aws cloudformation describe-stacks \
    --stack-name prod-vpc \
    --query 'Stacks[0].Outputs'
```

---

## Real-Time Example 2: EC2 with Auto Scaling & ALB

**Scenario:** Deploy an auto-scaling web application with Application Load Balancer.

```yaml
Resources:
  # Security Group
  WebSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Web server security group
      VpcId: !ImportValue prod-vpc-VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  # Launch Template
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        ImageId: !FindInMap [RegionAMI, !Ref "AWS::Region", HVM64]
        InstanceType: !If [IsProd, t3.medium, t3.micro]
        SecurityGroupIds:
          - !Ref WebSG
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd
            echo "<h1>Hello from ${Environment}</h1>" > /var/www/html/index.html

  # ALB
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets: !Split [",", !ImportValue prod-vpc-PublicSubnets]
      SecurityGroups: [!Ref WebSG]
  
  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Port: 80
      Protocol: HTTP
      VpcId: !ImportValue prod-vpc-VPCId
      HealthCheckPath: /
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ALB
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  # Auto Scaling Group
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: 2
      MaxSize: 6
      DesiredCapacity: 2
      VPCZoneIdentifier: !Split [",", !ImportValue prod-vpc-PrivateSubnets]
      TargetGroupARNs:
        - !Ref TargetGroup

  # Scaling Policy
  CPUScaleUp:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref ASG
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70
```

---

## Real-Time Example 3: Nested Stacks for Modular Architecture

**Scenario:** Break a large infrastructure into reusable nested stacks.

```yaml
# parent-stack.yaml
Resources:
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/cf-templates/network.yaml
      Parameters:
        Environment: !Ref Environment

  DatabaseStack:
    Type: AWS::CloudFormation::Stack
    DependsOn: NetworkStack
    Properties:
      TemplateURL: https://s3.amazonaws.com/cf-templates/database.yaml
      Parameters:
        VPCId: !GetAtt NetworkStack.Outputs.VPCId
        SubnetIds: !GetAtt NetworkStack.Outputs.PrivateSubnets

  ApplicationStack:
    Type: AWS::CloudFormation::Stack
    DependsOn: [NetworkStack, DatabaseStack]
    Properties:
      TemplateURL: https://s3.amazonaws.com/cf-templates/application.yaml
      Parameters:
        VPCId: !GetAtt NetworkStack.Outputs.VPCId
        SubnetIds: !GetAtt NetworkStack.Outputs.PublicSubnets
        DBEndpoint: !GetAtt DatabaseStack.Outputs.DBEndpoint
```

```bash
# Upload templates to S3
aws s3 sync ./templates/ s3://cf-templates/

# Deploy parent stack (creates all nested stacks)
aws cloudformation create-stack \
    --stack-name production \
    --template-body file://parent-stack.yaml \
    --parameters ParameterKey=Environment,ParameterValue=prod \
    --capabilities CAPABILITY_NAMED_IAM
```

---

## CloudFormation vs Terraform

| Feature | CloudFormation | Terraform |
|---------|---------------|-----------|
| **Provider** | AWS only | Multi-cloud (AWS, Azure, GCP, etc.) |
| **Language** | JSON / YAML | HCL (HashiCorp Configuration Language) |
| **State** | Managed by AWS | You manage (S3 + DynamoDB) |
| **Drift detection** | Built-in | `terraform plan` shows drift |
| **Rollback** | Automatic on failure | Manual (apply previous state) |
| **Modules** | Nested stacks | Native modules (more flexible) |
| **Preview changes** | Change Sets | `terraform plan` |
| **Cost** | Free | Free (open source) |
| **Community** | AWS-focused | Massive multi-cloud community |
| **Learning curve** | Moderate (verbose YAML) | Moderate (HCL syntax) |

---

## Important CLI Commands

```bash
# Create stack
aws cloudformation create-stack --stack-name my-stack --template-body file://template.yaml

# Update stack (with change set preview)
aws cloudformation create-change-set --stack-name my-stack --template-body file://template.yaml --change-set-name my-changes
aws cloudformation describe-change-set --stack-name my-stack --change-set-name my-changes
aws cloudformation execute-change-set --stack-name my-stack --change-set-name my-changes

# Delete stack
aws cloudformation delete-stack --stack-name my-stack

# Validate template
aws cloudformation validate-template --template-body file://template.yaml

# List stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Detect drift
aws cloudformation detect-stack-drift --stack-name my-stack
aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id DETECTION_ID
```

---

## Labs

### Lab 1: Create a VPC Stack from Template
```bash
# Use the VPC template from Example 1
# Deploy with different parameter values for dev and prod
# View resources created in AWS Console
# Get outputs and use in next lab
aws cloudformation create-stack --stack-name lab-vpc --template-body file://vpc.yaml --parameters ParameterKey=Environment,ParameterValue=dev
```

### Lab 2: Deploy EC2 with UserData
```bash
# Create template with EC2 instance + security group
# Use UserData to install and start a web server
# Use Parameters for instance type and key pair
# Use Mappings for region-specific AMIs
# Access the web server after creation
```

### Lab 3: Update Stack with Change Sets
```bash
# Modify template (e.g., change instance type)
# Create a change set to preview changes
# Review what will be added/modified/deleted
# Execute the change set
# Verify the update was applied correctly
```

### Lab 4: Provision Infrastructure with Outputs & Cross-Stack References
```bash
# Create network stack exporting VPC ID and subnet IDs
# Create application stack importing those values
# Test cross-stack references with !ImportValue
# Delete stacks in correct order (app first, then network)
```

---

## Interview Questions

1. **What is CloudFormation and why use it?**
   → IaC service for AWS. Define infrastructure in YAML/JSON templates. Benefits: reproducibility, version control, automated provisioning, drift detection, automatic rollback.

2. **Explain the difference between a template and a stack.**
   → Template: the blueprint (YAML/JSON file). Stack: the running instance of a template (actual AWS resources). One template can create many stacks.

3. **What happens if a CloudFormation stack creation fails?**
   → By default, automatic rollback — all created resources are deleted. Can disable rollback for debugging with `--disable-rollback`.

4. **What are Change Sets?**
   → Preview mechanism. Before updating a stack, create a change set to see what will be added, modified, or deleted. Then execute or discard the change set.

5. **How do you handle secrets in CloudFormation?**
   → Use `AWS::SSM::Parameter` (Parameter Store) or `AWS::SecretsManager::Secret`. Reference with dynamic references: `{{resolve:ssm-secure:my-secret}}`. Never hardcode secrets.

6. **CloudFormation vs Terraform — when to use which?**
   → CloudFormation: AWS-only, free, automatic rollback, native AWS integration. Terraform: multi-cloud, HCL is more readable, better module system, larger community.

7. **What is drift detection?**
   → Compares actual resource state vs template definition. Detects manual changes (drift). Helps maintain IaC compliance. Can run on-demand or via AWS Config.

8. **How do you structure large CloudFormation projects?**
   → Nested stacks for modularity, cross-stack references with Exports/ImportValue, StackSets for multi-account deployment, SAM for serverless applications.
