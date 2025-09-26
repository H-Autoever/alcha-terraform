variable "aws_region" {
  description = "AWS region for ECR login and other operations"
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry domain, e.g. 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com"
  type        = string
}

variable "ecr_repository_connector" {
  description = "ECR repository name : alcha/connector"
  type        = string
}

variable "ecr_repository_frontend" {
  description = "ECR repository name : alcha/frontend"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g., latest or git sha)"
  type        = string
  default     = "latest"
}

variable "kafka_bootstrap" {
  description = "Kafka bootstrap servers"
  type        = string
}

variable "kafka_group_id" {
  description = "Kafka consumer group id"
  type        = string
}

variable "kafka_security_protocol" {
  description = "Kafka security protocol"
  type        = string
  default     = "SASL_SSL"
}

variable "kafka_sasl_mechanism" {
  description = "Kafka SASL mechanism"
  type        = string
  default     = "SCRAM-SHA-512"
}

variable "kafka_sasl_username" {
  description = "Kafka SASL username"
  type        = string
}

variable "kafka_sasl_password" {
  description = "Kafka SASL password"
  type        = string
  sensitive   = true
}

variable "mongo_uri" {
  description = "MongoDB connection URI"
  type        = string
}

variable "mongo_db_name" {
  description = "MongoDB database name"
  type        = string
}

variable "alcha_backend_port" {
  description = "Alcha backend port (if needed by env)"
  type        = number
  default     = 9090
}

variable "redis_host" {
  description = "Redis host"
  type        = string
  default     = "redis"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}
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
