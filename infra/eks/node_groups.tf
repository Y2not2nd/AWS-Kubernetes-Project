resource "aws_eks_node_group" "yasn_nodes" {
  cluster_name    = aws_eks_cluster.yasn.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_node_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.eks_node_ecr_read_only
  ]
}
