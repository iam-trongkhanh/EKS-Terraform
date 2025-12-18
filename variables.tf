variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
   default = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "eks-platform"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
   default = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default = "eks-cluster"

}

variable "eks_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default = "10.0.0.0/16"

}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default = [
    "ap-southeast-2a"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
   default = [
    "10.0.1.0/24","10.0.2.0/24"
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
  default = [
   "10.0.101.0/24","10.0.102.0/24"
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

variable "node_group_instance_types" {
  description = "EC2 instance types for managed node groups"
  type        = list(string)
   default = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for node groups (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  default = 1
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in node group"
  type        = number
  default = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
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

variable "jenkins_iam_role_arn" {
  description = "IAM role ARN that Jenkins uses to authenticate to EKS cluster"
  type        = string
  default     = ""
}

variable "manage_aws_auth_configmap" {
  description = "Whether Terraform should manage the aws-auth ConfigMap. Set to false if managed by platform team or GitOps"
  type        = bool
  default = true
}

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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  # Default empty map; add tags via tfvars or override if needed
  default = {}
}

