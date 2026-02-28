# CLAUDE.md

## Project Overview

AWS Lab Infrastructure — a Terraform-based IaC project that builds a production-grade, three-tier AWS environment. Phases 0–2 (networking, encryption, IAM, secrets) are complete. Phases 3–7 (compute, data, observability, CI/CD, security hardening) have placeholder modules.

## Repository Structure

```
aws-lab-infra/
├── environments/
│   └── dev/                    # Development environment (entry point)
│       ├── backend.tf          # S3 + DynamoDB remote state config
│       ├── main.tf             # Module orchestration and provider setup
│       ├── variables.tf        # Environment-level variables
│       ├── outputs.tf          # Aggregated module outputs
│       └── .terraform.lock.hcl # Provider lock (AWS 5.100.0)
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                    # Three-tier VPC (public/app/data subnets, NAT, flow logs)
│   ├── kms/                    # Customer-managed encryption key + key policy
│   ├── secrets/                # Secrets Manager for DB credentials
│   ├── iam/                    # IAM roles (ECS execution, ECS task, GitHub OIDC)
│   ├── security-groups/        # Identity-based SG rules (ALB→App→RDS/Redis)
│   ├── alb/                    # [placeholder] Application Load Balancer
│   ├── ecs/                    # [placeholder] ECS Fargate
│   ├── rds/                    # [placeholder] PostgreSQL RDS
│   ├── elasticache/            # [placeholder] Redis ElastiCache
│   ├── cicd/                   # [placeholder] CI/CD pipelines
│   ├── monitoring/             # [placeholder] CloudWatch dashboards/alarms
│   └── security/               # [placeholder] WAF, Shield, GuardDuty
├── scripts/
│   └── bootstrap/
│       └── bootstrap-backend.sh  # One-time S3 + DynamoDB backend setup
├── docs/
│   └── decisions/              # Architecture Decision Records (placeholder)
└── .github/
    └── workflows/              # GitHub Actions workflows (placeholder)
```

## Quick Reference

| Item | Value |
|------|-------|
| Terraform version | >= 1.0 |
| AWS provider | ~> 5.0 (locked at 5.100.0) |
| AWS region | us-east-1 |
| AWS profile | aws-lab |
| State bucket | aws-lab-tfstate-{account-id} |
| Lock table | aws-lab-tfstate-lock |
| GitHub org/repo | cpitzi/aws-lab-infra |

## Common Commands

```bash
# One-time backend bootstrap (creates S3 bucket + DynamoDB table)
./scripts/bootstrap/bootstrap-backend.sh

# Initialize Terraform
cd environments/dev && terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# View outputs
terraform output
```

## Module Dependency Graph

```
VPC ──┐
      ├──→ Security Groups
KMS ──┤
      ├──→ Secrets ──→ IAM
      └──→ IAM (receives key ARN; returns role ARNs back to KMS)
```

The KMS ↔ IAM relationship is bidirectional: IAM needs the KMS key ARN for decrypt permissions, and the KMS key policy needs IAM role ARNs to grant encrypt/decrypt access.

## Architecture Conventions

### Naming
All resources: `{project}-{environment}-{resource-type}` (e.g., `aws-lab-dev-ecs-task-execution`).

### Tagging
Applied via provider `default_tags` in `environments/dev/main.tf`:
- `Environment`: dev
- `Project`: aws-lab
- `ManagedBy`: terraform

Individual resources add a `Name` tag.

### Module Structure
Each module contains exactly three files:
- `main.tf` — resource definitions
- `variables.tf` — input variables with descriptions and defaults
- `outputs.tf` — exported values for cross-module wiring

### Multi-AZ
Two availability zones (us-east-1a, us-east-1b) with dedicated NAT Gateway per AZ to avoid cross-AZ bottlenecks and egress costs.

### Three-Tier Networking
- **Public subnets** (10.0.1.0/24, 10.0.2.0/24): ALB and NAT Gateways only
- **App subnets** (10.0.10.0/24, 10.0.11.0/24): ECS Fargate tasks (private)
- **Data subnets** (10.0.20.0/24, 10.0.21.0/24): RDS and ElastiCache (private)

### Security Group Pattern
Rules reference security group IDs (not CIDRs) so they remain valid when ECS Fargate tasks get new IPs on each deployment. Groups are created as empty shells first, then rules are added as separate `aws_security_group_rule` resources to avoid circular references.

### IAM Least Privilege
Three distinct roles with minimal permissions:
- **ECS Task Execution Role**: ECR pull, CloudWatch logs, Secrets Manager read, KMS decrypt
- **ECS Task Role**: Only Secrets Manager read + KMS decrypt (expandable for future app needs)
- **GitHub Actions OIDC Role**: Scoped to specific repo, no long-lived credentials

### KMS Key Policy
Four-statement structure: root account escape hatch, key admin (no crypto), CloudWatch Logs service principal, conditional service role grants.

### Secrets Manager
- Secret container and secret version are separate resources
- `ignore_changes` on `secret_string` prevents Terraform from overwriting manual/automated rotations
- 7-day recovery window (dev environment)
- Placeholder values — will be seeded when RDS is created in Phase 4

## Development Guidelines

### Adding a New Module
1. Create `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`
2. Include `environment` and `project` variables for consistent naming/tagging
3. Wire it into `environments/dev/main.tf` following the dependency order
4. Export relevant outputs in `environments/dev/outputs.tf`

### Adding a New Environment
1. Create `environments/<env>/` with the same file structure as `environments/dev/`
2. Update `backend.tf` to use a different state key (e.g., `env/staging/terraform.tfstate`)
3. Set appropriate variable defaults in `variables.tf`

### Sensitive Data
- Never commit `.tfvars`, `.tfstate`, or credential files (enforced by `.gitignore`)
- Use Secrets Manager for application secrets, not Terraform variables
- KMS-encrypt all sensitive resources

### CI/CD Authentication
GitHub Actions authenticates to AWS via OIDC (no access keys stored as secrets). The trust policy in `modules/iam/main.tf` scopes access to `repo:cpitzi/aws-lab-infra:*`.

## Project Phases

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Bootstrap backend, project structure | Complete |
| 1 | VPC, KMS, Secrets Manager | Complete |
| 2 | IAM roles, Security Groups | Complete |
| 3 | ALB, ECS Fargate, ECR | Planned |
| 4 | RDS PostgreSQL, ElastiCache Redis | Planned |
| 5 | CloudWatch monitoring, alarms | Planned |
| 6 | GitHub Actions CI/CD workflows | Planned |
| 7 | WAF, Shield, GuardDuty | Planned |

## Key Files for Context

When working on this repo, these files provide the most context:
- `environments/dev/main.tf` — how all modules connect
- `environments/dev/outputs.tf` — what each module exposes
- `modules/*/variables.tf` — what each module accepts
- `scripts/bootstrap/bootstrap-backend.sh` — backend initialization
