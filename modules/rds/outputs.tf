# -----------------------------------------------------------------------------
# RDS MODULE OUTPUTS
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INSTANCE OUTPUTS
# -----------------------------------------------------------------------------

output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = aws_db_instance.main.identifier
}

# -----------------------------------------------------------------------------
# CONNECTION OUTPUTS
# -----------------------------------------------------------------------------

output "db_endpoint" {
  description = <<-EOT
    The connection endpoint in address:port format.
    Use this in your application configuration.
  EOT
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "The master username for the database"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# -----------------------------------------------------------------------------
# CONNECTION STRING OUTPUTS
# -----------------------------------------------------------------------------

output "connection_string_mysql" {
  description = "MySQL connection string (without password)"
  value       = var.engine == "mysql" ? "mysql://${aws_db_instance.main.username}:PASSWORD@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}" : null
}

output "connection_string_postgres" {
  description = "PostgreSQL connection string (without password)"
  value       = var.engine == "postgres" ? "postgresql://${aws_db_instance.main.username}:PASSWORD@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}" : null
}

# -----------------------------------------------------------------------------
# SUBNET GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "db_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

# -----------------------------------------------------------------------------
# PARAMETER GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "db_parameter_group_id" {
  description = "The ID of the DB parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_name" {
  description = "The name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
}

# -----------------------------------------------------------------------------
# STATUS OUTPUTS
# -----------------------------------------------------------------------------

output "db_availability_zone" {
  description = "The availability zone of the instance"
  value       = aws_db_instance.main.availability_zone
}

output "db_multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = aws_db_instance.main.multi_az
}

output "db_engine" {
  description = "The database engine"
  value       = aws_db_instance.main.engine
}

output "db_engine_version_actual" {
  description = "The running version of the database"
  value       = aws_db_instance.main.engine_version_actual
}
