provider "aws" {
  region = "ap-south-1"
}

############################
# VPC
############################
data "aws_vpc" "devops_vpc" {
  id = "vpc-0adb31ddbaf14d3bf"
}

############################
# PRIVATE SUBNETS (2 AZs)
############################
data "aws_subnet" "private_a" {
  id = "subnet-04b8571a304250a1b"
}

data "aws_subnet" "private_b" {
  id = "subnet-0b9b8056f6cdecac2"
}

############################
# TAGS REQUIRED FOR EKS
############################
resource "aws_ec2_tag" "private_a_cluster" {
  resource_id = data.aws_subnet.private_a.id
  key   = "kubernetes.io/cluster/aniket-eks-cluster"
  value = "shared"
}

resource "aws_ec2_tag" "private_b_cluster" {
  resource_id = data.aws_subnet.private_b.id
  key   = "kubernetes.io/cluster/aniket-eks-cluster"
  value = "shared"
}

resource "aws_ec2_tag" "private_a_elb" {
  resource_id = data.aws_subnet.private_a.id
  key   = "kubernetes.io/role/internal-elb"
  value = "1"
}

resource "aws_ec2_tag" "private_b_elb" {
  resource_id = data.aws_subnet.private_b.id
  key   = "kubernetes.io/role/internal-elb"
  value = "1"
}

############################
# SECURITY GROUP
############################
data "aws_security_group" "devops_sg" {
  id = "sg-0bd9eba5479b04af8"
}

############################
# IAM ROLES
############################
resource "aws_iam_role" "cluster_role" {
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

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node_role" {
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

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################
# EKS CLUSTER
############################
resource "aws_eks_cluster" "aniket" {
  name     = "aniket-eks-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.private_a.id,
      data.aws_subnet.private_b.id
    ]

    security_group_ids      = [data.aws_security_group.devops_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Name = "aniket-eks-cluster"
  }
}

############################
# NODE GROUP (STABLE)
############################
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.aniket.name
  node_group_name = "aniket-node-group-v3"
  node_role_arn   = aws_iam_role.node_role.arn

  subnet_ids = [
    data.aws_subnet.private_a.id,
    data.aws_subnet.private_b.id
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["c7i-flex.large"]  # ✅ your choice

  disk_size = 20  # ✅ added as requested

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [data.aws_security_group.devops_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]

  tags = {
    Name = "aniket-node-group-v3"
  }
}
