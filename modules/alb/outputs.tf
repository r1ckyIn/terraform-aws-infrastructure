# -----------------------------------------------------------------------------
# ALB OUTPUTS
# -----------------------------------------------------------------------------

output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = <<-EOT
    DNS name of the Application Load Balancer.
    Use this to:
      - Create a CNAME record in Route53
      - Configure CloudFront origin
      - Test the application endpoint
  EOT
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

# -----------------------------------------------------------------------------
# TARGET GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "target_group_arn" {
  description = "ARN of the target group for registering targets"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.main.name
}

output "target_group_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb_target_group.main.arn_suffix
}

# -----------------------------------------------------------------------------
# LISTENER OUTPUTS
# -----------------------------------------------------------------------------

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null if HTTPS not enabled)"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

# -----------------------------------------------------------------------------
# CONVENIENCE OUTPUTS
# -----------------------------------------------------------------------------

output "https_enabled" {
  description = "Whether HTTPS is enabled on this ALB"
  value       = local.https_enabled
}

output "endpoint_url" {
  description = "URL to access the application"
  value       = local.https_enabled ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}
