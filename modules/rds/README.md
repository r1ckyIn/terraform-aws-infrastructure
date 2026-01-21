# RDS Module

Creates an RDS database instance with subnet group and parameter group.

## Features

- MySQL, PostgreSQL, or MariaDB support
- Multi-AZ deployment for high availability
- Storage autoscaling
- Automated backups and maintenance windows
- Encryption at rest
- Performance Insights support
- CloudWatch Logs export

## Architecture

```
         Private DB Subnets
    ┌────────────────────────────────┐
    │                                │
    │  ┌──────────┐   ┌──────────┐  │
    │  │  AZ-a    │   │  AZ-b    │  │
    │  │          │   │          │  │
    │  │ ┌──────┐ │   │ ┌──────┐ │  │
    │  │ │ RDS  │ │   │ │Standby│ │  │
    │  │ │Primary│◄───►│ (Multi-│ │  │
    │  │ │      │ │   │ │  AZ)  │ │  │
    │  │ └──────┘ │   │ └──────┘ │  │
    │  └──────────┘   └──────────┘  │
    │                                │
    │  DB Subnet Group               │
    └────────────────────────────────┘
              │
    ┌─────────▼──────────┐
    │  App Security      │
    │  Group (ingress)   │
    └────────────────────┘
```

## Usage

### Development (MySQL)

```hcl
module "rds" {
  source = "../../modules/rds"

  name              = "my-app-dev"
  subnet_ids        = module.vpc.private_db_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  db_name           = "myapp"
  username          = "admin"
  password          = var.db_password

  # Dev settings
  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Environment = "dev"
  }
}
```

### Production (MySQL)

```hcl
module "rds" {
  source = "../../modules/rds"

  name              = "my-app-prod"
  subnet_ids        = module.vpc.private_db_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"

  db_name  = "myapp"
  username = "admin"
  password = var.db_password

  # Production settings
  multi_az              = true
  deletion_protection   = true
  skip_final_snapshot   = false
  backup_retention_period = 30

  # Monitoring
  performance_insights_enabled          = true
  performance_insights_retention_period = 731
  enabled_cloudwatch_logs_exports       = ["error", "slowquery"]

  # Custom parameters
  parameters = [
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    }
  ]

  tags = {
    Environment = "prod"
  }
}
```

### PostgreSQL

```hcl
module "rds" {
  source = "../../modules/rds"

  name              = "my-app-postgres"
  subnet_ids        = module.vpc.private_db_subnet_ids
  security_group_id = module.security_groups.rds_security_group_id

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  port           = 5432

  db_name  = "myapp"
  username = "postgres"
  password = var.db_password

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix (DB identifier) | `string` | n/a | yes |
| subnet_ids | Private DB subnet IDs | `list(string)` | n/a | yes |
| security_group_id | Security group ID | `string` | n/a | yes |
| engine | Database engine | `string` | `"mysql"` | no |
| engine_version | Engine version | `string` | `"8.0"` | no |
| instance_class | Instance class | `string` | `"db.t3.micro"` | no |
| allocated_storage | Storage in GB | `number` | `20` | no |
| max_allocated_storage | Max storage for autoscaling | `number` | `100` | no |
| db_name | Initial database name | `string` | `"appdb"` | no |
| username | Master username | `string` | `"admin"` | yes |
| password | Master password | `string` | n/a | yes |
| port | Database port | `number` | `3306` | no |
| multi_az | Enable Multi-AZ | `bool` | `false` | no |
| backup_retention_period | Backup retention days | `number` | `7` | no |
| deletion_protection | Enable deletion protection | `bool` | `false` | no |
| skip_final_snapshot | Skip final snapshot | `bool` | `true` | no |
| tags | Common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The ID of the RDS instance |
| db_endpoint | Connection endpoint (address:port) |
| db_address | Database hostname |
| db_port | Database port |
| db_name | Database name |
| db_username | Master username |
| connection_string_mysql | MySQL connection string template |
| connection_string_postgres | PostgreSQL connection string template |

## Instance Classes

| Environment | Recommended | vCPU | Memory |
|-------------|-------------|------|--------|
| Dev | db.t3.micro | 2 | 1 GB |
| Staging | db.t3.small | 2 | 2 GB |
| Prod (small) | db.t3.medium | 2 | 4 GB |
| Prod (medium) | db.r5.large | 2 | 16 GB |
| Prod (large) | db.r5.xlarge | 4 | 32 GB |

## Cost Considerations

- **Multi-AZ** doubles the cost (standby instance)
- **Storage** is charged per GB-month
- **Backup storage** free up to total storage size
- **Performance Insights** additional cost for 731-day retention

## Security Best Practices

1. **Never expose to internet** - `publicly_accessible = false`
2. **Use Security Group** - Only allow app tier access
3. **Enable encryption** - `storage_encrypted = true`
4. **Enable deletion protection** in production
5. **Use strong passwords** - Consider AWS Secrets Manager
6. **Regular backups** - Set appropriate retention period
