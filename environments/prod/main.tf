# -----------------------------------------------------------------------------
# PRODUCTION ENVIRONMENT
# Production environment with high availability and security settings
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
# Production: NAT Gateway per AZ for high availability
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name_prefix
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway # false for HA

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
# Production: deletion protection enabled
# -----------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id

  target_port = var.app_port

  health_check = {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Production: enable deletion protection
  enable_deletion_protection = true

  # Production: Add certificate for HTTPS
  # certificate_arn = var.acm_certificate_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# COMPUTE
# Production: larger instances, higher scaling limits
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

  # Longer grace period for production apps
  health_check_grace_period = 600

  user_data_vars = {
    app_port    = var.app_port
    environment = var.environment
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DATABASE
# Production: Multi-AZ enabled, deletion protection, larger instance
# -----------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  name              = local.name_prefix
  subnet_ids        = module.vpc.private_db_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 500 # Auto-scaling up to 500GB
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  port                  = var.db_port

  # Production settings
  multi_az                = var.db_multi_az
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
  backup_retention_period = 30

  # Enable monitoring
  performance_insights_enabled          = true
  performance_insights_retention_period = 731 # 2 years
  enabled_cloudwatch_logs_exports       = ["error", "slowquery"]

  tags = local.common_tags
}
