# Configure remote state storage here before running in a team/production setting.
# Local state is used by default so this works out of the box for testing.
#
# Example S3 backend (uncomment and fill in once you have a state bucket + lock table):
#
# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket-name"
#     key            = "three-tier-app/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
