##########################################
# GLOBAL
##########################################
 
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

##########################################
# EKS SETTINGS
##########################################

variable "yasn_cluster_name" {
  type    = string
  default = "yasn-eks"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "eks_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "eks_desired_size" {
  type    = number
  default = 2
}

variable "eks_min_size" {
  type    = number
  default = 1
}

variable "eks_max_size" {
  type    = number
  default = 4
}

##########################################
# NETWORK (VPC + SUBNETS)
##########################################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets" {
  type = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

##########################################
# RDS SETTINGS
##########################################

variable "rds_name" {
  type    = string
  default = "yasn_rds"
}

variable "rds_user" {
  type    = string
  default = "postgres"
}

variable "rds_password" {
  type      = string
  sensitive = true
}

##########################################
# TAGS
##########################################

variable "tags" {
  type = map(string)
  default = {
    Project = "yasn"
  }
}
