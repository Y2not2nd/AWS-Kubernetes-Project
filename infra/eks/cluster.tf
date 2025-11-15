resource "aws_eks_cluster" "yasn" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.cluster.id]
    endpoint_public_access = true
    endpoint_private_access = true
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_resource_controller
  ]
}
