output "cluster_id" {
  value = aws_eks_cluster.aniket.id
}

output "node_group_id" {
  value = aws_eks_node_group.aniket_node_group_v3.id
}

output "vpc_id" {
  value = data.aws_vpc.aniket_vpc.id
}

output "subnet_ids" {
  value = [
    data.aws_subnet.aniket_subnet_1.id,
    data.aws_subnet.aniket_subnet_2.id
  ]
}
