# ============================================================================
# CORE CONFIGURATION
# ============================================================================

variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  # TODO: Set default or provide via terraform.tfvars or environment variable
  default = "________REPLACE_WITH_AWS_REGION________"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "eks-platform"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  # TODO: Set appropriate environment value
  default = "________REPLACE_WITH_ENVIRONMENT_NAME________"
}

# ============================================================================
# EKS CLUSTER CONFIGURATION
# ============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  # TODO: Set cluster name (should be unique within AWS account/region)
  default = "________REPLACE_WITH_EKS_CLUSTER_NAME________"
}

variable "eks_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  # Defaulting to a stable, widely-adopted version
  # AWS EKS supports 1-2 minor versions behind current
  # This version was chosen as it's stable and supports modern Kubernetes features
  # TODO: Verify this version is supported in your AWS region
  default = "1.28"
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

# ============================================================================
# VPC & NETWORKING CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  # TODO: Ensure CIDR doesn't conflict with existing networks
  default = "________REPLACE_WITH_VPC_CIDR_BLOCK________"
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  # TODO: Replace with actual AZs in your region (e.g., ["us-east-1a", "us-east-1b", "us-east-1c"])
  default = [
    "________REPLACE_WITH_AZ_1________",
    "________REPLACE_WITH_AZ_2________",
    "________REPLACE_WITH_AZ_3________"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  # TODO: Ensure these don't overlap with VPC CIDR or each other
  default = [
    "________REPLACE_WITH_PRIVATE_SUBNET_1_CIDR________",
    "________REPLACE_WITH_PRIVATE_SUBNET_2_CIDR________",
    "________REPLACE_WITH_PRIVATE_SUBNET_3_CIDR________"
  ]
}

variable "enable_public_subnets" {
  description = "Enable public subnets for NAT Gateways (required for private subnet internet access)"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, only used if enable_public_subnets = true)"
  type        = list(string)
  # TODO: If enable_public_subnets = true, provide CIDR blocks
  default = [
    "________REPLACE_WITH_PUBLIC_SUBNET_1_CIDR________",
    "________REPLACE_WITH_PUBLIC_SUBNET_2_CIDR________",
    "________REPLACE_WITH_PUBLIC_SUBNET_3_CIDR________"
  ]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access (has cost implications: ~$32/month per NAT Gateway)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all AZs (cost optimization, reduces HA)"
  type        = bool
  default     = false
}

# ============================================================================
# NODE GROUP CONFIGURATION
# ============================================================================

variable "node_group_instance_types" {
  description = "EC2 instance types for managed node groups"
  type        = list(string)
  # TODO: Choose appropriate instance types based on workload requirements
  # Common choices: ["t3.medium", "t3.large", "m5.large", "m5.xlarge"]
  default = ["________REPLACE_WITH_NODE_INSTANCE_TYPE________"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for node groups (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  # TODO: Set based on availability requirements
  default = 1
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in node group"
  type        = number
  # TODO: Set based on expected workload
  default = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
  # TODO: Set based on scaling requirements and cost limits
  default = 5
}

variable "node_group_disk_size" {
  description = "Disk size (GB) for node group instances"
  type        = number
  default     = 50
}

variable "node_group_ami_type" {
  description = "AMI type for node group (AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64)"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_group_labels" {
  description = "Kubernetes labels to apply to nodes"
  type        = map(string)
  default = {
    "managed-by" = "terraform"
  }
}

variable "node_group_taints" {
  description = "Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

# ============================================================================
# JENKINS & CI/CD CONFIGURATION
# ============================================================================

variable "jenkins_iam_role_arn" {
  description = "IAM role ARN that Jenkins uses to authenticate to EKS cluster"
  type        = string
  # TODO: Provide the ARN of the IAM role that Jenkins assumes
  # This role must have permissions to assume the EKS node group role or use eks:DescribeCluster
  default = "________REPLACE_WITH_JENKINS_IAM_ROLE_ARN________"
}

variable "manage_aws_auth_configmap" {
  description = "Whether Terraform should manage the aws-auth ConfigMap. Set to false if managed by platform team or GitOps"
  type        = bool
  # TODO: Decide who manages aws-auth ConfigMap:
  # true = Terraform manages it (recommended for initial setup)
  # false = Platform team manages manually or via GitOps
  default = true
}

# ============================================================================
# ADDITIONAL ACCESS CONFIGURATION
# ============================================================================

variable "additional_admin_roles" {
  description = "Additional IAM role ARNs to grant cluster admin access (beyond Jenkins role)"
  type        = list(string)
  default     = []
}

variable "additional_admin_users" {
  description = "Additional IAM user ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

# ============================================================================
# TAGS
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "________REPLACE_WITH_ENVIRONMENT_NAME________"
    # TODO: Add additional tags as required by your organization
    # Owner       = "platform-team"
    # CostCenter  = "engineering"
  }
}

