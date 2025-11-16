terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

##########################################
# NETWORK (VPC, subnets, routing)
##########################################

module "yasn_network" {
  source = "./network"

  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  tags               = var.tags
}

##########################################
# EKS CLUSTER MODULE
##########################################

module "yasn_eks" {
  source = "./eks"

  cluster_name     = var.yasn_cluster_name
  cluster_version  = var.eks_version

  vpc_id           = module.yasn_network.vpc_id
  subnet_ids       = module.yasn_network.private_subnet_ids

  node_group_name  = "yasn-ng"
  instance_type    = var.eks_instance_type

  desired_size     = var.eks_desired_size
  min_size         = var.eks_min_size
  max_size         = var.eks_max_size

  tags             = var.tags
}

##########################################
# ECR REPOSITORIES
##########################################

module "yasn_ecr" {
  source = "./ecr"

  repositories = [
    "yasn-frontend",
    "yasn-backend",
    "yasn-worker"
  ]
}

##########################################
# RDS POSTGRES DATABASE
##########################################

module "yasn_rds" {
  source = "./rds"

  db_name           = var.rds_name
  db_user           = var.rds_user
  db_password       = var.rds_password
  db_engine_version = var.rds_engine_version

  subnet_ids        = module.yasn_network.private_subnet_ids
  vpc_id            = module.yasn_network.vpc_id
}

##########################################
# API GATEWAY (NEWLY ADDED)
##########################################

module "yasn_api_gateway" {
  source = "./api_gateway"

  # This must match your api_gateway/variables.tf
  backend_ingress_url = module.yasn_eks.backend_ingress_url
}
