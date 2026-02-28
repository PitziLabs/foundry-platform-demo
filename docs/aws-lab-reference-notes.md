# AWS Infrastructure Lab — Central Reference Notes

> **This is a living document.** Update it as each phase progresses. Upload to your Claude Project knowledge base so every conversation has context.

---

## Account & Identity

| Item | Value | Notes |
|------|-------|-------|
| AWS Account ID | 365184644049 | |
| AWS Region | us-east-1 | |
| Root email | _TBD_ | MFA enabled: ✅ |
| IAM admin username | cpitzi-iac | MFA enabled: ✅ |
| AWS CLI profile name | aws-lab | |
| GitHub repo | aws-lab-infra | https://github.com/cpitzi/aws-lab-infra |
| GitHub username | cpitzi | |
| Domain name | _TBD_ | Cheap domain, Phase 3 |
| Local OS | ChromeOS w/ Linux dev env (Debian-based) | |

---

## Terraform Backend

| Item | Value |
|------|-------|
| State bucket name | aws-lab-tfstate-365184644049 |
| State bucket region | us-east-1 |
| DynamoDB lock table | aws-lab-tfstate-lock |
| State file key | env/dev/terraform.tfstate |

---

## Networking (Phase 1)

| Item | Value |
|------|-------|
| VPC ID | vpc-00c7c8f9950ad6468 |
| VPC CIDR | 10.0.0.0/16 |
| AZ 1 | us-east-1a |
| AZ 2 | us-east-1b |
| Public subnet AZ1 | subnet-0677e44d31c8df6ff (10.0.1.0/24) |
| Public subnet AZ2 | subnet-07f793a7266da9a86 (10.0.2.0/24) |
| App-private subnet AZ1 | subnet-055e06ee5000e35c1 (10.0.10.0/24) |
| App-private subnet AZ2 | subnet-01354c329bfdeec58 (10.0.11.0/24) |
| Data-private subnet AZ1 | subnet-0ede14a937169580e (10.0.20.0/24) |
| Data-private subnet AZ2 | subnet-05c868aa8fdf71042 (10.0.21.0/24) |
| NAT Gateway AZ1 IP | 32.192.220.190 |
| NAT Gateway AZ2 IP | 98.90.48.147 |

---

## Security (Phase 2)

| Item | Value |
|------|-------|
| KMS key alias | alias/aws-lab-dev-main |
| KMS key ID | 366ef9e5-645c-4755-9ad6-4b2ea322af9e |
| KMS key ARN | arn:aws:kms:us-east-1:365184644049:key/366ef9e5-645c-4755-9ad6-4b2ea322af9e |
| ECS task execution role | arn:aws:iam::365184644049:role/aws-lab-dev-ecs-task-execution |
| ECS task role | arn:aws:iam::365184644049:role/aws-lab-dev-ecs-task |
| GitHub Actions OIDC role | arn:aws:iam::365184644049:role/aws-lab-dev-github-actions |
| Secrets Manager secret name | aws-lab-dev/db-credentials |
| Secrets Manager secret ARN | arn:aws:secretsmanager:us-east-1:365184644049:secret:aws-lab-dev/db-credentials-xZ4Eby |
| ALB security group | sg-09d6b29de9879301c |
| App security group | sg-0e31af3dc8ce08f3a |
| RDS security group | sg-08a72bc492fa4fea0 |
| Redis security group | sg-034ba24499da8d804 |

---

## Compute & Containers (Phase 3)

| Item | Value |
|------|-------|
| ECR repo name | _TBD_ |
| ECR repo URI | _TBD_ |
| ECS cluster name | _TBD_ |
| ECS service name | _TBD_ |
| ALB DNS name | _TBD_ |
| ACM certificate ARN | _TBD_ |
| Route 53 hosted zone ID | _TBD_ |

---

## Data Layer (Phase 4)

| Item | Value |
|------|-------|
| RDS instance identifier | _TBD_ |
| RDS endpoint | _TBD_ |
| RDS database name | _TBD_ |
| RDS master username | _TBD_ |
| S3 bucket name | _TBD_ |
| ElastiCache cluster ID | _TBD_ |
| ElastiCache endpoint | _TBD_ |

---

## Observability (Phase 5)

| Item | Value |
|------|-------|
| SNS topic ARN | _TBD_ |
| Notification email | _TBD_ |
| CloudTrail name | _TBD_ |
| CloudTrail S3 prefix | _TBD_ |

---

## CI/CD (Phase 6)

| Item | Value |
|------|-------|
| Deploy workflow file | `.github/workflows/deploy.yml` |
| Terraform workflow file | `.github/workflows/terraform.yml` |
| OIDC provider configured | ☐ |
| Branch protection enabled | ☐ |

---

## Decisions Log

_Quick-reference for architectural decisions made along the way. Full ADRs live in `docs/decisions/` in the repo._

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| 1 | AdministratorAccess on cpitzi-iac | Lab/sandbox account, sole user. Scoped permissions would create constant friction. Will scope down for CI/CD roles. | 2026-02-27 |
| 2 | AES256 encryption on state bucket (not KMS yet) | Avoids KMS dependency before Phase 2. Will upgrade to CMK later. | 2026-02-27 |
| 3 | 2 NAT Gateways (one per AZ) | Production-correct HA pattern. Accepted ~$65/mo cost over single-NAT savings. | 2026-02-27 |
| 4 | count over for_each for VPC subnets | Simpler to learn; fine for lab. Can refactor to for_each later for better state handling. | 2026-02-27 |
| 5 | Single KMS CMK for all encryption | $1/mo per key; lab doesn't need per-service key isolation. Key policy grants scoped to specific roles. | 2026-02-28 |
| 6 | Separate ECS task execution vs task role | Execution role = ECS control plane (image pull, logs, secrets injection). Task role = application runtime AWS access. Least-privilege separation. | 2026-02-28 |
| 7 | GitHub OIDC over IAM access keys | No long-lived credentials. Trust scoped to repo:cpitzi/aws-lab-infra:*. | 2026-02-28 |
| 8 | Security groups as standalone module | Separation of concerns: VPC = network plumbing, SGs = access policy. Cleaner output wiring to consuming modules in Phases 3-4. | 2026-02-28 |
| 9 | Newer per-rule SG resources over legacy inline/aws_security_group_rule | aws_vpc_security_group_ingress_rule is the recommended path forward; older resources in maintenance mode. | 2026-02-28 |
| 10 | Hybrid module structure for Phase 2 (kms/, secrets/, iam/, security-groups/) | KMS + Secrets Manager tightly coupled but separate from IAM roles and security groups. Each module has a clear contract and output surface. | 2026-02-28 |

---

## Cost Tracking

| Date | Monthly Run Rate | Notes |
|------|-----------------|-------|
| 2026-02-27 | ~$65/mo | Phase 1 only: 2 NAT Gateways + 2 EIPs. `terraform destroy` when idle. |
| 2026-02-28 | ~$66/mo | Phase 2 adds: KMS key ($1/mo), Secrets Manager ($0.40/mo). IAM and SGs are free. |

---

## Progress Tracker

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 0 — Foundation & Tooling | Complete | 2026-02-27 | 2026-02-27 |
| 1 — Networking | Complete | 2026-02-27 | 2026-02-27 |
| 2 — Security | Complete | 2026-02-28 | 2026-02-28 |
| 3 — Compute & Containers | Not Started | | |
| 4 — Data Layer | Not Started | | |
| 5 — Observability | Not Started | | |
| 6 — CI/CD | Not Started | | |
| 7 — Hardening | Not Started | | |

---

## Terraform Module Structure (as of Phase 2)

```
modules/
├── vpc/              # Phase 1: VPC, subnets, IGW, NAT, route tables, flow logs
├── kms/              # Phase 2: Customer-managed encryption key
├── secrets/          # Phase 2: Secrets Manager (db credentials pattern)
├── iam/              # Phase 2: ECS roles, GitHub OIDC provider + role
└── security-groups/  # Phase 2: ALB → App → RDS/Redis security group chain
```

---

## Operations Notes

_Operational knowledge for day-to-day work with this environment._

| Topic | Detail |
|-------|--------|
| **Daily teardown** | `terraform destroy` when idle to save ~$2.15/day (NAT Gateways). `terraform apply` recreates everything identically from code. |
| **Secrets Manager recovery window** | Secret has `recovery_window_in_days = 7`. After `terraform destroy`, the secret name is reserved for 7 days. Next `terraform apply` restores the pending-deletion secret — this is normal. If you hit "already scheduled for deletion" errors, either wait out the window or temporarily set recovery window to `0` for immediate deletion. Only an issue because we're using placeholder values; would not do this with real credentials. |
| **KMS key deletion** | KMS key has `deletion_window_in_days = 30`. On destroy, Terraform schedules deletion (doesn't delete immediately). On next apply, it cancels the scheduled deletion and restores the key. No data loss, no new key ID needed. |

---

## Troubleshooting Notes

_Things that bit us and how we fixed them._

| Issue | Resolution | Date |
|-------|-----------|------|
| DynamoDB CreateTable AccessDenied on cpitzi-iac | User only had S3 + EC2 policies. Attached AdministratorAccess via root console. | 2026-02-27 |
