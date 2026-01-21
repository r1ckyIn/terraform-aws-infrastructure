# -----------------------------------------------------------------------------
# SECURITY GROUPS MODULE
# Implements security group chaining pattern:
# Internet -> ALB SG -> App SG -> RDS SG
#
# Key Design Decision: Use Security Group IDs (not CIDRs) for inter-tier
# communication. This ensures only resources in the specified security group
# can access the next tier, regardless of their IP address.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ALB SECURITY GROUP
# Allows HTTP/HTTPS traffic from the internet (or specified CIDRs)
# This is the entry point for all external traffic
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP ingress (port 80) - typically for redirect to HTTPS
resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidrs
  description = "Allow HTTP from specified CIDRs"
}

# HTTPS ingress (port 443)
resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.allowed_https_cidrs
  description = "Allow HTTPS from specified CIDRs"
}

# Egress to application tier only (principle of least privilege)
resource "aws_security_group_rule" "alb_app_egress" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "Allow traffic to application tier"
}

# -----------------------------------------------------------------------------
# APPLICATION SECURITY GROUP
# Only accepts traffic from ALB Security Group
# This ensures that application instances can only be accessed through the ALB
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow traffic from ALB only - using Security Group ID (not CIDR)
# This is the key security pattern: traffic can only come from resources
# that are members of the ALB security group
resource "aws_security_group_rule" "app_alb_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.app.id

  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB only"
}

# Allow instances to communicate with each other (for clustering)
resource "aws_security_group_rule" "app_self_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.app.id

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  self        = true
  description = "Allow inter-instance communication"
}

# Egress to database tier
resource "aws_security_group_rule" "app_db_egress" {
  type              = "egress"
  security_group_id = aws_security_group.app.id

  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow traffic to database tier"
}

# Egress to internet (for package updates, external APIs, etc.)
# NOTE: This goes through NAT Gateway for private subnets
resource "aws_security_group_rule" "app_https_egress" {
  type              = "egress"
  security_group_id = aws_security_group.app.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow HTTPS to internet (via NAT)"
}

# Egress for HTTP (some package repositories)
resource "aws_security_group_rule" "app_http_egress" {
  type              = "egress"
  security_group_id = aws_security_group.app.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow HTTP to internet (via NAT)"
}

# -----------------------------------------------------------------------------
# RDS SECURITY GROUP
# Only accepts traffic from Application Security Group
# Most restricted tier - only application instances can connect
# -----------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS database - app tier access only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow database connections from application tier only
# SECURITY: Using security group ID ensures only app instances can connect,
# regardless of IP address. This is more secure than CIDR-based rules.
resource "aws_security_group_rule" "rds_app_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.rds.id

  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "Allow database connections from application tier only"
}

# NOTE: No egress rules for RDS
# RDS doesn't need outbound internet access
# This provides defense in depth - even if compromised, it can't call out
