# -----------------------------------------------------------------------------
# TERRAFORM BACKEND CONFIGURATION
# Stores state in S3 with DynamoDB locking
# -----------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "terraform-aws-infrastructure/staging/terraform.tfstate"
#     region         = "ap-southeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
