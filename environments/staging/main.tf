# -----------------------------------------------------------------------------
# STAGING ENVIRONMENT
# Pre-production environment for testing and validation
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name_prefix
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SECURITY
# -----------------------------------------------------------------------------

module "security_groups" {
  source = "../../modules/security-groups"

  name     = local.name_prefix
  vpc_id   = module.vpc.vpc_id
  app_port = var.app_port
  db_port  = var.db_port

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# LOAD BALANCER
# -----------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id

  target_port = var.app_port

  health_check = {
    path    = "/health"
    matcher = "200"
  }

  # Staging: enable deletion protection
  enable_deletion_protection = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# COMPUTE
# -----------------------------------------------------------------------------

module "ec2" {
  source = "../../modules/ec2"

  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_app_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  target_group_arn  = module.alb.target_group_arn

  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  user_data_vars = {
    app_port    = var.app_port
    environment = var.environment
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DATABASE
# -----------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  name              = local.name_prefix
  subnet_ids        = module.vpc.private_db_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  port              = var.db_port

  # Staging settings
  multi_az            = var.db_multi_az
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot

  tags = local.common_tags
}
