# Security Groups Module

Creates a chain of security groups implementing the principle of least privilege for a three-tier architecture.

## Architecture

```
                      Internet
                         │
                         ▼
              ┌──────────────────┐
              │    ALB SG        │
              │  Port 80/443     │
              │  from 0.0.0.0/0  │
              └────────┬─────────┘
                       │ SG Reference
                       ▼
              ┌──────────────────┐
              │    App SG        │
              │  Port 8080       │
              │  from ALB SG     │
              └────────┬─────────┘
                       │ SG Reference
                       ▼
              ┌──────────────────┐
              │    RDS SG        │
              │  Port 3306       │
              │  from App SG     │
              └──────────────────┘
```

## Key Design Decisions

### Security Group ID as Source (Not CIDR)

This module uses **Security Group IDs** instead of CIDR blocks for inter-tier communication:

```hcl
# GOOD: Using Security Group ID
source_security_group_id = aws_security_group.app.id

# BAD: Using CIDR (too broad, less secure)
cidr_blocks = ["10.0.0.0/8"]
```

**Why?**
- Only resources that are members of the specified security group can access
- IP address changes don't require rule updates
- Auto-scaling instances are automatically authorized
- More secure than CIDR-based rules

### Traffic Flow

| Source | Destination | Ports | Protocol |
|--------|-------------|-------|----------|
| Internet | ALB | 80, 443 | TCP |
| ALB SG | App SG | app_port | TCP |
| App SG | RDS SG | db_port | TCP |
| App SG | Internet | 80, 443 | TCP (outbound via NAT) |

## Usage

### Basic Usage

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name   = "my-project-dev"
  vpc_id = module.vpc.vpc_id

  app_port = 8080
  db_port  = 3306

  tags = {
    Environment = "dev"
  }
}
```

### Restricted Access

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name   = "my-project-internal"
  vpc_id = module.vpc.vpc_id

  # Only allow access from corporate network
  allowed_http_cidrs  = ["10.0.0.0/8"]
  allowed_https_cidrs = ["10.0.0.0/8"]

  app_port = 3000
  db_port  = 5432  # PostgreSQL

  tags = {
    Environment = "internal"
  }
}
```

### PostgreSQL Configuration

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name   = "my-project-prod"
  vpc_id = module.vpc.vpc_id

  app_port = 8080
  db_port  = 5432  # PostgreSQL

  tags = {
    Environment = "prod"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for security groups | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| app_port | Application listening port | `number` | `8080` | no |
| db_port | Database port | `number` | `3306` | no |
| allowed_http_cidrs | CIDRs allowed for HTTP | `list(string)` | `["0.0.0.0/0"]` | no |
| allowed_https_cidrs | CIDRs allowed for HTTPS | `list(string)` | `["0.0.0.0/0"]` | no |
| tags | Common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | Security group ID for ALB |
| app_security_group_id | Security group ID for application instances |
| rds_security_group_id | Security group ID for RDS |
| all_security_group_ids | Map of all security group IDs |

## Common Database Ports

| Database | Port |
|----------|------|
| MySQL | 3306 |
| PostgreSQL | 5432 |
| SQL Server | 1433 |
| Oracle | 1521 |
| MongoDB | 27017 |
| Redis | 6379 |

## Security Best Practices

1. **Never use 0.0.0.0/0 for database access** - Always use security group references
2. **Restrict ALB access if internal** - Use corporate CIDR for internal applications
3. **Review egress rules** - Application instances have limited outbound access
4. **Use separate security groups** - Don't share security groups across tiers
