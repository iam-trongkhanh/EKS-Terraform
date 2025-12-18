locals {
  name_prefix = "${var.project_name}-${var.environment}"

  cluster_name = var.cluster_name

  vpc_name = "${local.name_prefix}-vpc"

  node_group_name = "${local.name_prefix}-node-group"

  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ClusterName = local.cluster_name
    }
  )
}

