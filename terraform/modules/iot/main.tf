data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# IoT Thing
resource "aws_iot_thing" "main" {
  name = var.iot_thing_name

  attributes = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for IoT
resource "aws_cloudwatch_log_group" "iot" {
  name              = "/aws/iot/${var.project_name}"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.project_name}-iot-logs"
  }
}

# IAM Role for IoT Rule
resource "aws_iam_role" "iot_rule" {
  name = "IoTLogsRole-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "IoTLogsRole-${var.project_name}"
  }
}

# IAM Policy for IoT Rule (PowerUserAccess for broad permissions)
resource "aws_iam_role_policy_attachment" "iot_rule_poweruser" {
  role       = aws_iam_role.iot_rule.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "iot_rule_secrets" {
  name = "${var.project_name}-iot-secrets-policy"
  role = aws_iam_role.iot_rule.id

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
      }
    ]
  })
}

# VPC Destination for IoT Rule
resource "aws_iot_topic_rule_destination" "msk" {
  enabled = true

  vpc_configuration {
    subnet_ids      = var.private_subnet_ids
    security_groups = [var.msk_security_group_id]
    vpc_id          = var.vpc_id
    role_arn        = aws_iam_role.iot_rule.arn
  }
}

# IoT Topic Rule for MSK
resource "aws_iot_topic_rule" "msk" {
  name        = "${replace(var.project_name, "-", "")}MSKRule"
  description = "Route IoT messages to MSK cluster"
  enabled     = true
  sql         = "SELECT *, topic() as source_topic FROM 'topic/+'"
  sql_version = "2015-10-08"

  kafka {
    destination_arn = aws_iot_topic_rule_destination.msk.arn
    topic          = var.iot_topic_name
    client_properties = {
      "bootstrap.servers"  = var.bootstrap_brokers_sasl_scram
      "security.protocol"  = "SASL_SSL"
      "sasl.mechanism"     = "SCRAM-SHA-512"
      "sasl.scram.username" = "$${get_secret('${var.secret_arn}','SecretString','username','${aws_iam_role.iot_rule.arn}')}"
      "sasl.scram.password" = "$${get_secret('${var.secret_arn}','SecretString','password','${aws_iam_role.iot_rule.arn}')}"
    }
  }

  cloudwatch_logs {
    log_group_name = aws_cloudwatch_log_group.iot.name
    role_arn      = aws_iam_role.iot_rule.arn
  }

  depends_on = [
    aws_iot_topic_rule_destination.msk,
    aws_iam_role_policy_attachment.iot_rule_poweruser
  ]

  tags = {
    Name = "${var.project_name}-msk-rule"
  }
}
