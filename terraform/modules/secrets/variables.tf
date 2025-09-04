variable "project_name" {
  description = "Project name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "msk_scram_username" {
  description = "MSK SCRAM username"
  type        = string
}

variable "msk_scram_password" {
  description = "MSK SCRAM password"
  type        = string
  sensitive   = true
}
