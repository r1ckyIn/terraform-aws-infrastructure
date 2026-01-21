# -----------------------------------------------------------------------------
# TERRAFORM BACKEND CONFIGURATION
# Stores state in S3 with DynamoDB locking
#
# NOTE: Before first use, run the init-backend.sh script to create:
#   - S3 bucket for state storage
#   - DynamoDB table for state locking
#
# Uncomment the backend block after creating the S3 bucket and DynamoDB table.
# -----------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "terraform-aws-infrastructure/dev/terraform.tfstate"
#     region         = "ap-southeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
