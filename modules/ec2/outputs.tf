# -----------------------------------------------------------------------------
# EC2 MODULE OUTPUTS
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LAUNCH TEMPLATE OUTPUTS
# -----------------------------------------------------------------------------

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.main.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

# -----------------------------------------------------------------------------
# AUTO SCALING GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

# -----------------------------------------------------------------------------
# IAM OUTPUTS
# -----------------------------------------------------------------------------

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

# -----------------------------------------------------------------------------
# AMI OUTPUTS
# -----------------------------------------------------------------------------

output "ami_id" {
  description = "AMI ID used for instances"
  value       = local.ami_id
}
