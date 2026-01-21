# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for all security group resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "app_port" {
  description = "Port on which the application listens (e.g., 8080, 3000)"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "App port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = <<-EOT
    Port for database connections.
    Common values: 3306 (MySQL), 5432 (PostgreSQL), 1433 (SQL Server)
  EOT
  type        = number
  default     = 3306

  validation {
    condition     = var.db_port > 0 && var.db_port < 65536
    error_message = "DB port must be between 1 and 65535."
  }
}

variable "allowed_http_cidrs" {
  description = <<-EOT
    CIDR blocks allowed to access ALB on HTTP (port 80).
    Default is 0.0.0.0/0 (public access) for load balancers.
    Restrict this for internal applications.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_https_cidrs" {
  description = <<-EOT
    CIDR blocks allowed to access ALB on HTTPS (port 443).
    Default is 0.0.0.0/0 (public access) for load balancers.
    Restrict this for internal applications.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
