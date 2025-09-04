variable "project_name" {
  description = "Project name"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 security group ID"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "bootstrap_brokers_sasl_scram" {
  description = "MSK SASL SCRAM bootstrap brokers"
  type        = string
}

variable "iot_topic_name" {
  description = "IoT topic name"
  type        = string
}
