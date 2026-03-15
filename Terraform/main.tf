provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "aniket_vpc" {
  id = "vpc-087bcd22867e1366f"
}

data "aws_subnet" "aniket_subnet" {
  id = "subnet-06c612ff09bcab060"
}

data "aws_security_group" "aniket_cluster_sg" {
  id = "sg-0ac52e60282081cd9"
}

resource "aws_eks_cluster" "aniket" {
  name     = "aniket-eks-cluster"
  role_arn = aws_iam_role.aniket_cluster_role.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.aniket_subnet.id]
    security_group_ids = [data.aws_security_group.aniket_cluster_sg.id]
  }

  tags = {
    Name = "aniket-eks-cluster"
  }
}

resource "aws_eks_node_group" "aniket" {
  cluster_name    = aws_eks_cluster.aniket.name
  node_group_name = "aniket-node-group"
  node_role_arn   = aws_iam_role.aniket_node_group_role.arn
  subnet_ids      = [data.aws_subnet.aniket_subnet.id]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.large"]

  remote_access {
    ec2_ssh_key = "thinkpad-2"
    source_security_group_ids = [data.aws_security_group.aniket_cluster_sg.id]
  }

  tags = {
    Name = "aniket-node-group"
  }
}

resource "aws_iam_role" "aniket_cluster_role" {
  name = "aniket-eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
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

resource "aws_iam_role" "aniket_node_group_role" {
  name = "aniket-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
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
