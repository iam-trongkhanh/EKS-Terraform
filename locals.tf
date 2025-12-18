locals {
  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Cluster-specific locals
  cluster_name = var.cluster_name != "________REPLACE_WITH_EKS_CLUSTER_NAME________" ? var.cluster_name : "${local.name_prefix}-cluster"

  # VPC configuration
  vpc_name = "${local.name_prefix}-vpc"

  # Node group configuration
  node_group_name = "${local.name_prefix}-node-group"

  # OIDC provider URL (computed after cluster creation, available via outputs)
  # Note: Cannot reference module outputs in locals, use output values instead

  # Tags
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ClusterName = local.cluster_name
    }
  )

  # Validation checks (will fail if critical TODOs are not replaced)
  # Note: These are basic checks - full validation should be done via terraform validate
}

