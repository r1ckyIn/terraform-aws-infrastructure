# VPC Module

Creates a production-grade VPC with public and private subnets across multiple availability zones.

## Features

- Multi-AZ deployment for high availability
- Three-tier subnet architecture (public, private-app, private-db)
- Configurable NAT Gateway (single for cost savings or per-AZ for HA)
- Auto-calculated subnet CIDRs or custom specification
- Complete isolation for database tier (no internet access)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                   │
│  CIDR: 10.0.0.0/16                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Public     │  │  Public     │  │  Public     │              │
│  │  Subnet     │  │  Subnet     │  │  Subnet     │              │
│  │  AZ-a       │  │  AZ-b       │  │  AZ-c       │              │
│  │  10.0.0.0/20│  │  10.0.16.0/20│ │  10.0.32.0/20│             │
│  │  [NAT GW]   │  │  [NAT GW]*  │  │  [NAT GW]*  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│        │                │                │                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Private    │  │  Private    │  │  Private    │              │
│  │  App Subnet │  │  App Subnet │  │  App Subnet │              │
│  │  AZ-a       │  │  AZ-b       │  │  AZ-c       │              │
│  │  10.0.48.0/20│ │ 10.0.64.0/20│  │ 10.0.80.0/20│              │
│  │  [EC2/ECS]  │  │  [EC2/ECS]  │  │  [EC2/ECS]  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│        │                │                │                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Private    │  │  Private    │  │  Private    │              │
│  │  DB Subnet  │  │  DB Subnet  │  │  DB Subnet  │              │
│  │  AZ-a       │  │  AZ-b       │  │  AZ-c       │              │
│  │  10.0.96.0/20│ │10.0.112.0/20│  │10.0.128.0/20│              │
│  │  [RDS]      │  │  [RDS]      │  │  [RDS]      │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                  │
│  * NAT Gateway per AZ only when single_nat_gateway = false      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage (Development)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "my-project-dev"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]

  # Cost saving: single NAT Gateway
  single_nat_gateway = true

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Production Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "my-project-prod"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  # High availability: NAT Gateway per AZ
  single_nat_gateway = false

  tags = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

### Custom Subnet CIDRs

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "my-project"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]

  # Custom subnet CIDRs
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]

  tags = {
    Environment = "staging"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all VPC resources | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| single_nat_gateway | Use single NAT Gateway for cost savings | `bool` | `true` | no |
| enable_dns_hostnames | Enable DNS hostnames in VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in VPC | `bool` | `true` | no |
| public_subnet_cidrs | Custom CIDRs for public subnets | `list(string)` | `[]` | no |
| private_app_subnet_cidrs | Custom CIDRs for private app subnets | `list(string)` | `[]` | no |
| private_db_subnet_cidrs | Custom CIDRs for private DB subnets | `list(string)` | `[]` | no |
| tags | Common tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_app_subnet_ids | List of private application subnet IDs |
| private_db_subnet_ids | List of private database subnet IDs |
| internet_gateway_id | The ID of the Internet Gateway |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of NAT Gateway public IPs |
| availability_zones | List of availability zones used |

## Cost Considerations

- **NAT Gateway**: ~$32/month per gateway + $0.045/GB data processed
- **Elastic IP**: Free when attached to running NAT Gateway
- **Recommendation**: Use `single_nat_gateway = true` for dev/staging to save costs

## Security Notes

- Database subnets have **no internet access** (not even outbound)
- Application subnets can reach internet via NAT Gateway (outbound only)
- Public subnets can have public IPs with direct internet access
- Use Security Groups to control traffic between tiers
