# ============================================================================
# VPC MODULE
# ============================================================================

module "vpc" {
  source = "./modules/vpc"

  name                 = local.vpc_name
  cidr                 = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_public_subnets = var.enable_public_subnets
  public_subnet_cidrs  = var.public_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

# ============================================================================
# IAM MODULE (Roles for EKS and Node Groups)
# ============================================================================

module "iam" {
  source = "./modules/iam"

  cluster_name = local.cluster_name

  tags = local.common_tags
}

# ============================================================================
# EKS CLUSTER MODULE
# ============================================================================

module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_service_ipv4_cidr = "172.20.0.0/16"
  cluster_role_arn          = module.iam.cluster_role_arn

  enabled_cluster_log_types = var.enabled_cluster_log_types

  enable_irsa = true

  tags = local.common_tags

  depends_on = [
    module.vpc,
    module.iam
  ]
}

# ============================================================================
# NODE GROUP MODULE
# ============================================================================

module "node_groups" {
  source = "./modules/node_groups"

  cluster_name    = module.eks.cluster_name
  cluster_version = var.eks_version

  node_group_name      = local.node_group_name
  subnet_ids           = module.vpc.private_subnet_ids
  node_role_arn        = module.iam.node_group_role_arn

  instance_types       = var.node_group_instance_types
  capacity_type        = var.node_group_capacity_type
  min_size             = var.node_group_min_size
  desired_size         = var.node_group_desired_size
  max_size             = var.node_group_max_size
  disk_size            = var.node_group_disk_size
  ami_type             = var.node_group_ami_type

  labels = var.node_group_labels
  taints = var.node_group_taints

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.iam
  ]
}

# ============================================================================
# AWS AUTH CONFIGMAP (Kubernetes Authentication)
# ============================================================================

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [
        {
          rolearn  = module.iam.node_group_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
      ],
      var.jenkins_iam_role_arn != "" ? [
        {
          rolearn  = var.jenkins_iam_role_arn
          username = "jenkins"
          groups   = ["system:masters"]
        }
      ] : [],
      [for role_arn in var.additional_admin_roles : {
        rolearn  = role_arn
        username = split("/", role_arn)[length(split("/", role_arn)) - 1]
        groups   = ["system:masters"]
      }]
    ))
    mapUsers = yamlencode([
      for user_arn in var.additional_admin_users : {
        userarn  = user_arn
        username = split("/", user_arn)[length(split("/", user_arn)) - 1]
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [
    module.eks,
    module.node_groups
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [data]
  }
}

