resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids                   = var.subnet_ids
    endpoint_private_access      = true
    endpoint_public_access       = true
    public_access_cidrs         = ["0.0.0.0/0"]
  }

  version = var.kubernetes_version

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn

  subnet_ids = var.subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = var.instance_types

  tags = {
    Name        = "${var.cluster_name}-worker-nodes"
    Environment = var.environment
  }
}