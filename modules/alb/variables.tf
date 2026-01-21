# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets in different AZs."
  }
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "internal" {
  description = "Whether the ALB is internal (not internet-facing)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on ALB"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

# Target Group Configuration
variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 8080
}

variable "target_protocol" {
  description = "Protocol for target traffic (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "Target protocol must be HTTP or HTTPS."
  }
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda)"
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "Target type must be instance, ip, or lambda."
  }
}

# Health Check Configuration
variable "health_check" {
  description = <<-EOT
    Health check configuration for target group.

    Attributes:
      - path: Health check endpoint path
      - port: Health check port (traffic-port uses target port)
      - protocol: Health check protocol
      - healthy_threshold: Consecutive successes before healthy
      - unhealthy_threshold: Consecutive failures before unhealthy
      - timeout: Health check timeout in seconds
      - interval: Health check interval in seconds
      - matcher: Success codes (e.g., "200" or "200-299")
  EOT
  type = object({
    path                = optional(string, "/health")
    port                = optional(string, "traffic-port")
    protocol            = optional(string, "HTTP")
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 3)
    timeout             = optional(number, 5)
    interval            = optional(number, 30)
    matcher             = optional(string, "200")
  })
  default = {}
}

# HTTPS Configuration (Optional)
variable "certificate_arn" {
  description = <<-EOT
    ARN of ACM certificate for HTTPS listener.
    If provided, HTTPS listener will be created on port 443.
    HTTP listener (port 80) will redirect to HTTPS.
    If not provided, only HTTP listener will be created.
  EOT
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
