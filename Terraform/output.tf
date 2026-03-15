output "cluster_id" {
  value       = aws_eks_cluster.aniket.id
  description = "The ID of the EKS cluster"
}

output "node_group_id" {
  value       = aws_eks_node_group.aniket.id
  description = "The ID of the EKS node group"
}

output "vpc_id" {
  value       = data.aws_vpc.aniket_vpc.id
  description = "The ID of the existing VPC"
}

output "subnet_ids" {
  value       = [
    data.aws_subnet.aniket_subnet_1.id,
    data.aws_subnet.aniket_subnet_2.id
  ]
  description = "IDs of the subnets used by the EKS cluster"
}
