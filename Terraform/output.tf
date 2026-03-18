output "cluster_id" {
  value = aws_eks_cluster.aniket.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.aniket.endpoint
}

output "node_group_id" {
  value = aws_eks_node_group.node_group.id
}

output "vpc_id" {
  value = data.aws_vpc.devops_vpc.id
}

output "subnet_ids" {
  value = [
    data.aws_subnet.private_a.id,
    data.aws_subnet.private_b.id
  ]
}

output "cluster_security_group_id" {
  value = data.aws_security_group.devops_sg.id
}
