data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# IAM Policy for EC2 to access Secrets Manager and CloudWatch
resource "aws_iam_role_policy" "ec2" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Data source to get MSK credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "msk_credentials" {
  secret_id = var.secret_arn
}

locals {
  msk_credentials = jsondecode(data.aws_secretsmanager_secret_version.msk_credentials.secret_string)
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name              = var.project_name
    secret_name              = var.secret_name
    bootstrap_brokers        = var.bootstrap_brokers_sasl_scram
    topic_name              = var.iot_topic_name
    username                = local.msk_credentials.username
    password                = local.msk_credentials.password
  }))
}

# EC2 Instance
resource "aws_instance" "consumer" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_pair_name

  vpc_security_group_ids = [var.ec2_security_group_id]
  subnet_id              = var.public_subnet_ids[0]  # Launch in public subnet
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = local.user_data

  tags = {
    Name = "${var.project_name}-consumer"
  }
}
