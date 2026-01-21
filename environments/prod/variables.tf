# -----------------------------------------------------------------------------
# GENERAL VARIABLES
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# -----------------------------------------------------------------------------
# VPC VARIABLES
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (set to false for production HA)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# APPLICATION VARIABLES
# -----------------------------------------------------------------------------

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# DATABASE VARIABLES
# -----------------------------------------------------------------------------

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.large"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}
