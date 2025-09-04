variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "iot-msk-pipeline-psw0507"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "psw0507"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "vpc-iot-msk-psw0507"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_names" {
  description = "Names for private subnets"
  type        = list(string)
  default     = ["private-subnet-psw0507-1", "private-subnet-psw0507-2"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "public_subnet_names" {
  description = "Names for public subnets"
  type        = list(string)
  default     = ["public-subnet-psw0507-1", "public-subnet-psw0507-2"]
}

variable "msk_instance_type" {
  description = "MSK broker instance type"
  type        = string
  default     = "kafka.t3.small"
}

variable "msk_volume_size" {
  description = "MSK broker volume size in GB"
  type        = number
  default     = 100
}

variable "ec2_instance_type" {
  description = "EC2 instance type for consumer"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "psw0507-key"
}

variable "msk_scram_username" {
  description = "MSK SCRAM username"
  type        = string
  default     = "iotuser-psw0507"
}

variable "msk_scram_password" {
  description = "MSK SCRAM password"
  type        = string
  sensitive   = true
  default     = "SecurePassword123!"
}

variable "iot_thing_name" {
  description = "IoT Thing name"
  type        = string
  default     = "test-psw0507"
}

variable "iot_topic_name" {
  description = "MSK topic name for IoT data"
  type        = string
  default     = "iot-sensor-data"
}
