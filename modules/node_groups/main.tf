# ============================================================================
# EKS MANAGED NODE GROUP
# ============================================================================

resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.cluster_version

  capacity_type  = var.capacity_type
  instance_types = var.instance_types
  disk_size      = var.disk_size
  ami_type       = var.ami_type

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Launch template (optional, using default)
  # If you need custom AMI, user data, or advanced config, create a launch template

  # Remote access (SSH access to nodes)
  # TODO: Configure if SSH access to nodes is required
  # remote_access {
  #   ec2_ssh_key               = "your-key-pair-name"
  #   source_security_group_ids = [aws_security_group.node_ssh.id]
  # }

  labels = var.labels

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  depends_on = [
    var.cluster_name # Ensure cluster exists
  ]

  tags = merge(
    var.tags,
    {
      # Ensure nodes are tagged for cluster autoscaler (if used)
      "k8s.io/cluster-autoscaler/enabled" = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    }
  )
}

