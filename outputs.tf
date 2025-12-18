# ============================================================================
# EKS CLUSTER OUTPUTS
# ============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.cluster_oidc_provider_arn
}

# ============================================================================
# VPC OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (if enabled)"
  value       = module.vpc.public_subnet_ids
}

# ============================================================================
# IAM OUTPUTS
# ============================================================================

output "cluster_role_arn" {
  description = "IAM role ARN for EKS cluster"
  value       = module.iam.cluster_role_arn
}

output "node_group_role_arn" {
  description = "IAM role ARN for EKS node groups"
  value       = module.iam.node_group_role_arn
}

# ============================================================================
# NODE GROUP OUTPUTS
# ============================================================================

output "node_group_id" {
  description = "Node group ID"
  value       = module.node_groups.node_group_id
}

output "node_group_arn" {
  description = "Node group ARN"
  value       = module.node_groups.node_group_arn
}

# ============================================================================
# KUBECONFIG GENERATION (FOR REFERENCE)
# ============================================================================

output "kubeconfig_generation_command" {
  description = "Command to generate kubeconfig for this cluster (run locally)"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ============================================================================
# JENKINS INTEGRATION OUTPUTS
# ============================================================================

output "jenkins_integration_note" {
  description = "Instructions for Jenkins to access the cluster"
  value = var.jenkins_iam_role_arn != "________REPLACE_WITH_JENKINS_IAM_ROLE_ARN________" ? "Jenkins role configured in aws-auth ConfigMap. Ensure Jenkins assumes this role before accessing cluster." : "WARNING: Jenkins IAM role ARN not configured. Update jenkins_iam_role_arn variable."
}

