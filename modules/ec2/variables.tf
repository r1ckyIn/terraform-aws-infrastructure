# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for EC2 resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instances will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Auto Scaling Group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least 1 subnet is required."
  }
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for ALB attachment"
  type        = string
}

# -----------------------------------------------------------------------------
# INSTANCE CONFIGURATION
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = <<-EOT
    AMI ID to use for instances.
    If not provided, the latest Amazon Linux 2023 AMI will be used.
  EOT
  type        = string
  default     = null
}

variable "key_name" {
  description = <<-EOT
    EC2 key pair name for SSH access.
    Not recommended - use SSM Session Manager instead.
  EOT
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root EBS volume (gp3, gp2, io1)"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# AUTO SCALING CONFIGURATION
# -----------------------------------------------------------------------------

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.asg_min_size >= 0
    error_message = "Minimum size must be >= 0."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.asg_max_size >= 1
    error_message = "Maximum size must be >= 1."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "health_check_grace_period" {
  description = "Time (seconds) after launch before health check starts"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "ELB"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be EC2 or ELB."
  }
}

# -----------------------------------------------------------------------------
# SCALING POLICY CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_cpu_autoscaling" {
  description = "Enable CPU-based auto scaling"
  type        = bool
  default     = true
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target must be between 1 and 100."
  }
}

# -----------------------------------------------------------------------------
# USER DATA CONFIGURATION
# -----------------------------------------------------------------------------

variable "user_data_vars" {
  description = <<-EOT
    Variables to pass to user_data template.
    Available in template as var.app_port, var.environment, etc.
  EOT
  type = object({
    app_port    = optional(number, 8080)
    environment = optional(string, "dev")
  })
  default = {}
}

variable "custom_user_data" {
  description = <<-EOT
    Custom user data script. If provided, overrides the default template.
    Must be base64 encoded.
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
