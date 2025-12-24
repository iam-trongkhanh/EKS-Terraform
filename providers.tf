provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        ManagedBy = "Terraform"
        Project   = var.project_name
      }
    )
  }
}

# Get EKS cluster token for Kubernetes provider authentication
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Kubernetes provider configured using EKS module outputs
# Note: This will only work after the EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

