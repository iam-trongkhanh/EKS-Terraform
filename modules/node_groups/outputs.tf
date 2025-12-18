output "node_group_id" {
  description = "Node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "Node group ARN"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Node group status"
  value       = aws_eks_node_group.main.status
}

output "node_group_capacity_type" {
  description = "Node group capacity type"
  value       = aws_eks_node_group.main.capacity_type
}

