output "cluster_role_arn" {
  description = "ARN of the IAM role for EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_role_name" {
  description = "Name of the IAM role for EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_group_role_arn" {
  description = "ARN of the IAM role for EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "Name of the IAM role for EKS node groups"
  value       = aws_iam_role.node_group.name
}

