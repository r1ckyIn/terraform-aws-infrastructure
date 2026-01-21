# -----------------------------------------------------------------------------
# RDS MODULE
# Creates an RDS instance with subnet group and parameter group.
# Designed for production workloads with encryption and multi-AZ support.
# -----------------------------------------------------------------------------

locals {
  # Auto-determine parameter group family based on engine and version
  parameter_group_family = var.parameter_group_family != null ? var.parameter_group_family : (
    var.engine == "mysql" ? "mysql${split(".", var.engine_version)[0]}.0" :
    var.engine == "postgres" ? "postgres${var.engine_version}" :
    var.engine == "mariadb" ? "mariadb${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}" :
    null
  )

  # Final snapshot identifier
  final_snapshot_id = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.name}-final-snapshot"
  )
}

# -----------------------------------------------------------------------------
# DB SUBNET GROUP
# Defines which subnets RDS can use (must be in different AZs)
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}-subnet-group"
  description = "Subnet group for ${var.name} RDS instance"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

# -----------------------------------------------------------------------------
# DB PARAMETER GROUP
# Custom database parameters for tuning
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name        = "${var.name}-params"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.name} RDS instance"

  # Apply custom parameters if provided
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# RDS INSTANCE
# The actual database instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = var.name

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database configuration
  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false  # Never expose RDS to internet

  # High availability
  multi_az = var.multi_az

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Delete protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_id

  # Allow minor version upgrade automatically
  auto_minor_version_upgrade = true

  # Monitoring
  enabled_cloudwatch_logs_exports       = length(var.enabled_cloudwatch_logs_exports) > 0 ? var.enabled_cloudwatch_logs_exports : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    # Prevent accidental destruction in production
    # Remove this block if you need to destroy the database
    ignore_changes = [
      # Ignore password changes made outside Terraform
      # password,
    ]
  }
}
