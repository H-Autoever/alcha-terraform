variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "iot_thing_name" {
  description = "IoT Thing name"
  type        = string
}

variable "iot_topic_name" {
  description = "MSK topic name for IoT data"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "msk_security_group_id" {
  description = "MSK security group ID"
  type        = string
}

variable "bootstrap_brokers_sasl_scram" {
  description = "MSK SASL SCRAM bootstrap brokers"
  type        = string
}

variable "msk_scram_username" {
  description = "MSK SCRAM username"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}
