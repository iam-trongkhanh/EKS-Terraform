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

# Kubernetes provider configured after EKS cluster is created
# See outputs.tf and main.tf for cluster configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

