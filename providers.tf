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

# Get existing EKS cluster info for Kubernetes provider
# This works both for new clusters and when updating existing infrastructure
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

# Kubernetes provider configured using data source to work with existing clusters
provider "kubernetes" {
  host                   = data.aws_eks_cluster.existing.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.existing.name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

