# -----------------------------------------------------------------------------
# VPC OUTPUTS
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# -----------------------------------------------------------------------------
# SUBNET OUTPUTS
# -----------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs for deploying application servers"
  value       = aws_subnet.private_app[*].id
}

output "private_app_subnet_cidrs" {
  description = "List of private application subnet CIDR blocks"
  value       = aws_subnet.private_app[*].cidr_block
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs for deploying RDS and other data stores"
  value       = aws_subnet.private_db[*].id
}

output "private_db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks"
  value       = aws_subnet.private_db[*].cidr_block
}

# -----------------------------------------------------------------------------
# GATEWAY OUTPUTS
# -----------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# -----------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
# -----------------------------------------------------------------------------

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "private_db_route_table_id" {
  description = "The ID of the private database route table (no internet access)"
  value       = aws_route_table.private_db.id
}

# -----------------------------------------------------------------------------
# AVAILABILITY ZONE OUTPUTS
# -----------------------------------------------------------------------------

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "az_count" {
  description = "Number of availability zones used"
  value       = length(var.availability_zones)
}
