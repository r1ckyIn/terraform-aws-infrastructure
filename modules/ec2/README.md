# EC2 Module

Creates an Auto Scaling Group with Launch Template for application instances.

## Features

- Auto Scaling Group with target tracking (CPU-based scaling)
- Launch Template with IMDSv2 (secure metadata service)
- SSM Session Manager access (no SSH keys needed)
- CloudWatch Agent for metrics and logs
- Encrypted EBS volumes
- Automatic ALB target group registration

## Architecture

```
                    ALB
                     │
                     ▼
         ┌───────────────────────┐
         │   Target Group        │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
┌────────┐      ┌────────┐      ┌────────┐
│  EC2   │      │  EC2   │      │  EC2   │
│ (AZ-a) │      │ (AZ-b) │      │ (AZ-c) │
└────────┘      └────────┘      └────────┘
    │                │                │
    └────────────────┼────────────────┘
                     │
         ┌───────────────────────┐
         │   Auto Scaling Group  │
         │   (min=2, max=10)     │
         └───────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "ec2" {
  source = "../../modules/ec2"

  name              = "my-app-dev"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_app_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  target_group_arn  = module.alb.target_group_arn

  instance_type        = "t3.micro"
  asg_min_size         = 1
  asg_max_size         = 2
  asg_desired_capacity = 1

  user_data_vars = {
    app_port    = 8080
    environment = "dev"
  }

  tags = {
    Environment = "dev"
  }
}
```

### Production Configuration

```hcl
module "ec2" {
  source = "../../modules/ec2"

  name              = "my-app-prod"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_app_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  target_group_arn  = module.alb.target_group_arn

  instance_type    = "t3.medium"
  root_volume_size = 30
  root_volume_type = "gp3"

  asg_min_size         = 2
  asg_max_size         = 10
  asg_desired_capacity = 2

  # Scale at 70% CPU
  enable_cpu_autoscaling = true
  cpu_target_value       = 70

  # Longer grace period for larger apps
  health_check_grace_period = 600

  user_data_vars = {
    app_port    = 8080
    environment = "prod"
  }

  tags = {
    Environment = "prod"
  }
}
```

### Custom AMI

```hcl
module "ec2" {
  source = "../../modules/ec2"

  name              = "my-app"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_app_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  target_group_arn  = module.alb.target_group_arn

  # Use custom AMI with pre-installed application
  ami_id = "ami-0123456789abcdef0"

  # Disable default user data
  custom_user_data = base64encode("#!/bin/bash\necho 'Custom startup'")

  tags = {
    Environment = "staging"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for resources | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | Private subnet IDs | `list(string)` | n/a | yes |
| security_group_id | Security group ID | `string` | n/a | yes |
| target_group_arn | ALB target group ARN | `string` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| ami_id | AMI ID (defaults to latest AL2023) | `string` | `null` | no |
| key_name | SSH key pair name | `string` | `null` | no |
| root_volume_size | Root volume size (GB) | `number` | `20` | no |
| root_volume_type | Root volume type | `string` | `"gp3"` | no |
| asg_min_size | ASG minimum instances | `number` | `1` | no |
| asg_max_size | ASG maximum instances | `number` | `4` | no |
| asg_desired_capacity | ASG desired instances | `number` | `2` | no |
| enable_cpu_autoscaling | Enable CPU-based scaling | `bool` | `true` | no |
| cpu_target_value | CPU target percentage | `number` | `70` | no |
| user_data_vars | Variables for user data template | `object` | `{}` | no |
| tags | Common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | ID of the launch template |
| asg_id | ID of the Auto Scaling Group |
| asg_name | Name of the Auto Scaling Group |
| iam_role_arn | ARN of the IAM role |
| ami_id | AMI ID used for instances |

## SSM Session Manager Access

Instead of SSH, use SSM Session Manager:

```bash
# Connect to instance
aws ssm start-session --target i-0123456789abcdef0

# Or through AWS Console:
# EC2 > Instances > Select instance > Connect > Session Manager
```

## Security Features

- **IMDSv2 Required**: Protects against SSRF attacks
- **Encrypted Volumes**: EBS volumes encrypted by default
- **No SSH Keys**: Uses SSM Session Manager
- **Private Subnets**: Instances not directly accessible from internet
- **IAM Role**: Least privilege access for SSM and CloudWatch

## Cost Optimization

| Environment | Instance Type | Min/Max | Estimated Monthly |
|-------------|--------------|---------|-------------------|
| Dev | t3.micro | 1/2 | ~$8 |
| Staging | t3.small | 2/4 | ~$30 |
| Prod | t3.medium | 2/10 | ~$60-300 |
