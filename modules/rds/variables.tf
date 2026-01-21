# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for RDS resources (will be used as DB identifier)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "subnet_ids" {
  description = "List of private database subnet IDs"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS requires at least 2 subnets in different AZs."
  }
}

variable "security_group_id" {
  description = "Security group ID for RDS instance"
  type        = string
}

# -----------------------------------------------------------------------------
# DATABASE CONFIGURATION
# -----------------------------------------------------------------------------

variable "engine" {
  description = "Database engine (mysql, postgres, mariadb)"
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres", "mariadb"], var.engine)
    error_message = "Engine must be mysql, postgres, or mariadb."
  }
}

variable "engine_version" {
  description = <<-EOT
    Database engine version.
    Examples: "8.0" for MySQL, "15" for PostgreSQL
  EOT
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "max_allocated_storage" {
  description = <<-EOT
    Maximum storage in GB for autoscaling.
    Set to 0 to disable storage autoscaling.
  EOT
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username for database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "password" {
  description = <<-EOT
    Master password for database.
    Must be at least 8 characters.
    Consider using AWS Secrets Manager in production.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.password) >= 8
    error_message = "Password must be at least 8 characters."
  }
}

variable "port" {
  description = "Database port (3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  default     = 3306
}

# -----------------------------------------------------------------------------
# HIGH AVAILABILITY & BACKUP
# -----------------------------------------------------------------------------

variable "multi_az" {
  description = <<-EOT
    Enable Multi-AZ deployment for high availability.
    Recommended for production workloads.
    Note: Doubles the cost.
  EOT
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range for system maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# -----------------------------------------------------------------------------
# SECURITY
# -----------------------------------------------------------------------------

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = <<-EOT
    Enable deletion protection.
    Recommended for production to prevent accidental deletion.
  EOT
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = <<-EOT
    Skip final snapshot when deleting.
    Set to false for production to ensure data is backed up before deletion.
  EOT
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot (required if skip_final_snapshot is false)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# MONITORING
# -----------------------------------------------------------------------------

variable "enabled_cloudwatch_logs_exports" {
  description = <<-EOT
    List of log types to export to CloudWatch.
    For MySQL: audit, error, general, slowquery
    For PostgreSQL: postgresql, upgrade
  EOT
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period (7 or 731 days)"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# PARAMETER GROUP
# -----------------------------------------------------------------------------

variable "parameter_group_family" {
  description = <<-EOT
    Parameter group family.
    If not specified, will be auto-determined from engine and version.
  EOT
  type        = string
  default     = null
}

variable "parameters" {
  description = "List of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
