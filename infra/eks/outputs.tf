output "cluster_name" {
  value = aws_eks_cluster.yasn.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.yasn.endpoint
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.yasn_eks_oidc.arn
}
