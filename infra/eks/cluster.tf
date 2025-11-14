data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

resource "aws_eks_cluster" "yasn" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}
