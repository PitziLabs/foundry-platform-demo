# modules/alb/variables.tf

variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB target group performs health checks"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be deployed (must span 2+ AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ALB (controls inbound/outbound traffic)"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM TLS certificate for the HTTPS listener"
  type        = string
}

variable "health_check_path" {
  description = "Path the ALB uses to health-check targets (e.g., '/' for nginx default page)"
  type        = string
  default     = "/"
}

variable "container_port" {
  description = "Port the container listens on (must match ECS task definition and security group rules)"
  type        = number
  default     = 8080
}