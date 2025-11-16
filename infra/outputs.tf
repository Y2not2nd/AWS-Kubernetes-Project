output "eks_cluster_name" {
  value = module.yasn_eks.cluster_name
}

output "rds_endpoint" {
  value = module.yasn_rds.db_endpoint
}

output "ecr_urls" {
  value = module.yasn_ecr.urls
}

output "backend_ingress_url" {
  value = aws_lb.your_ingress_load_balancer.dns_name
}

