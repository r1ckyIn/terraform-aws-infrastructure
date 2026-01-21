# ALB Module

Creates an Application Load Balancer with target group and listeners.

## Features

- Internet-facing or internal ALB
- Automatic HTTPS redirect when certificate provided
- Configurable health checks
- Support for instance, IP, or Lambda targets
- Modern TLS 1.3 security policy

## Architecture

```
                   Internet
                      │
                      ▼
            ┌─────────────────┐
            │       ALB       │
            │   (Port 80/443) │
            └────────┬────────┘
                     │
         ┌───────────┴───────────┐
         │    Target Group       │
         │  (Health Checks)      │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
┌────────┐      ┌────────┐      ┌────────┐
│  EC2   │      │  EC2   │      │  EC2   │
│ (AZ-a) │      │ (AZ-b) │      │ (AZ-c) │
└────────┘      └────────┘      └────────┘
```

## Usage

### HTTP Only (Development)

```hcl
module "alb" {
  source = "../../modules/alb"

  name              = "my-app-dev"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id

  target_port = 8080

  health_check = {
    path    = "/health"
    matcher = "200"
  }

  tags = {
    Environment = "dev"
  }
}
```

### HTTPS with Certificate (Production)

```hcl
module "alb" {
  source = "../../modules/alb"

  name              = "my-app-prod"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id

  # Enable deletion protection in production
  enable_deletion_protection = true

  target_port = 8080

  # HTTPS configuration
  certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/xxx"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  health_check = {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Environment = "prod"
  }
}
```

### Internal ALB

```hcl
module "alb" {
  source = "../../modules/alb"

  name              = "my-internal-app"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_app_subnet_ids
  security_group_id = module.security_groups.internal_alb_security_group_id

  # Internal ALB
  internal = true

  target_port = 8080

  tags = {
    Environment = "prod"
    Type        = "internal"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for ALB resources | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | Public subnet IDs (min 2) | `list(string)` | n/a | yes |
| security_group_id | Security group ID | `string` | n/a | yes |
| internal | Internal ALB (not internet-facing) | `bool` | `false` | no |
| enable_deletion_protection | Enable deletion protection | `bool` | `false` | no |
| idle_timeout | Idle timeout in seconds | `number` | `60` | no |
| target_port | Port for targets | `number` | `8080` | no |
| target_protocol | Protocol for targets | `string` | `"HTTP"` | no |
| target_type | Target type | `string` | `"instance"` | no |
| health_check | Health check configuration | `object` | see below | no |
| certificate_arn | ACM certificate ARN for HTTPS | `string` | `null` | no |
| ssl_policy | SSL policy for HTTPS | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| tags | Common tags | `map(string)` | `{}` | no |

### Health Check Defaults

```hcl
health_check = {
  path                = "/health"
  port                = "traffic-port"
  protocol            = "HTTP"
  healthy_threshold   = 2
  unhealthy_threshold = 3
  timeout             = 5
  interval            = 30
  matcher             = "200"
}
```

## Outputs

| Name | Description |
|------|-------------|
| alb_id | The ID of the ALB |
| alb_arn | The ARN of the ALB |
| alb_dns_name | DNS name of the ALB |
| alb_zone_id | Zone ID for Route53 alias |
| target_group_arn | ARN of the target group |
| http_listener_arn | ARN of HTTP listener |
| https_listener_arn | ARN of HTTPS listener (if enabled) |
| endpoint_url | Full URL to access the application |

## Listener Behavior

| Certificate | HTTP (80) | HTTPS (443) |
|-------------|-----------|-------------|
| Not provided | Forward to target | Not created |
| Provided | Redirect to HTTPS | Forward to target |

## SSL Policy Options

| Policy | TLS Versions | Recommended For |
|--------|--------------|-----------------|
| `ELBSecurityPolicy-TLS13-1-2-2021-06` | TLS 1.2, 1.3 | Default, modern |
| `ELBSecurityPolicy-TLS-1-2-2017-01` | TLS 1.2 only | Compatibility |
| `ELBSecurityPolicy-FS-1-2-Res-2020-10` | TLS 1.2, FS | High security |
