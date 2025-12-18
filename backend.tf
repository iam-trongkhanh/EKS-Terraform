# IMPORTANT: Configure remote backend before first terraform init
# Replace placeholders with actual values

terraform {
  backend "s3" {
    # REQUIRED: S3 bucket name for Terraform state
    bucket = "________REPLACE_WITH_S3_BUCKET_NAME_FOR_TERRAFORM_STATE________"

    # REQUIRED: S3 key path for state file
    # Recommended: Use environment prefix (e.g., "dev/eks/terraform.tfstate")
    key = "________REPLACE_WITH_STATE_FILE_KEY_PATH________"

    # REQUIRED: AWS region for S3 bucket
    region = "________REPLACE_WITH_AWS_REGION_FOR_BACKEND________"

    # REQUIRED: DynamoDB table name for state locking
    dynamodb_table = "________REPLACE_WITH_DYNAMODB_TABLE_NAME_FOR_LOCKING________"

    # Enable state encryption at rest
    encrypt = true

    # Optional: KMS key ID for encryption (if using CMK)
    # kms_key_id = "arn:aws:kms:region:account:key/key-id"
  }
}

# TODO: Create S3 bucket and DynamoDB table before initializing backend
# 
# Example commands (replace placeholders):
# aws s3 mb s3://REPLACE_WITH_S3_BUCKET_NAME_FOR_TERRAFORM_STATE --region REPLACE_WITH_AWS_REGION_FOR_BACKEND
# aws s3api put-bucket-versioning --bucket REPLACE_WITH_S3_BUCKET_NAME_FOR_TERRAFORM_STATE --versioning-configuration Status=Enabled
# aws s3api put-bucket-encryption --bucket REPLACE_WITH_S3_BUCKET_NAME_FOR_TERRAFORM_STATE --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# 
# aws dynamodb create-table \
#   --table-name REPLACE_WITH_DYNAMODB_TABLE_NAME_FOR_LOCKING \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region REPLACE_WITH_AWS_REGION_FOR_BACKEND

