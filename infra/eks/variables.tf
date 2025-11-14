variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which to deploy EKS"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS"
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for node group"
  type        = string
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes in node group"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of nodes in node group"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to EKS resources"
  type        = map(string)
  default     = {}
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}
