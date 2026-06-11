variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "mern-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be dev, staging, prod, or production."
  }
}

# AWS Region (single-region deployment)
variable "aws_region" {
  description = "AWS region for deployment (single region)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1, eu-west-1)."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "instance_types" {
  description = "EC2 instance types for EKS node groups"
  type        = list(string)
  default     = ["m7i-flex.large", "c7i-flex.large"]
}

# Node Group Settings
variable "node_group_desired" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 3

  validation {
    condition     = var.node_group_desired >= 1 && var.node_group_desired <= 100
    error_message = "Desired nodes must be between 1 and 100."
  }
}

variable "node_group_min" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_max" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 10
}

# DocumentDB Configuration
variable "documentdb_database_name" {
  description = "DocumentDB database name"
  type        = string
  default     = "mernapp"
}

variable "documentdb_username" {
  description = "DocumentDB admin username"
  type        = string
  default     = "admin"
}

variable "documentdb_engine_version" {
  description = "Amazon DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "documentdb_instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "documentdb_instance_count" {
  description = "Number of DocumentDB instances in the cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.documentdb_instance_count >= 1 && var.documentdb_instance_count <= 15
    error_message = "DocumentDB instance count must be between 1 and 15."
  }
}

variable "documentdb_backup_retention_period" {
  description = "Backup retention period for DocumentDB"
  type        = number
  default     = 1
}

variable "documentdb_preferred_backup_window" {
  description = "Preferred daily backup window for DocumentDB"
  type        = string
  default     = "03:00-04:00"
}

variable "documentdb_preferred_maintenance_window" {
  description = "Preferred weekly maintenance window for DocumentDB"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "documentdb_parameter_group_family" {
  description = "DocumentDB parameter group family"
  type        = string
  default     = "docdb5.0"
}

# Features
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable AWS Load Balancer Controller for Ingress"
  type        = bool
  default     = true
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for Route53"
  type        = string
  default     = "example.com"
}

# Monitoring
variable "alarm_email" {
  description = "Email for CloudWatch alarms"
  type        = string
  default     = "alerts@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alarm_email))
    error_message = "Must be a valid email address."
  }
}

variable "enable_kubernetes_monitoring" {
  description = "Enable Prometheus and Grafana monitoring on EKS cluster"
  type        = bool
  default     = true
}

variable "monitoring_storage_class_name" {
  description = "Storage class used for Prometheus, Grafana, and Alertmanager persistent volumes"
  type        = string
  default     = "gp2"
}

variable "grafana_persistence_size" {
  description = "Persistent storage size for Grafana"
  type        = string
  default     = "20Gi"
}

variable "prometheus_persistence_size" {
  description = "Persistent storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "alertmanager_persistence_size" {
  description = "Persistent storage size for Alertmanager"
  type        = string
  default     = "20Gi"
}

# variable "tags" {
#   description = "Tags"
#   type        = map(string)
#   default     = {}
# }

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Owner      = "DevOps"
    CostCenter = "Engineering"
    Compliance = "SOC2"
  }
}

# ArgoCD / GitOps
variable "enable_argocd" {
  description = "Enable ArgoCD deployment to clusters"
  type        = bool
  default     = true
}

variable "argocd_certificate_arn" {
  description = "Optional ACM certificate ARN for ArgoCD HTTPS"
  type        = string
  default     = ""
}

variable "argocd_hostname" {
  description = "Optional fully-qualified hostname for ArgoCD (e.g., argocd.example.com). Defaults to argocd-<cluster>.<domain_name>"
  type        = string
  default     = ""
}

# variable "cluster_name" {
#   description = "Name of the EKS cluster."
#   type        = string
# }

# variable "environment" {
#   description = "Deployment environment (dev / staging / production)."
#   type        = string
# }

# variable "domain_name" {
#   description = "Base domain name used to construct service hostnames (e.g. example.com)."
#   type        = string
# }

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Pass via TF_VAR env var or a secrets backend — never hardcode."
  type        = string
  sensitive   = true
}

# variable "acm_certificate_arn" {
#   description = "ARN of the ACM certificate that covers the grafana hostname."
#   type        = string
# }
