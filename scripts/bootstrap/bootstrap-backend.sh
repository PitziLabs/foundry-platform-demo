#!/bin/bash
set -euo pipefail

# Configuration
AWS_PROFILE="aws-lab"
AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile "${AWS_PROFILE}")
if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "ERROR: Could not determine AWS account ID. Check your AWS_PROFILE." >&2
  exit 1
fi
BUCKET_NAME="aws-lab-tfstate-${ACCOUNT_ID}"
TABLE_NAME="aws-lab-tfstate-lock"

echo "==> Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}"

echo "==> Enabling versioning on state bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  --profile "${AWS_PROFILE}"

echo "==> Enabling server-side encryption (AES256 for now, KMS later)..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }' \
  --profile "${AWS_PROFILE}"

echo "==> Blocking all public access on state bucket..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --profile "${AWS_PROFILE}"

echo "==> Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}"

echo ""
echo "==> Bootstrap complete!"
echo "    State bucket: ${BUCKET_NAME}"
echo "    Lock table:   ${TABLE_NAME}"
echo "    Region:       ${AWS_REGION}"
