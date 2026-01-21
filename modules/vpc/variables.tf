# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "single_nat_gateway" {
  description = <<-EOT
    Use a single NAT Gateway for all private subnets.
    Set to true for cost savings in dev/staging environments.
    Set to false for high availability in production (one NAT per AZ).
  EOT
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for public subnets.
    If not provided, will be auto-calculated from VPC CIDR.
    Must have same length as availability_zones.
  EOT
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for private application subnets.
    If not provided, will be auto-calculated from VPC CIDR.
    Must have same length as availability_zones.
  EOT
  type        = list(string)
  default     = []
}

variable "private_db_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for private database subnets.
    If not provided, will be auto-calculated from VPC CIDR.
    Must have same length as availability_zones.
  EOT
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
