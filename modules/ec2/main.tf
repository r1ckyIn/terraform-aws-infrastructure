# -----------------------------------------------------------------------------
# EC2 MODULE
# Creates an Auto Scaling Group with Launch Template for application instances.
# Uses SSM Session Manager for access instead of SSH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

# Get current AWS region
data "aws_region" "current" {}

# Get latest Amazon Linux 2023 AMI if not specified
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id

  # User data: use custom if provided, otherwise use template
  user_data = var.custom_user_data != null ? var.custom_user_data : base64encode(
    templatefile("${path.module}/user_data.sh.tpl", {
      app_port    = var.user_data_vars.app_port
      environment = var.user_data_vars.environment
    })
  )
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR EC2 INSTANCES
# Allows SSM Session Manager access and CloudWatch logging
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-ec2-role"
  })
}

# SSM Session Manager - allows secure shell access without SSH
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent - for metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile - attaches role to EC2 instances
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# LAUNCH TEMPLATE
# Defines the configuration for EC2 instances
# -----------------------------------------------------------------------------

resource "aws_launch_template" "main" {
  name_prefix   = "${var.name}-lt-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Security
  vpc_security_group_ids = [var.security_group_id]

  # IAM role for SSM and CloudWatch
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  # Enable IMDSv2 (more secure instance metadata service)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Root volume configuration
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Enable detailed monitoring
  monitoring {
    enabled = var.enable_monitoring
  }

  # User data script
  user_data = local.user_data

  # Instance tags
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name}-volume"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name}-launch-template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# AUTO SCALING GROUP
# Manages the fleet of EC2 instances
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  # Health checks
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  # Use latest version of launch template
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Attach to ALB target group
  target_group_arns = [var.target_group_arn]

  # Instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Tags propagated to instances
  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.name}-asg-instance"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# AUTO SCALING POLICIES
# Automatically scale based on CPU utilization
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count = var.enable_cpu_autoscaling ? 1 : 0

  name                   = "${var.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.cpu_target_value
    disable_scale_in = false
  }
}
