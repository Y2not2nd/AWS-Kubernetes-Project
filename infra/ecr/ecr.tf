resource "aws_ecr_repository" "yasn_repos" {
  for_each = toset(var.repositories)
  name     = each.value
}

output "urls" {
  value = {
    for k, r in aws_ecr_repository.yasn_repos : k => r.repository_url
  }
}
