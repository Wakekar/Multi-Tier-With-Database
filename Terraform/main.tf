provider "aws" {
  region = "ap-south-1"
}

# Use existing VPC
data "aws_vpc" "aniket_vpc" {
  id = "vpc-087bcd22867e1366f"
}

# Existing subnets
data "aws_subnet" "aniket_subnet_1" {
  id = "subnet-06c612ff09bcab060"
}

data "aws_subnet" "aniket_subnet_2" {
  id = "subnet-0142550db89a86499"
}

# Existing Security Group for EKS
data "aws_security_group" "aniket_cluster_sg" {
  id = "sg-0ac52e60282081cd9"
}

# IAM Role for EKS Cluster (new unique name)
resource "aws_iam_roles" "aniket_cluster_role_v3" {
  name = "aniket-eks-cluster-role-v3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aniket_cluster_role_policy_v2" {
  role       = aws_iam_role.aniket_cluster_role_v2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group (new unique name)
resource "aws_iam_roles" "aniket_node_group_role_v3" {
  name = "aniket-node-group-role-v3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aniket_node_group_role_policy_v2" {
  role       = aws_iam_role.aniket_node_group_role_v2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "aniket_node_group_cni_policy_v2" {
  role       = aws_iam_role.aniket_node_group_role_v2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "aniket_node_group_registry_policy_v2" {
  role       = aws_iam_role.aniket_node_group_role_v2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "aniket" {
  name     = "aniket-eks-cluster"
  role_arn = aws_iam_role.aniket_cluster_role_v2.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.aniket_subnet_1.id, data.aws_subnet.aniket_subnet_2.id]
    security_group_ids = [data.aws_security_group.aniket_cluster_sg.id]
  }

  tags = {
    Name = "aniket-eks-cluster"
  }
}

# EKS Node Group (new name)
resource "aws_eks_node_group" "aniket_node_group_v2" {
  cluster_name    = aws_eks_cluster.aniket.name
  node_group_name = "aniket-node-group-v2"
  node_role_arn   = aws_iam_role.aniket_node_group_role_v2.arn
  subnet_ids      = [data.aws_subnet.aniket_subnet_1.id, data.aws_subnet.aniket_subnet_2.id]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["c7i-flex.large"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [data.aws_security_group.aniket_cluster_sg.id]
  }

  tags = {
    Name = "aniket-node-group-v2"
  }
}
