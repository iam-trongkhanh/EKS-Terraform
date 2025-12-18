terraform {
  backend "s3" {
    bucket         = "khanh-learn-devops"
    key            = "dev/eks/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
