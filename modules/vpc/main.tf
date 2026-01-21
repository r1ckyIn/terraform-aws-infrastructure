# -----------------------------------------------------------------------------
# VPC MODULE
# Creates a production-grade VPC with public and private subnets across
# multiple availability zones, including NAT Gateway for outbound internet
# access from private subnets.
# -----------------------------------------------------------------------------

locals {
  # Calculate subnet CIDRs if not provided
  # Using /20 subnets within a /16 VPC gives plenty of IP addresses
  # Layout: public (0-2), private_app (3-5), private_db (6-8)
  az_count = length(var.availability_zones)

  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.cidr_block, 4, i)
  ]

  private_app_subnet_cidrs = length(var.private_app_subnet_cidrs) > 0 ? var.private_app_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.cidr_block, 4, i + local.az_count)
  ]

  private_db_subnet_cidrs = length(var.private_db_subnet_cidrs) > 0 ? var.private_db_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.cidr_block, 4, i + local.az_count * 2)
  ]

  # NAT Gateway count: 1 if single_nat_gateway, otherwise one per AZ
  nat_gateway_count = var.single_nat_gateway ? 1 : local.az_count
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# Provides internet access for resources in public subnets
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# -----------------------------------------------------------------------------
# PUBLIC SUBNETS
# Resources here can have public IP addresses and direct internet access
# Typically used for: Load Balancers, Bastion hosts, NAT Gateways
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

# -----------------------------------------------------------------------------
# PRIVATE APPLICATION SUBNETS
# Resources here have no direct internet access (outbound via NAT)
# Typically used for: Application servers, containers, compute resources
# -----------------------------------------------------------------------------

resource "aws_subnet" "private_app" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-app-${var.availability_zones[count.index]}"
    Tier = "private-app"
  })
}

# -----------------------------------------------------------------------------
# PRIVATE DATABASE SUBNETS
# Most isolated tier - no internet access at all (not even outbound)
# Typically used for: RDS, ElastiCache, other data stores
# -----------------------------------------------------------------------------

resource "aws_subnet" "private_db" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-db-${var.availability_zones[count.index]}"
    Tier = "private-db"
  })
}

# -----------------------------------------------------------------------------
# ELASTIC IPs FOR NAT GATEWAYS
# Static IPs that persist even if NAT Gateway is recreated
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name}-nat-eip" : "${var.name}-nat-eip-${var.availability_zones[count.index]}"
  })

  # EIP requires IGW to exist before allocation in VPC
  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT GATEWAYS
# Provides outbound internet access for private subnets
# Single NAT for cost savings (dev/staging) or per-AZ for HA (prod)
# NOTE: NAT Gateway costs ~$32/month per gateway + data processing charges
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name}-nat" : "${var.name}-nat-${var.availability_zones[count.index]}"
  })

  # NAT Gateway requires IGW to be fully created first
  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# ROUTE TABLES
# -----------------------------------------------------------------------------

# Public route table - routes to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

# Private route tables - routes to NAT Gateway
# One per AZ if using per-AZ NAT, otherwise single table for all private subnets
resource "aws_route_table" "private" {
  count = local.nat_gateway_count

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name}-private-rt" : "${var.name}-private-rt-${var.availability_zones[count.index]}"
  })
}

# -----------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATIONS
# -----------------------------------------------------------------------------

# Public subnets use the public route table
resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private app subnets use private route tables
# If single NAT, all use the same route table; otherwise, each AZ has its own
resource "aws_route_table_association" "private_app" {
  count = local.az_count

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# Private DB subnets - no route to NAT (most isolated)
# Create a separate route table with no internet route
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  # No routes to internet - completely isolated
  # Only VPC-internal traffic is allowed

  tags = merge(var.tags, {
    Name = "${var.name}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db" {
  count = local.az_count

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
