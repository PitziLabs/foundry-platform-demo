# modules/cloudtrail/main.tf
# =============================================================================
# CLOUDTRAIL: API AUDIT LOGGING
#
# This module creates:
#   1. An S3 bucket policy granting CloudTrail write access
#   2. A CloudTrail trail capturing all management events
#
# Every API call in the account is recorded — console clicks, CLI commands,
# SDK calls, and service-to-service actions. Logs are encrypted with your
# CMK and delivered to the existing S3 bucket under a "cloudtrail/" prefix.
#
# Key design choices:
#   - is_multi_region_trail = true: captures events from ALL regions, not
#     just us-east-1. Even if you only deploy to one region, IAM and other
#     global services generate events in us-east-1 — this ensures nothing
#     is missed.
#   - enable_log_file_validation = true: CloudTrail creates a digest file
#     every hour with a hash of all log files. This lets you prove logs
#     haven't been tampered with — a key compliance requirement.
#   - Management events only (no data events): Data events track individual
#     S3 object operations and Lambda invocations, which would generate
#     massive volume and cost for a lab. Management events cover the
#     "who created/modified/deleted what resource" questions.
# =============================================================================


# -----------------------------------------------------------------------------
# S3 BUCKET POLICY
#
# CloudTrail requires explicit permission to write to your S3 bucket.
# This is a resource-based policy on the bucket (not an IAM policy)
# because CloudTrail operates as a service principal, not as an IAM role
# you control.
#
# Two statements:
#   1. GetBucketAcl — CloudTrail checks it has permission before writing
#   2. PutObject — CloudTrail delivers encrypted log files
#
# The PutObject condition requires "bucket-owner-full-control" ACL,
# which ensures you (the bucket owner) retain full access to log files
# even in cross-account scenarios. In single-account use it's still
# required by the CloudTrail API.
#
# NOTE: aws_s3_bucket_policy replaces any existing bucket policy.
# Since our S3 module didn't create a bucket policy, this is safe.
# If we later need to add more policy statements (e.g., for AWS Config),
# we'll consolidate them into a single aws_s3_bucket_policy resource
# in a shared location.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudtrail_s3" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [var.s3_bucket_arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/${var.s3_key_prefix}/AWSLogs/${var.aws_account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = var.s3_bucket_name
  policy = data.aws_iam_policy_document.cloudtrail_s3.json
}


# -----------------------------------------------------------------------------
# CLOUDTRAIL TRAIL
#
# The trail itself — the configuration that tells CloudTrail where to
# deliver events and how to encrypt them.
#
# depends_on the bucket policy is critical: if the trail is created
# before the bucket policy, CloudTrail will fail to validate that it
# can write to the bucket, and the aws_cloudtrail resource will error.
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  name = "${var.project}-${var.environment}-trail"

  # Where to deliver logs
  s3_bucket_name = var.s3_bucket_name
  s3_key_prefix  = var.s3_key_prefix

  # Encryption — use our CMK directly (not just S3 default encryption)
  kms_key_id = var.kms_key_arn

  # Capture events from ALL regions, not just the one we deploy to.
  # IAM, STS, and CloudFront are global services that emit events in
  # us-east-1 regardless of where you call them from.
  is_multi_region_trail         = true
  include_global_service_events = true

  # Log file validation creates hourly digest files with SHA-256 hashes
  # of all log files. This enables tamper detection — you can prove your
  # audit trail hasn't been modified after the fact.
  enable_log_file_validation = true

  # Start logging immediately
  enable_logging = true

  # The bucket policy must exist before CloudTrail tries to validate access
  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Name = "${var.project}-${var.environment}-trail"
  }
}
