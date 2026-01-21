# Architecture Documentation

[English](#english) | [中文](#中文)

---

## English

### High-Level Architecture

```
                           Internet
                              │
                              ▼
                    ┌─────────────────┐
                    │ Internet Gateway │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
      ┌───────────────┐            ┌───────────────┐
      │ Public Subnet │            │ Public Subnet │
      │    (AZ-a)     │            │    (AZ-b)     │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │   ALB   │  │            │  │   ALB   │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      │       │       │            │       │       │
      │  ┌────┴────┐  │            │  ┌────┴────┐  │
      │  │NAT GW   │  │            │  │NAT GW*  │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      └───────┼───────┘            └───────┼───────┘
              │                            │
      ┌───────┴───────┐            ┌───────┴───────┐
      │ Private App   │            │ Private App   │
      │ Subnet (AZ-a) │            │ Subnet (AZ-b) │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │   EC2   │──┼────────────┼──│   EC2   │  │
      │  │  (ASG)  │  │            │  │  (ASG)  │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      └───────┼───────┘            └───────┼───────┘
              │                            │
      ┌───────┴───────┐            ┌───────┴───────┐
      │ Private DB    │            │ Private DB    │
      │ Subnet (AZ-a) │            │ Subnet (AZ-b) │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │   RDS   │◄─┼─Multi-AZ──►┼─│  Standby │  │
      │  │ Primary │  │            │  │   RDS    │  │
      │  └─────────┘  │            │  └─────────┘  │
      └───────────────┘            └───────────────┘

* NAT GW per AZ only in production (single_nat_gateway = false)
```

### Module Dependency Graph

```
                    ┌─────────────────────────────┐
                    │         Environment          │
                    │     (main.tf composition)    │
                    └──────────────┬──────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐
    │     VPC     │         │     ALB     │         │     RDS     │
    │   Module    │◄────────│   Module    │         │   Module    │
    └─────┬───────┘         └──────┬──────┘         └──────┬──────┘
          │                        │                       │
          │                        │                       │
          │    ┌───────────────────┴───────────────────┐   │
          │    │                                       │   │
          ▼    ▼                                       ▼   ▼
    ┌─────────────────┐                        ┌───────────────┐
    │ Security Groups │◄───────────────────────│     EC2       │
    │     Module      │                        │    Module     │
    └─────────────────┘                        └───────────────┘

Dependency Flow:
1. VPC creates networking foundation
2. Security Groups depend on VPC ID
3. ALB depends on VPC subnets and Security Groups
4. EC2 depends on VPC subnets, Security Groups, and ALB target group
5. RDS depends on VPC subnets and Security Groups
```

### Security Group Chain

```
    ┌────────────────────────────────────────────────────────────┐
    │                     Security Group Chain                    │
    │                                                             │
    │   Internet                                                  │
    │      │                                                      │
    │      │ HTTP/HTTPS (80, 443)                                 │
    │      ▼                                                      │
    │   ┌──────────────┐                                          │
    │   │   ALB SG     │ ◄── Source: 0.0.0.0/0 (or restricted)   │
    │   └──────┬───────┘                                          │
    │          │                                                  │
    │          │ App Port (8080)                                  │
    │          ▼                                                  │
    │   ┌──────────────┐                                          │
    │   │   App SG     │ ◄── Source: ALB Security Group ID       │
    │   └──────┬───────┘                                          │
    │          │                                                  │
    │          │ DB Port (3306/5432)                              │
    │          ▼                                                  │
    │   ┌──────────────┐                                          │
    │   │   RDS SG     │ ◄── Source: App Security Group ID       │
    │   └──────────────┘                                          │
    │                                                             │
    │   Key: Using SG IDs (not CIDRs) ensures only authorized    │
    │        resources can communicate between tiers              │
    └────────────────────────────────────────────────────────────┘
```

### State Management

```
    ┌─────────────────────────────────────────────────────────────┐
    │                    Terraform State                           │
    │                                                              │
    │   S3 Bucket (terraform-state-bucket)                        │
    │   ├── terraform-aws-infrastructure/                          │
    │   │   ├── dev/terraform.tfstate                             │
    │   │   ├── staging/terraform.tfstate                         │
    │   │   └── prod/terraform.tfstate                            │
    │                                                              │
    │   DynamoDB Table (terraform-state-lock)                     │
    │   └── LockID: terraform-aws-infrastructure/env/terraform... │
    │                                                              │
    │   Benefits:                                                  │
    │   • State versioning (S3)                                   │
    │   • State encryption (S3)                                   │
    │   • State locking (DynamoDB)                                │
    │   • Environment isolation                                   │
    └─────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Flow

```
    ┌─────────────────────────────────────────────────────────────┐
    │                    CI/CD Pipeline                            │
    │                                                              │
    │   Pull Request:                                              │
    │   ┌──────────┐    ┌──────────┐    ┌──────────┐              │
    │   │  Format  │───►│ Validate │───►│   Plan   │              │
    │   │  Check   │    │ Modules  │    │ (PR Comment)│           │
    │   └──────────┘    └──────────┘    └──────────┘              │
    │                                                              │
    │   Merge to Main:                                             │
    │   ┌──────────┐    ┌──────────┐    ┌──────────┐              │
    │   │  Apply   │───►│  Apply   │───►│  Apply   │              │
    │   │   Dev    │    │ Staging  │    │   Prod   │              │
    │   │ (auto)   │    │(approval)│    │(approval)│              │
    │   └──────────┘    └──────────┘    └──────────┘              │
    │                                                              │
    │   Environment Protection:                                    │
    │   • dev: Auto-deploy on merge                               │
    │   • staging: Required reviewers                             │
    │   • prod: Required reviewers + wait timer                   │
    └─────────────────────────────────────────────────────────────┘
```

### Network CIDR Allocation

```
    VPC CIDR: 10.x.0.0/16

    Dev:     10.0.0.0/16
    Staging: 10.1.0.0/16
    Prod:    10.2.0.0/16

    Subnet Allocation (using /20 subnets):
    ┌────────────────────────────────────────────────────────────┐
    │ Tier          │ AZ-a          │ AZ-b          │ AZ-c       │
    ├────────────────────────────────────────────────────────────┤
    │ Public        │ 10.x.0.0/20   │ 10.x.16.0/20  │ 10.x.32.0/20│
    │ Private App   │ 10.x.48.0/20  │ 10.x.64.0/20  │ 10.x.80.0/20│
    │ Private DB    │ 10.x.96.0/20  │ 10.x.112.0/20 │ 10.x.128.0/20│
    └────────────────────────────────────────────────────────────┘

    Each /20 subnet provides 4,096 IP addresses
```

### Cost Optimization Strategies

| Resource | Dev | Staging | Prod | Rationale |
|----------|-----|---------|------|-----------|
| NAT Gateway | 1 | 1 | Per-AZ | $32/month savings in non-prod |
| EC2 Type | t3.micro | t3.small | t3.medium | Right-sized for workload |
| RDS Type | db.t3.micro | db.t3.small | db.r5.large | Right-sized for workload |
| RDS Multi-AZ | No | No | Yes | HA only needed in prod |
| ASG Min | 1 | 2 | 2 | Reduced capacity in dev |

---

## 中文

### 高层架构

```
                           互联网
                              │
                              ▼
                    ┌─────────────────┐
                    │   互联网网关     │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
      ┌───────────────┐            ┌───────────────┐
      │ 公有子网       │            │ 公有子网       │
      │    (AZ-a)     │            │    (AZ-b)     │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │  ALB    │  │            │  │   ALB   │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      │       │       │            │       │       │
      │  ┌────┴────┐  │            │  ┌────┴────┐  │
      │  │NAT 网关  │  │            │  │NAT 网关* │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      └───────┼───────┘            └───────┼───────┘
              │                            │
      ┌───────┴───────┐            ┌───────┴───────┐
      │ 私有应用子网   │            │ 私有应用子网   │
      │    (AZ-a)     │            │    (AZ-b)     │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │  EC2    │──┼────────────┼──│   EC2   │  │
      │  │ (ASG)   │  │            │  │  (ASG)  │  │
      │  └────┬────┘  │            │  └────┬────┘  │
      └───────┼───────┘            └───────┼───────┘
              │                            │
      ┌───────┴───────┐            ┌───────┴───────┐
      │ 私有数据库子网 │            │ 私有数据库子网 │
      │    (AZ-a)     │            │    (AZ-b)     │
      │  ┌─────────┐  │            │  ┌─────────┐  │
      │  │  RDS    │◄─┼─ 多 AZ ───►┼─│  备用    │  │
      │  │  主实例  │  │            │  │  RDS    │  │
      │  └─────────┘  │            │  └─────────┘  │
      └───────────────┘            └───────────────┘

* 每 AZ 一个 NAT 网关仅在生产环境 (single_nat_gateway = false)
```

### 安全组链

```
    ┌────────────────────────────────────────────────────────────┐
    │                     安全组链                                │
    │                                                             │
    │   互联网                                                    │
    │      │                                                      │
    │      │ HTTP/HTTPS (80, 443)                                 │
    │      ▼                                                      │
    │   ┌──────────────┐                                          │
    │   │  ALB 安全组   │ ◄── 来源: 0.0.0.0/0（或受限）           │
    │   └──────┬───────┘                                          │
    │          │                                                  │
    │          │ 应用端口 (8080)                                   │
    │          ▼                                                  │
    │   ┌──────────────┐                                          │
    │   │  应用安全组   │ ◄── 来源: ALB 安全组 ID                  │
    │   └──────┬───────┘                                          │
    │          │                                                  │
    │          │ 数据库端口 (3306/5432)                           │
    │          ▼                                                  │
    │   ┌──────────────┐                                          │
    │   │  RDS 安全组   │ ◄── 来源: 应用安全组 ID                  │
    │   └──────────────┘                                          │
    │                                                             │
    │   关键：使用安全组 ID（而非 CIDR）确保只有授权的            │
    │         资源可以在各层之间通信                              │
    └────────────────────────────────────────────────────────────┘
```

### 成本优化策略

| 资源 | Dev | Staging | Prod | 原因 |
|------|-----|---------|------|------|
| NAT 网关 | 1 | 1 | 每 AZ | 非生产环境节省 $32/月 |
| EC2 类型 | t3.micro | t3.small | t3.medium | 根据工作负载调整 |
| RDS 类型 | db.t3.micro | db.t3.small | db.r5.large | 根据工作负载调整 |
| RDS 多 AZ | 否 | 否 | 是 | 仅生产环境需要高可用 |
| ASG 最小值 | 1 | 2 | 2 | dev 减少容量 |
