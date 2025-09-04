variable "project_name" {
  description = "Project name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for MSK"
  type        = list(string)
}

variable "msk_security_group_id" {
  description = "Security group ID for MSK"
  type        = string
}

variable "msk_instance_type" {
  description = "MSK broker instance type"
  type        = string
}

variable "msk_volume_size" {
  description = "MSK broker volume size in GB"
  type        = number
}

variable "kms_key_id" {
  description = "KMS key ID"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}
