provider "aws" {
  region = "ap-south-1"
}

# Use existing VPC
data "aws_vpc" "aniket_vpc" {
  id = "vpc-087bcd22867e1366f"
}

# Existing subnets (pick one from each AZ)
data "aws_subnet" "aniket_subnet_1" {
  id = "subnet-06c612ff09bcab060"  # ap-south-1a
}

data "aws_subnet" "aniket_subnet_2" {
  id = "subnet-0142550db89a86499"  # ap-south-1b
}

# Existing Security Group for EKS
data "aws_security_group" "aniket_cluster_sg" {
  id = "sg-0ac52e60282081cd9"
}

# IAM Role for EKS Cluster (renamed to avoid conflicts)
resource "aws_iam_role" "aniket_cluster_role" {
  name = "aniket-eks-cluster-role-new"

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

resource "aws_iam_role_policy_attachment" "aniket_cluster_role_policy" {
  role       = aws_iam_role.aniket_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group (renamed to avoid conflicts)
resource "aws_iam_role" "aniket_node_group_role" {
  name = "aniket-node-group-role-new"

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

resource "aws_iam_role_policy_attachment" "aniket_node_group_role_policy" {
  role       = aws_iam_role.aniket_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "aniket_node_group_cni_policy" {
  role       = aws_iam_role.aniket_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "aniket_node_group_registry_policy" {
  role       = aws_iam_role.aniket_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "aniket" {
  name     = "aniket-eks-cluster"
  role_arn = aws_iam_role.aniket_cluster_role.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.aniket_subnet_1.id, data.aws_subnet.aniket_subnet_2.id]
    security_group_ids = [data.aws_security_group.aniket_cluster_sg.id]
  }

  tags = {
    Name = "aniket-eks-cluster"
  }
}

# EKS Node Group (new name)
resource "aws_eks_node_group" "aniket_new" {
  cluster_name    = aws_eks_cluster.aniket.name
  node_group_name = "aniket-node-group-new"
  node_role_arn   = aws_iam_role.aniket_node_group_role.arn
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
    Name = "aniket-node-group-new"
  }
}
