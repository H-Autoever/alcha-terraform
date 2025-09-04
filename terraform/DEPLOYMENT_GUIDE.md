# IoT-MSK-EC2 Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the IoT-MSK-EC2 pipeline infrastructure using Terraform.

## Prerequisites

### Required Software
- AWS CLI >= 2.0
- Terraform >= 1.0
- Python 3.7+
- Git

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Key pair for EC2 access

## Pre-Deployment Setup

### 1. AWS CLI Configuration

```bash
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

### 2. Create EC2 Key Pair

```bash
# Create key pair for EC2 access
aws ec2 create-key-pair \
    --key-name psw0507-key \
    --query 'KeyMaterial' \
    --output text > psw0507-key.pem

# Set proper permissions (Linux/Mac)
chmod 400 psw0507-key.pem

# Windows: Right-click psw0507-key.pem → Properties → Security → Advanced → Disable inheritance → Current user read-only
```

### 3. Configure Terraform Variables

Edit `terraform.tfvars` file:

```hcl
# AWS Configuration
aws_region = "ap-northeast-2"
project_name = "iot-msk-pipeline-psw0507"
environment = "dev"
owner = "psw0507"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
vpc_name = "vpc-iot-msk-psw0507"
availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_names = ["private-subnet-psw0507-1", "private-subnet-psw0507-2"]
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
public_subnet_names = ["public-subnet-psw0507-1", "public-subnet-psw0507-2"]

# MSK Configuration
msk_instance_type = "kafka.t3.small"
msk_volume_size = 100
msk_scram_username = "iotuser-psw0507"

# EC2 Configuration
ec2_instance_type = "t3.micro"
ec2_key_pair_name = "psw0507-key"

# IoT Configuration
iot_thing_name = "test-psw0507"
iot_topic_name = "sensor-data"
```

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

### Step 2: Plan Deployment

```bash
# Review deployment plan
terraform plan

# Save plan to file (optional)
terraform plan -out=deployment.tfplan
```

### Step 3: Deploy Infrastructure

```bash
# Apply configuration
terraform apply

# Or apply saved plan
terraform apply deployment.tfplan
```

### Step 4: Post-Deployment Verification

```bash
# Check outputs
terraform output

# Example output:
#   ec2_public_ip = "1.2.3.4"
#   msk_cluster_arn = "arn:aws:kafka:..."
#   iot_thing_name = "test-psw0507"
```

## Post-Deployment Configuration

### 1. Access EC2 Instance

```bash
# SSH to EC2 instance
ssh -i psw0507-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check installation log
cat /home/ec2-user/installation.log
```

### 2. Start Consumer Service

```bash
# Start MSK consumer service
sudo systemctl start iot-msk-pipeline-psw0507-consumer

# Enable auto-start
sudo systemctl enable iot-msk-pipeline-psw0507-consumer

# Check service status
sudo systemctl status iot-msk-pipeline-psw0507-consumer
```

### 3. Monitor Consumer Logs

```bash
# View real-time logs
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer

# View recent logs
sudo journalctl -u iot-msk-pipeline-psw0507-consumer --since "1 hour ago"
```

## Testing the Pipeline

### 1. Test IoT Message Publishing

```bash
# From local machine or EC2
cd app

# Install dependencies
pip install boto3

# Send test message
python iot_publisher.py --test
```

### 2. Verify Message Flow

```bash
# Send test message via AWS CLI
aws iot-data publish \
    --topic "topic/test" \
    --payload '{
        "temperature": 25.5,
        "humidity": 60.2,
        "timestamp": "2025-09-04T10:30:00Z",
        "device": "psw0507-sensor"
    }' \
    --region ap-northeast-2
```

### 3. Check Consumer Output

```bash
# On EC2 instance, check if messages are received
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer
```

## Resource Verification

### Created Resources Checklist

#### Core Infrastructure
- ✅ KMS Key: iot-msk-pipeline-psw0507-kms
- ✅ Secrets Manager: AmazonMSK_iotuser-psw0507
- ✅ MSK Cluster: iot-msk-pipeline-psw0507-cluster
- ✅ IoT Thing: test-psw0507
- ✅ IoT Rule: iotmskpipelinepsw0507MSKRule

#### Networking
- ✅ VPC: vpc-iot-msk-psw0507
- ✅ Public Subnets: public-subnet-psw0507-1, public-subnet-psw0507-2
- ✅ Private Subnets: private-subnet-psw0507-1, private-subnet-psw0507-2
- ✅ Internet Gateway: igw-iot-msk-psw0507
- ✅ NAT Gateways: nat-gateway-psw0507-1, nat-gateway-psw0507-2
- ✅ Route Tables: rt-public-psw0507, rt-private-psw0507-1, rt-private-psw0507-2
- ✅ Security Groups: msk-sg-psw0507, ec2-sg-psw0507

#### Compute
- ✅ EC2 Instance: iot-msk-pipeline-psw0507-consumer
- ✅ EC2 Role: iot-msk-pipeline-psw0507-ec2-role
- ✅ SystemD Service: iot-msk-pipeline-psw0507-consumer.service

## Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

```bash
# Check Terraform state
terraform show

# Refresh state
terraform refresh

# Fix state issues
terraform import <resource_type>.<resource_name> <resource_id>
```

#### 2. EC2 Instance Not Accessible

```bash
# Check security group rules
aws ec2 describe-security-groups --group-names ec2-sg-psw0507

# Verify key pair
aws ec2 describe-key-pairs --key-names psw0507-key

# Check instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=iot-msk-pipeline-psw0507-consumer"
```

#### 3. MSK Connectivity Issues

```bash
# Check MSK cluster status
aws kafka describe-cluster --cluster-arn <MSK_CLUSTER_ARN>

# Verify bootstrap brokers
aws kafka get-bootstrap-brokers --cluster-arn <MSK_CLUSTER_ARN>

# Check secrets
aws secretsmanager get-secret-value --secret-id AmazonMSK_iotuser-psw0507
```

#### 4. IoT Rule Not Working

```bash
# Check IoT rule
aws iot get-topic-rule --rule-name iotmskpipelinepsw0507MSKRule

# Check IoT logs
aws logs filter-log-events \
    --log-group-name /aws/iot/iot-msk-pipeline-psw0507 \
    --start-time $(date -d '1 hour ago' +%s)000
```

### Log Locations

#### EC2 Consumer Logs
```bash
# Service logs
sudo journalctl -u iot-msk-pipeline-psw0507-consumer

# Installation logs
cat /home/ec2-user/installation.log

# System logs
sudo tail -f /var/log/messages
```

#### CloudWatch Logs
- IoT Core: `/aws/iot/iot-msk-pipeline-psw0507`
- MSK: `/aws/msk/iot-msk-pipeline-psw0507`

## Monitoring and Maintenance

### 1. CloudWatch Monitoring

```bash
# View IoT Core metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/IoT \
    --metric-name PublishIn.Success \
    --start-time 2025-09-04T00:00:00Z \
    --end-time 2025-09-04T23:59:59Z \
    --period 3600 \
    --statistics Sum

# View MSK metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/Kafka \
    --metric-name MessagesInPerSec \
    --start-time 2025-09-04T00:00:00Z \
    --end-time 2025-09-04T23:59:59Z \
    --period 3600 \
    --statistics Average
```

### 2. Regular Maintenance

```bash
# Update EC2 instance
sudo yum update -y

# Restart consumer service if needed
sudo systemctl restart iot-msk-pipeline-psw0507-consumer

# Check disk usage
df -h

# Check memory usage
free -h
```

## Cleanup

### Destroy Infrastructure

```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Type: yes

# Verify cleanup
aws kafka list-clusters
aws iot list-things
aws ec2 describe-instances
```

### Manual Cleanup (if needed)

```bash
# Delete key pair
aws ec2 delete-key-pair --key-name psw0507-key

# Remove local key file
rm psw0507-key.pem

# Clean Terraform state
rm -rf .terraform
rm terraform.tfstate*
```

## Best Practices

1. **Version Control**: Keep terraform files in version control
2. **State Management**: Use remote state storage for production
3. **Security**: Rotate credentials regularly
4. **Monitoring**: Set up CloudWatch alarms
5. **Backup**: Regular backup of important data
6. **Testing**: Test in development environment first

## Support

For issues and questions:
1. Check troubleshooting section
2. Review AWS documentation
3. Check Terraform documentation
4. Contact system administrator

---

**Note**: This deployment guide is specific to the psw0507 configuration. Update resource names and identifiers as needed for different environments.
