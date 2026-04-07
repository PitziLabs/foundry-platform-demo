variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (app/name/id format)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "elasticache_replication_group_id" {
  description = "ElastiCache replication group ID"
  type        = string
}

variable "waf_web_acl_name" {
  description = "Name of the WAFv2 Web ACL"
  type        = string
}

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  type        = list(string)
}
