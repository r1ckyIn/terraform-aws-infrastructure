# -----------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "Security group ARN for the Application Load Balancer"
  value       = aws_security_group.alb.arn
}

output "app_security_group_id" {
  description = "Security group ID for application instances"
  value       = aws_security_group.app.id
}

output "app_security_group_arn" {
  description = "Security group ARN for application instances"
  value       = aws_security_group.app.arn
}

output "rds_security_group_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.rds.id
}

output "rds_security_group_arn" {
  description = "Security group ARN for RDS database"
  value       = aws_security_group.rds.arn
}

# -----------------------------------------------------------------------------
# CONVENIENCE OUTPUTS
# -----------------------------------------------------------------------------

output "all_security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    rds = aws_security_group.rds.id
  }
}
