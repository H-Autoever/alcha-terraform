# IoT-MSK-EC2 Pipeline

## Overview

A real-time IoT data pipeline using AWS IoT Core, Amazon MSK (Managed Streaming for Apache Kafka), and EC2 for streaming data processing.

## Architecture

```
IoT Device → AWS IoT Core → Amazon MSK → EC2 Consumer
```

### Components

- **AWS IoT Core**: Collects data from IoT devices
- **Amazon MSK**: Kafka cluster for streaming data processing
- **EC2**: Consumes data from MSK for real-time processing

## Infrastructure Components

### AWS IoT Core
- **Thing**: test-psw0507
- **Topic**: topic/test
- **Rule**: Routes messages to MSK

### Amazon MSK
- **Version**: Kafka 3.5.1
- **Authentication**: SCRAM-SHA-512
- **Encryption**: TLS + KMS
- **Monitoring**: CloudWatch logging

### EC2 Consumer
- **Instance Type**: t3.micro
- **OS**: Amazon Linux 2
- **Language**: Python 3
- **Libraries**: confluent-kafka, boto3

### Networking
- **VPC**: Custom VPC with public/private subnets
- **Security**: Security groups for MSK and EC2
- **High Availability**: Multi-AZ deployment

## Prerequisites

### Required Tools
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- Python 3.7+ (for local testing)

### AWS Permissions
- IAM permissions for IoT Core, MSK, EC2, VPC
- Secrets Manager access
- CloudWatch logs access

## Quick Start

### 1. Infrastructure Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Test Message Publishing

```bash
cd app

# Create Python virtual environment
python -m venv venv

# Activate virtual environment
# Linux/Mac:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# Install dependencies
pip install boto3

# Send test message
python iot_publisher.py --test
```

## Usage

### 1. Single Test Message

```bash
python iot_publisher.py --test
```

### 2. Continuous Message Streaming

```bash
python iot_publisher.py
```

### 3. EC2 Consumer Status Check

```bash
# SSH to EC2 instance
ssh -i psw0507-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check consumer service status
sudo systemctl status iot-msk-pipeline-psw0507-consumer

# View real-time logs
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer
```

## Message Flow

### Message Format

```json
{
  "device_id": "test-psw0507",
  "timestamp": "2025-09-04T04:50:27.474600Z",
  "temperature": 30.91,
  "humidity": 61.96,
  "pressure": 1012.84,
  "location": {
    "latitude": 37.419712,
    "longitude": 126.821186
  },
  "battery_level": 84,
  "signal_strength": -55,
  "message": "Test message"
}
```

### Data Flow Process

1. **IoT Publisher** → Sends JSON message to IoT Core
2. **IoT Rule** → Routes message from `topic/test` to MSK
3. **MSK Kafka** → Stores message in Kafka topic
4. **EC2 Consumer** → Reads and processes messages from MSK

## Monitoring

### CloudWatch Logs
- IoT Core logs: `/aws/iot/iot-msk-pipeline-psw0507`
- MSK logs: `/aws/msk/iot-msk-pipeline-psw0507`

### Consumer Logs
```bash
# View consumer logs on EC2
sudo journalctl -f -u iot-msk-pipeline-psw0507-consumer

# Check consumer status
sudo systemctl status iot-msk-pipeline-psw0507-consumer
```

## Security

### Authentication
- **MSK**: SCRAM-SHA-512 with AWS Secrets Manager
- **EC2**: IAM roles and security groups
- **IoT Core**: IAM policies for device authentication

### Encryption
- **In Transit**: TLS encryption for all communications
- **At Rest**: KMS encryption for MSK and Secrets Manager

## Troubleshooting

### Common Issues

#### 1. Consumer Not Receiving Messages
```bash
# Check MSK connectivity
aws kafka describe-cluster --cluster-arn <MSK_CLUSTER_ARN>

# Verify secrets
aws secretsmanager get-secret-value --secret-id AmazonMSK_iotuser-psw0507
```

#### 2. IoT Rule Not Triggering
```bash
# Check IoT logs
aws logs filter-log-events --log-group-name /aws/iot/iot-msk-pipeline-psw0507
```

#### 3. EC2 Consumer Service Issues
```bash
# Restart consumer service
sudo systemctl restart iot-msk-pipeline-psw0507-consumer

# Check service logs
sudo journalctl -u iot-msk-pipeline-psw0507-consumer --since "1 hour ago"
```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform

# Destroy all resources
terraform destroy
```

**Warning**: This will delete all data and resources. Make sure to backup any important data before running destroy.

## Project Structure

```
IoT-MSK-EC2/
├── README.md
├── app/
│   ├── iot_publisher.py       # IoT message publisher
│   └── requirements.txt       # Python dependencies
└── terraform/
    ├── main.tf               # Main Terraform configuration
    ├── variables.tf          # Variable definitions
    ├── outputs.tf            # Output values
    ├── terraform.tfvars      # Variable values
    ├── DEPLOYMENT_GUIDE.md   # Detailed deployment guide
    ├── PSW0507_RESOURCE_CHECKLIST.md  # Resource checklist
    └── modules/
        ├── ec2/              # EC2 consumer module
        ├── iot/              # IoT Core module
        ├── msk/              # MSK cluster module
        ├── networking/       # VPC and networking
        ├── secrets/          # Secrets Manager
        └── kms/              # KMS encryption
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
