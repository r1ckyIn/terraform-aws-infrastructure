# -----------------------------------------------------------------------------
# VPC OUTPUTS
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

# -----------------------------------------------------------------------------
# ALB OUTPUTS
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_endpoint" {
  description = "Application endpoint URL"
  value       = module.alb.endpoint_url
}

# -----------------------------------------------------------------------------
# EC2 OUTPUTS
# -----------------------------------------------------------------------------

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2.asg_name
}

# -----------------------------------------------------------------------------
# RDS OUTPUTS
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.db_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_port
}
