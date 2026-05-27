variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "node_group_desired" {
  description = "Desired number of nodes"
  type        = number
}

variable "node_group_min" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_group_max" {
  description = "Maximum number of nodes"
  type        = number
}

variable "instance_types" {
  description = "EC2 instance types"
  type        = list(string)
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ALB ingress controller"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
