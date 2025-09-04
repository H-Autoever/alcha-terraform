# KMS Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = module.kms.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = module.kms.kms_key_arn
  sensitive   = true
}

# Secrets Manager Outputs
output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = module.secrets.secret_arn
  sensitive   = true
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = module.secrets.secret_name
}

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# MSK Outputs
output "msk_cluster_arn" {
  description = "MSK cluster ARN"
  value       = module.msk.msk_cluster_arn
}

output "msk_cluster_name" {
  description = "MSK cluster name"
  value       = module.msk.msk_cluster_name
}

output "bootstrap_brokers_sasl_scram" {
  description = "MSK SASL SCRAM bootstrap brokers"
  value       = module.msk.bootstrap_brokers_sasl_scram
  sensitive   = true
}

# IoT Outputs
output "iot_thing_name" {
  description = "IoT Thing name"
  value       = module.iot.iot_thing_name
}

output "iot_rule_name" {
  description = "IoT Rule name"
  value       = module.iot.iot_rule_name
}

output "vpc_destination_arn" {
  description = "VPC destination ARN"
  value       = module.iot.vpc_destination_arn
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.ec2_instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.ec2_public_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = module.ec2.ssh_command
}

# Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    aws_region      = var.aws_region
    vpc_id          = module.networking.vpc_id
    msk_cluster     = module.msk.msk_cluster_name
    iot_thing       = module.iot.iot_thing_name
    iot_rule        = module.iot.iot_rule_name
    ec2_instance    = module.ec2.ec2_instance_id
    ec2_public_ip   = module.ec2.ec2_public_ip
  }
}
