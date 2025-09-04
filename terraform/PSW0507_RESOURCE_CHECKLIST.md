# PSW0507 Resource Deployment Checklist

## Overview

This document provides a comprehensive checklist for verifying the successful deployment of all AWS resources for the IoT-MSK-EC2 pipeline with identifier `psw0507`.

## Pre-Deployment Configuration

### Terraform Variables
- `project_name`: `iot-msk-pipeline-psw0507`
- `owner`: `psw0507`
- `vpc_name`: `vpc-iot-msk-psw0507`
- `private_subnet_names`: `["private-subnet-psw0507-1", "private-subnet-psw0507-2"]`
- `public_subnet_names`: `["public-subnet-psw0507-1", "public-subnet-psw0507-2"]`
- `ec2_key_pair_name`: `psw0507-key`
- `msk_scram_username`: `iotuser-psw0507`
- `iot_thing_name`: `test-psw0507`

### Expected Resource Names
- All key pair names: `psw0507-key`
- All service names: `iot-msk-pipeline-psw0507-consumer`
- All SSH commands: `ssh -i psw0507-key.pem`
- All example outputs contain psw0507 identifier

## Resource Verification Checklist

### 🔐 Security & Encryption

#### KMS (Key Management Service)
- [ ] KMS Key Alias: `alias/iot-msk-pipeline-psw0507-kms-key`
- [ ] Key Policy: Allows IoT, MSK, and Secrets Manager access
- [ ] Key State: Enabled

#### Secrets Manager
- [ ] Secret Name: `AmazonMSK_iotuser-psw0507`
- [ ] Secret Value: Contains username and password for MSK SCRAM
- [ ] KMS Encryption: Uses project KMS key

### 🌐 Networking Infrastructure

#### VPC and Subnets
- [ ] VPC: `vpc-iot-msk-psw0507`
- [ ] Public Subnets: `public-subnet-psw0507-1`, `public-subnet-psw0507-2`
- [ ] Private Subnets: `private-subnet-psw0507-1`, `private-subnet-psw0507-2`
- [ ] Availability Zones: `ap-northeast-2a`, `ap-northeast-2c`

#### Gateways and Routing
- [ ] Internet Gateway: `igw-iot-msk-psw0507`
- [ ] NAT Gateways: `nat-gateway-psw0507-1`, `nat-gateway-psw0507-2`
- [ ] Elastic IPs: `nat-eip-psw0507-1`, `nat-eip-psw0507-2`
- [ ] Route Tables: `rt-public-psw0507`, `rt-private-psw0507-1`, `rt-private-psw0507-2`

#### Security Groups
- [ ] MSK Security Group: `msk-sg-psw0507`
  - [ ] Allows SCRAM-SHA-512 port 9096 from EC2 security group
  - [ ] Allows internal MSK communication
- [ ] EC2 Security Group: `ec2-sg-psw0507`
  - [ ] Allows SSH port 22 from anywhere (0.0.0.0/0)
  - [ ] Allows all outbound traffic

### 📊 Amazon MSK (Managed Streaming for Kafka)

#### MSK Cluster
- [ ] Cluster Name: `iot-msk-pipeline-psw0507-cluster`
- [ ] Kafka Version: `3.5.1`
- [ ] Broker Nodes: 2 nodes
- [ ] Instance Type: `kafka.t3.small`
- [ ] Storage: 100GB EBS per broker

#### MSK Configuration
- [ ] Configuration Name: `iot-msk-pipeline-psw0507-msk-config`
- [ ] Auto-create topics: Enabled (`auto.create.topics.enable=true`)
- [ ] Default replication factor: 2
- [ ] Number of partitions: 3

#### MSK Security
- [ ] Authentication: SCRAM-SHA-512 enabled
- [ ] Encryption in transit: TLS enabled
- [ ] Encryption at rest: Not configured (default)
- [ ] Secret Association: Linked to Secrets Manager

#### MSK Monitoring
- [ ] CloudWatch Logs: Enabled
- [ ] Log Group: `/aws/msk/iot-msk-pipeline-psw0507`
- [ ] Log Retention: 7 days

### 🛰️ AWS IoT Core

#### IoT Thing
- [ ] Thing Name: `test-psw0507`
- [ ] Thing Attributes: Environment and Project tags

#### IoT Rule
- [ ] Rule Name: `iotmskpipelinepsw0507MSKRule`
- [ ] SQL Query: `SELECT * FROM 'topic/test'`
- [ ] Enabled: True
- [ ] Actions: Kafka action configured

#### IoT Rule Destination
- [ ] VPC Destination: Configured for MSK access
- [ ] Subnets: Private subnets
- [ ] Security Groups: MSK security group
- [ ] IAM Role: IoT rule execution role

#### IoT Logging
- [ ] CloudWatch Log Group: `/aws/iot/iot-msk-pipeline-psw0507`
- [ ] Log Retention: 7 days
- [ ] KMS Encryption: Project KMS key

### 💻 EC2 Consumer

#### EC2 Instance
- [ ] Instance Name: `iot-msk-pipeline-psw0507-consumer`
- [ ] Instance Type: `t3.micro`
- [ ] AMI: Amazon Linux 2
- [ ] Key Pair: `psw0507-key`
- [ ] Subnet: Public subnet (for SSH access)
- [ ] Public IP: Auto-assigned
- [ ] Security Group: `ec2-sg-psw0507`

#### EC2 IAM Role
- [ ] Role Name: `iot-msk-pipeline-psw0507-ec2-role`
- [ ] Policies: Secrets Manager read, MSK connect, CloudWatch logs
- [ ] Instance Profile: Attached to EC2 instance

#### Software Installation (User Data)
- [ ] Python 3: Installed
- [ ] Java 11: Installed (for Kafka tools)
- [ ] confluent-kafka: Python library installed
- [ ] boto3: AWS SDK installed
- [ ] Development tools: gcc, make installed

#### Consumer Application
- [ ] Consumer Script: `/home/ec2-user/iot-msk-pipeline-psw0507/msk_consumer.py`
- [ ] Script Permissions: Executable
- [ ] Owner: ec2-user

#### SystemD Service
- [ ] Service Name: `iot-msk-pipeline-psw0507-consumer.service`
- [ ] Service Status: Enabled for auto-start
- [ ] Service User: ec2-user
- [ ] Restart Policy: Always restart on failure

## Post-Deployment Verification

### 🔍 Connectivity Tests

#### EC2 to MSK Connectivity
```bash
# Test from EC2 instance
telnet <msk-broker-endpoint> 9096
```

#### Secrets Manager Access
```bash
# Test from EC2 instance
aws secretsmanager get-secret-value --secret-id AmazonMSK_iotuser-psw0507
```

#### IoT Core Publishing
```bash
# Test IoT message publishing
aws iot-data publish \
    --topic "topic/test" \
    --payload '{"test": "message"}' \
    --region ap-northeast-2
```

### 📈 Monitoring Verification

#### CloudWatch Logs
- [ ] IoT Core logs appearing in `/aws/iot/iot-msk-pipeline-psw0507`
- [ ] MSK logs appearing in `/aws/msk/iot-msk-pipeline-psw0507`
- [ ] EC2 consumer logs in SystemD journal

#### Service Status
```bash
# Check consumer service
sudo systemctl status iot-msk-pipeline-psw0507-consumer

# Check real-time logs
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer
```

## Expected Terraform Outputs

After successful deployment, verify these outputs:

```hcl
# Core Infrastructure
ec2_instance_id = "i-xxxxxxxxx"
ec2_public_ip = "xxx.xxx.xxx.xxx"
vpc_id = "vpc-xxxxxxxxx"

# MSK Information
msk_cluster_arn = "arn:aws:kafka:ap-northeast-2:xxxx:cluster/iot-msk-pipeline-psw0507-cluster/xxxxx"
bootstrap_brokers_sasl_scram = "b-1.iot-msk-pipeline-psw0507-cluster.xxxxx.ap-northeast-2.managed.kafka:9096,b-2.iot-msk-pipeline-psw0507-cluster.xxxxx.ap-northeast-2.managed.kafka:9096"

# IoT Resources
iot_thing_name = "test-psw0507"
iot_rule_name = "iotmskpipelinepsw0507MSKRule"

# Security
kms_key_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
secret_arn = "arn:aws:secretsmanager:ap-northeast-2:xxxx:secret:AmazonMSK_iotuser-psw0507-xxxxx"

# SSH Access
ssh_command = "ssh -i psw0507-key.pem ec2-user@xxx.xxx.xxx.xxx"
```

## Common Issues and Solutions

### Issue 1: MSK Cluster Creation Fails
**Symptoms**: Terraform times out during MSK cluster creation
**Solution**: 
- Verify subnet configurations
- Check security group rules
- Ensure sufficient IP addresses in private subnets

### Issue 2: EC2 Consumer Can't Connect to MSK
**Symptoms**: Consumer service fails to start or connect
**Solutions**:
- Verify security group allows port 9096
- Check SCRAM credentials in Secrets Manager
- Ensure MSK cluster is in ACTIVE state

### Issue 3: IoT Rule Not Triggering
**Symptoms**: Messages published to IoT Core don't reach MSK
**Solutions**:
- Verify IoT rule SQL query syntax
- Check IoT rule permissions
- Ensure VPC destination is correctly configured

## Final Verification Commands

```bash
# 1. Check all AWS resources exist
aws kafka list-clusters --region ap-northeast-2
aws iot list-things --region ap-northeast-2
aws ec2 describe-instances --region ap-northeast-2

# 2. Verify configuration consistency
cat terraform.tfvars  # Ensure psw0507 in all relevant fields

# 3. Test end-to-end flow
python iot_publisher.py --test

# 4. Monitor consumer output
ssh -i psw0507-key.pem ec2-user@<EC2_PUBLIC_IP>
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer
```

## Success Criteria

✅ **Deployment Successful When:**
- All resources created with psw0507 naming convention
- EC2 instance accessible via SSH
- Consumer service running and auto-starting
- IoT messages successfully routed to MSK
- Consumer receives and processes messages
- All monitoring and logging functional

---

**All resources are created with the psw0507 identifier! 🎯✨**

This checklist ensures comprehensive verification of the psw0507 deployment. Use this document to systematically verify each component of your IoT-MSK-EC2 pipeline.
