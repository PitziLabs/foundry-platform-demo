# modules/cloudtrail/variables.tf

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log delivery"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for CloudTrail log delivery"
  type        = string
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail log files"
  type        = string
  default     = "cloudtrail"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting CloudTrail log files"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID (used in S3 bucket policy conditions)"
  type        = string
}
