# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# KMS Module
module "kms" {
  source = "./modules/kms"

  project_name = var.project_name
  aws_region   = var.aws_region
}

# Secrets Manager Module
module "secrets" {
  source = "./modules/secrets"

  project_name       = var.project_name
  kms_key_id         = module.kms.kms_key_id
  msk_scram_username = var.msk_scram_username
  msk_scram_password = var.msk_scram_password

  depends_on = [module.kms]
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name          = var.project_name
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  private_subnet_names = var.private_subnet_names
  public_subnet_cidrs  = var.public_subnet_cidrs
  public_subnet_names  = var.public_subnet_names
}

# MSK Module
module "msk" {
  source = "./modules/msk"

  project_name           = var.project_name
  private_subnet_ids     = module.networking.private_subnet_ids
  msk_security_group_id  = module.networking.msk_security_group_id
  msk_instance_type      = var.msk_instance_type
  msk_volume_size        = var.msk_volume_size
  kms_key_id            = module.kms.kms_key_id
  kms_key_arn           = module.kms.kms_key_arn
  secret_arn            = module.secrets.secret_arn

  depends_on = [
    module.kms,
    module.secrets,
    module.networking
  ]
}

# IoT Module
module "iot" {
  source = "./modules/iot"

  project_name                 = var.project_name
  environment                  = var.environment
  iot_thing_name              = var.iot_thing_name
  iot_topic_name              = var.iot_topic_name
  vpc_id                      = module.networking.vpc_id
  private_subnet_ids          = module.networking.private_subnet_ids
  msk_security_group_id       = module.networking.msk_security_group_id
  bootstrap_brokers_sasl_scram = module.msk.bootstrap_brokers_sasl_scram
  msk_scram_username          = var.msk_scram_username
  secret_arn                  = module.secrets.secret_arn
  kms_key_arn                 = module.kms.kms_key_arn

  depends_on = [
    module.msk,
    module.networking
  ]
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  project_name                 = var.project_name
  ec2_instance_type           = var.ec2_instance_type
  ec2_key_pair_name           = var.ec2_key_pair_name
  public_subnet_ids           = module.networking.public_subnet_ids
  ec2_security_group_id       = module.networking.ec2_security_group_id
  secret_arn                  = module.secrets.secret_arn
  secret_name                 = module.secrets.secret_name
  kms_key_arn                 = module.kms.kms_key_arn
  bootstrap_brokers_sasl_scram = module.msk.bootstrap_brokers_sasl_scram
  iot_topic_name              = var.iot_topic_name

  depends_on = [
    module.msk,
    module.secrets,
    module.networking
  ]
}
