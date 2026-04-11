variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}
variable "project" {
  description = "Project name"
  type        = string
  default     = "foundry"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
