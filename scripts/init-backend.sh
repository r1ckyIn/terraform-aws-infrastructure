#!/bin/bash
# -----------------------------------------------------------------------------
# Initialize Terraform Backend
# Creates S3 bucket and DynamoDB table for Terraform state management
#
# Usage:
#   ./scripts/init-backend.sh [bucket-name] [region]
#
# Example:
#   ./scripts/init-backend.sh my-terraform-state ap-southeast-2
# -----------------------------------------------------------------------------

set -e

# Configuration
BUCKET_NAME=${1:-"terraform-state-$(aws sts get-caller-identity --query Account --output text)"}
REGION=${2:-"ap-southeast-2"}
DYNAMODB_TABLE="terraform-state-lock"

echo "=============================================="
echo "Terraform Backend Initialization"
echo "=============================================="
echo "S3 Bucket:      ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo "Region:         ${REGION}"
echo "=============================================="
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

echo "Current AWS Identity:"
aws sts get-caller-identity
echo ""

# Create S3 bucket
echo "Creating S3 bucket..."
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo "Bucket ${BUCKET_NAME} already exists"
else
    if [ "${REGION}" == "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${REGION}"
    else
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${REGION}" \
            --create-bucket-configuration LocationConstraint="${REGION}"
    fi
    echo "Bucket created successfully"
fi

# Enable versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
echo "Versioning enabled"

# Enable encryption
echo "Enabling encryption..."
aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            },
            "BucketKeyEnabled": true
        }]
    }'
echo "Encryption enabled"

# Block public access
echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
echo "Public access blocked"

# Create DynamoDB table for state locking
echo "Creating DynamoDB table..."
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>/dev/null; then
    echo "DynamoDB table ${DYNAMODB_TABLE} already exists"
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}"
    echo "DynamoDB table created"

    # Wait for table to be active
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
    echo "Table is now active"
fi

echo ""
echo "=============================================="
echo "Backend initialization complete!"
echo "=============================================="
echo ""
echo "Update your backend.tf files with:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"${BUCKET_NAME}\""
echo "    key            = \"terraform-aws-infrastructure/<env>/terraform.tfstate\""
echo "    region         = \"${REGION}\""
echo "    encrypt        = true"
echo "    dynamodb_table = \"${DYNAMODB_TABLE}\""
echo "  }"
echo "}"
echo ""
echo "=============================================="
