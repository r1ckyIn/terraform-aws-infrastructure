# Terraform AWS Multi-Tier Infrastructure

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-844FBA?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

**Production-grade AWS infrastructure with modular Terraform**

[English](#english) | [中文](#中文)

</div>

---

## English

### Overview

A production-ready, modular Terraform project for deploying multi-tier AWS infrastructure. This project demonstrates Infrastructure as Code (IaC) best practices with a focus on security, scalability, and maintainability.

### Architecture

```
                    Internet
                       │
                       ▼
              ┌────────────────┐
              │  Internet GW   │
              └────────┬───────┘
                       │
         ┌─────────────┴─────────────┐
         │      Public Subnets       │
         │  ┌─────────────────────┐  │
         │  │   Load Balancer     │  │
         │  └─────────────────────┘  │
         └─────────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         │   Private App Subnets     │
         │  ┌─────────────────────┐  │
         │  │  Auto Scaling Group │  │
         │  │    (EC2 Instances)  │  │
         │  └─────────────────────┘  │
         └─────────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         │    Private DB Subnets     │
         │  ┌─────────────────────┐  │
         │  │    RDS Database     │  │
         │  └─────────────────────┘  │
         └───────────────────────────┘
```

### Features

- **Modular Design**: Reusable modules for VPC, Security Groups, ALB, EC2, and RDS
- **Multi-Environment**: Separate configurations for dev, staging, and prod
- **Security First**: Security group chaining, encryption at rest, SSM access
- **Cost Optimization**: Configurable NAT Gateway (single vs per-AZ)
- **CI/CD Ready**: GitHub Actions workflows for plan and apply

### Quick Start

```bash
# Clone the repository
git clone git@github.com:r1ckyIn/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure

# Initialize backend (one-time setup)
./scripts/init-backend.sh

# Deploy to dev environment
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Project Structure

```
terraform-aws-infrastructure/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT gateway
│   ├── security-groups/  # Security group chain
│   ├── alb/              # Application Load Balancer
│   ├── ec2/              # Auto Scaling Group, Launch Template
│   └── rds/              # RDS instance
├── environments/
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
├── scripts/
│   ├── init-backend.sh   # Initialize S3 backend
│   └── validate-all.sh   # Validate all modules
├── docs/
│   ├── REQUIREMENTS.md   # Project requirements
│   └── ARCHITECTURE.md   # Architecture documentation
└── .github/workflows/
    ├── terraform-plan.yml
    └── terraform-apply.yml
```

### Environment Comparison

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| NAT Gateway | Single | Single | Per-AZ |
| Instance Type | t3.micro | t3.small | t3.medium |
| ASG Min/Max | 1/2 | 2/4 | 2/10 |
| RDS Instance | db.t3.micro | db.t3.small | db.r5.large |
| Multi-AZ RDS | No | No | Yes |
| Deletion Protection | No | Yes | Yes |

### Documentation

- [Requirements](docs/REQUIREMENTS.md)
- [Architecture](docs/ARCHITECTURE.md)

---

## 中文

### 项目概述

一个生产级、模块化的 Terraform 项目，用于部署多层 AWS 基础设施。该项目展示了基础设施即代码（IaC）的最佳实践，专注于安全性、可扩展性和可维护性。

### 架构

```
                    互联网
                       │
                       ▼
              ┌────────────────┐
              │  互联网网关     │
              └────────┬───────┘
                       │
         ┌─────────────┴─────────────┐
         │        公有子网           │
         │  ┌─────────────────────┐  │
         │  │    负载均衡器       │  │
         │  └─────────────────────┘  │
         └─────────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         │     私有应用子网          │
         │  ┌─────────────────────┐  │
         │  │   自动伸缩组        │  │
         │  │   (EC2 实例)        │  │
         │  └─────────────────────┘  │
         └─────────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         │     私有数据库子网        │
         │  ┌─────────────────────┐  │
         │  │    RDS 数据库       │  │
         │  └─────────────────────┘  │
         └───────────────────────────┘
```

### 功能特性

- **模块化设计**：可复用的 VPC、安全组、ALB、EC2 和 RDS 模块
- **多环境支持**：dev、staging 和 prod 的独立配置
- **安全优先**：安全组链、静态加密、SSM 访问
- **成本优化**：可配置的 NAT 网关（单个 vs 每 AZ）
- **CI/CD 就绪**：GitHub Actions 工作流

### 快速开始

```bash
# 克隆仓库
git clone git@github.com:r1ckyIn/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure

# 初始化后端（一次性设置）
./scripts/init-backend.sh

# 部署到 dev 环境
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 环境对比

| 配置 | Dev | Staging | Prod |
|-----|-----|---------|------|
| NAT 网关 | 单个 | 单个 | 每 AZ |
| 实例类型 | t3.micro | t3.small | t3.medium |
| ASG 最小/最大 | 1/2 | 2/4 | 2/10 |
| RDS 实例 | db.t3.micro | db.t3.small | db.r5.large |
| RDS 多 AZ | 否 | 否 | 是 |
| 删除保护 | 否 | 是 | 是 |

---

## License

MIT License

## Author

**Ricky** - CS Student @ University of Sydney

[![GitHub](https://img.shields.io/badge/GitHub-r1ckyIn-181717?style=flat-square&logo=github)](https://github.com/r1ckyIn)
