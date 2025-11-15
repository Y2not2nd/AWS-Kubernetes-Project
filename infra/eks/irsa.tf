resource "aws_iam_openid_connect_provider" "yasn_eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.yasn.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.yasn.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "yasn_external_secrets_policy" {
  name = "yasn-external-secrets-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "yasn_external_secrets_role" {
  name = "yasn-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.yasn_eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.yasn.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:backend-ns:yasn-external-secrets-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_policy_attach" {
  role       = aws_iam_role.yasn_external_secrets_role.name
  policy_arn = aws_iam_policy.yasn_external_secrets_policy.arn
}
