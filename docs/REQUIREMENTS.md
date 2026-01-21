# Project Requirements

[English](#english) | [中文](#中文)

---

## English

### Overview

This document outlines the requirements for the Terraform AWS Multi-Tier Infrastructure project.

### Project Goals

1. **Infrastructure as Code**: Create reproducible, version-controlled AWS infrastructure
2. **Modularity**: Reusable Terraform modules for common AWS resources
3. **Multi-Environment**: Support for dev, staging, and production environments
4. **Security**: Implement AWS security best practices
5. **Cost Optimization**: Environment-specific configurations for cost efficiency
6. **CI/CD Ready**: Automated deployment pipelines

### Functional Requirements

#### Networking (VPC Module)

- [x] VPC with configurable CIDR block
- [x] Multi-AZ deployment (2-3 availability zones)
- [x] Three-tier subnet architecture:
  - Public subnets (ALB, NAT Gateway)
  - Private application subnets (EC2)
  - Private database subnets (RDS)
- [x] Internet Gateway for public access
- [x] NAT Gateway (single or per-AZ option)
- [x] Route tables for each tier

#### Security (Security Groups Module)

- [x] ALB security group (HTTP/HTTPS from internet)
- [x] Application security group (from ALB only)
- [x] Database security group (from App only)
- [x] Security group chaining using SG IDs (not CIDRs)

#### Load Balancing (ALB Module)

- [x] Application Load Balancer
- [x] Target Group with health checks
- [x] HTTP listener (forward or redirect to HTTPS)
- [x] Optional HTTPS listener with ACM certificate

#### Compute (EC2 Module)

- [x] Launch Template with IMDSv2
- [x] Auto Scaling Group
- [x] Target tracking scaling policy (CPU-based)
- [x] IAM role with SSM and CloudWatch permissions
- [x] User data template for initialization

#### Database (RDS Module)

- [x] RDS instance (MySQL, PostgreSQL, MariaDB)
- [x] DB Subnet Group
- [x] DB Parameter Group
- [x] Multi-AZ option
- [x] Encryption at rest
- [x] Automated backups

### Non-Functional Requirements

#### Security

- [x] No hardcoded secrets in code
- [x] Encrypted EBS volumes
- [x] Encrypted RDS storage
- [x] Private subnets for application and database
- [x] Security group least privilege
- [x] IMDSv2 enforced on EC2

#### Reliability

- [x] Multi-AZ deployment support
- [x] Auto Scaling for fault tolerance
- [x] Health checks for load balancing
- [x] Terraform state locking (DynamoDB)

#### Cost Optimization

- [x] Single NAT Gateway option for dev
- [x] Smaller instance types for non-prod
- [x] RDS Multi-AZ only in prod

#### Maintainability

- [x] Modular design
- [x] Consistent tagging
- [x] Version constraints for Terraform/providers
- [x] CI/CD pipeline for automation

### Environment Configuration

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| NAT Gateway | Single | Single | Per-AZ |
| Instance Type | t3.micro | t3.small | t3.medium |
| ASG Min/Max | 1/2 | 2/4 | 2/10 |
| RDS Instance | db.t3.micro | db.t3.small | db.r5.large |
| Multi-AZ RDS | No | No | Yes |
| Deletion Protection | No | Yes | Yes |

### Dependencies

- Terraform >= 1.5.0
- AWS Provider >= 5.0.0
- AWS CLI (for backend setup)

---

## 中文

### 概述

本文档概述了 Terraform AWS 多层基础设施项目的需求。

### 项目目标

1. **基础设施即代码**：创建可重复、版本控制的 AWS 基础设施
2. **模块化**：可复用的 Terraform 模块
3. **多环境支持**：支持 dev、staging 和 production 环境
4. **安全性**：实施 AWS 安全最佳实践
5. **成本优化**：针对环境的成本优化配置
6. **CI/CD 就绪**：自动化部署流水线

### 功能需求

#### 网络（VPC 模块）

- [x] 可配置 CIDR 的 VPC
- [x] 多可用区部署（2-3 个可用区）
- [x] 三层子网架构：
  - 公有子网（ALB、NAT 网关）
  - 私有应用子网（EC2）
  - 私有数据库子网（RDS）
- [x] 用于公网访问的互联网网关
- [x] NAT 网关（单个或每 AZ 一个选项）
- [x] 各层的路由表

#### 安全（安全组模块）

- [x] ALB 安全组（来自互联网的 HTTP/HTTPS）
- [x] 应用安全组（仅来自 ALB）
- [x] 数据库安全组（仅来自应用）
- [x] 使用安全组 ID（而非 CIDR）的安全组链

#### 负载均衡（ALB 模块）

- [x] 应用负载均衡器
- [x] 带健康检查的目标组
- [x] HTTP 监听器（转发或重定向到 HTTPS）
- [x] 可选的 HTTPS 监听器（使用 ACM 证书）

#### 计算（EC2 模块）

- [x] 使用 IMDSv2 的启动模板
- [x] 自动伸缩组
- [x] 目标跟踪伸缩策略（基于 CPU）
- [x] 具有 SSM 和 CloudWatch 权限的 IAM 角色
- [x] 用于初始化的用户数据模板

#### 数据库（RDS 模块）

- [x] RDS 实例（MySQL、PostgreSQL、MariaDB）
- [x] 数据库子网组
- [x] 数据库参数组
- [x] 多 AZ 选项
- [x] 静态加密
- [x] 自动备份

### 非功能需求

#### 安全性

- [x] 代码中无硬编码密钥
- [x] 加密的 EBS 卷
- [x] 加密的 RDS 存储
- [x] 应用和数据库使用私有子网
- [x] 安全组最小权限
- [x] EC2 强制使用 IMDSv2

#### 可靠性

- [x] 多 AZ 部署支持
- [x] 用于容错的自动伸缩
- [x] 负载均衡健康检查
- [x] Terraform 状态锁定（DynamoDB）

#### 成本优化

- [x] dev 环境使用单个 NAT 网关选项
- [x] 非生产环境使用较小实例类型
- [x] 仅生产环境使用 RDS 多 AZ

#### 可维护性

- [x] 模块化设计
- [x] 一致的标签
- [x] Terraform/provider 版本约束
- [x] 自动化 CI/CD 流水线

### 环境配置

| 配置 | Dev | Staging | Prod |
|-----|-----|---------|------|
| NAT 网关 | 单个 | 单个 | 每 AZ |
| 实例类型 | t3.micro | t3.small | t3.medium |
| ASG 最小/最大 | 1/2 | 2/4 | 2/10 |
| RDS 实例 | db.t3.micro | db.t3.small | db.r5.large |
| RDS 多 AZ | 否 | 否 | 是 |
| 删除保护 | 否 | 是 | 是 |

### 依赖

- Terraform >= 1.5.0
- AWS Provider >= 5.0.0
- AWS CLI（用于后端设置）
