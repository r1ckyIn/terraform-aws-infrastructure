# -----------------------------------------------------------------------------
# ALB MODULE
# Creates an Application Load Balancer with target group and listeners.
# Supports both HTTP-only and HTTPS configurations.
# -----------------------------------------------------------------------------

locals {
  # Whether HTTPS is enabled (certificate provided)
  https_enabled = var.certificate_arn != null
}

# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

# -----------------------------------------------------------------------------
# TARGET GROUP
# Defines how to route traffic to registered targets (EC2 instances)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "main" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = var.target_protocol
  vpc_id   = var.vpc_id

  target_type = var.target_type

  # Deregistration delay: time to wait before removing instance from rotation
  # Lower value for faster deployments, higher for graceful shutdown
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check.path
    port                = var.health_check.port
    protocol            = var.health_check.protocol
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    timeout             = var.health_check.timeout
    interval            = var.health_check.interval
    matcher             = var.health_check.matcher
  }

  tags = merge(var.tags, {
    Name = "${var.name}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# HTTP LISTENER
# When HTTPS is enabled: Redirects all HTTP traffic to HTTPS
# When HTTPS is disabled: Forwards traffic to target group
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # If HTTPS enabled, redirect to HTTPS; otherwise, forward to target
  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-http-listener"
  })
}

# -----------------------------------------------------------------------------
# HTTPS LISTENER (Optional)
# Only created when certificate_arn is provided
# Forwards traffic to target group with TLS termination at ALB
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = var.ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name = "${var.name}-https-listener"
  })
}
