terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# EKS auth
data "aws_eks_cluster_auth" "primary" {
  name = module.primary_eks.cluster_name
}

provider "kubernetes" {
  host                   = module.primary_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.primary_eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.primary.token
}

provider "helm" {
  kubernetes {
    host                   = module.primary_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.primary_eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.primary.token
  }
}

# Primary Region EKS Cluster (single-region deployment)
module "primary_eks" {
  source = "./modules/eks"

  cluster_name       = var.project_name
  cluster_version    = var.kubernetes_version
  region             = var.aws_region
  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  node_group_desired = var.node_group_desired
  node_group_min     = var.node_group_min
  node_group_max     = var.node_group_max
  instance_types     = var.instance_types
  enable_monitoring  = var.enable_monitoring
  enable_autoscaling = var.enable_autoscaling
  enable_ingress     = var.enable_ingress

  tags = var.tags
}

# # DocumentDB in the same region
# module "primary_documentdb" {
#   source = "./modules/documentdb"

#   cluster_identifier                      = "${var.project_name}-docdb"
#   vpc_id                                  = module.primary_eks.vpc_id
#   private_subnet_ids                      = module.primary_eks.private_subnet_ids
#   eks_security_group_ids                  = [module.primary_eks.cluster_security_group_id]
#   private_cidr_blocks                     = [var.vpc_cidr]
#   environment                             = var.environment
#   documentdb_username                     = var.documentdb_username
#   documentdb_database_name                = var.documentdb_database_name
#   documentdb_engine_version               = var.documentdb_engine_version
#   documentdb_instance_class               = var.documentdb_instance_class
#   instance_count                          = var.documentdb_instance_count
#   documentdb_backup_retention_period      = var.documentdb_backup_retention_period
#   documentdb_preferred_backup_window      = var.documentdb_preferred_backup_window
#   documentdb_preferred_maintenance_window = var.documentdb_preferred_maintenance_window
#   parameter_group_family                  = var.documentdb_parameter_group_family
#   tags                                    = var.tags
# }

# CloudWatch Monitoring for single-region cluster
# module "monitoring" {
#   source = "./modules/monitoring"

#   cluster_name            = module.primary_eks.cluster_name
#   aws_region              = var.aws_region
#   alb_arn                 = module.primary_eks.alb_arn
#   autoscaling_group_names = [module.primary_eks.asg_name]
#   enable_dashboard        = var.enable_monitoring
#   enable_alarms           = true
#   alarm_email             = var.alarm_email

#   tags = var.tags
# }

# # Kubernetes-native Prometheus + Grafana monitoring for the cluster
# module "primary_kube_monitoring" {
#   count  = var.enable_monitoring && var.enable_kubernetes_monitoring ? 1 : 0
#   source = "./modules/kube_monitoring"
#   providers = {
#     kubernetes = kubernetes
#     helm       = helm
#   }

#   cluster_name                  = module.primary_eks.cluster_name
#   cluster_endpoint              = module.primary_eks.cluster_endpoint
#   cluster_ca_certificate        = module.primary_eks.cluster_ca_certificate
#   domain_name                   = var.domain_name
#   environment                   = var.environment
#   region                        = var.aws_region
#   grafana_host                  = "grafana-${module.primary_eks.cluster_name}.${var.domain_name}"
#   storage_class_name            = var.monitoring_storage_class_name
#   grafana_persistence_size      = var.grafana_persistence_size
#   prometheus_persistence_size   = var.prometheus_persistence_size
#   alertmanager_persistence_size = var.alertmanager_persistence_size
#   tags                          = var.tags
# }

# ArgoCD - Primary
module "primary_argocd" {
  source = "./modules/argocd"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    aws        = aws
  }

  project_name           = var.project_name
  cluster_name           = module.primary_eks.cluster_name
  domain_name            = var.domain_name
  region                 = var.aws_region
  admin_username         = "admin"
  replica_count          = 2
  load_balancer_name     = "${var.project_name}-${module.primary_eks.cluster_name}-argocd"
  argocd_hostname        = var.argocd_hostname != "" ? var.argocd_hostname : "argocd-${module.primary_eks.cluster_name}.${var.domain_name}"
  argocd_certificate_arn = var.argocd_certificate_arn

  depends_on = [module.primary_eks]
}
# =============================================================================
# root/main.tf  (excerpt — add this block to your existing root configuration)
# =============================================================================
# This snippet shows how to call the monitoring module from your root Terraform
# configuration that already manages the EKS cluster, node groups, ALB
# controller, and ArgoCD.
#
# Prerequisites already assumed to exist in your root state:
#   - module.eks          → AWS EKS cluster (aws_eks_cluster)
#   - module.eks_auth     → or equivalent kubeconfig / cluster endpoint outputs
#   - AWS Load Balancer Controller installed and running
#   - An ACM certificate covering var.grafana_hostname
# =============================================================================

# -----------------------------------------------------------------------------
# Provider configuration (root level)
# -----------------------------------------------------------------------------
# The Helm and Kubernetes providers must be configured with the EKS cluster
# endpoint and authentication token before the monitoring module is called.
# These are typically already present in your root providers.tf — shown here
# for completeness.
# -----------------------------------------------------------------------------

# # -----------------------------------------------------------------------------
# # Monitoring Module
# # -----------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/Monitoring-2"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  namespace     = "monitoring"
  environment   = var.environment
  chart_version = "58.2.2"

  grafana_admin_user     = "admin"
  grafana_admin_password = var.grafana_admin_password

  grafana_hostname     = "grafana.${var.domain_name}"
  grafana_storage_size = "10Gi"

  prometheus_retention    = "30d"
  prometheus_storage_size = "50Gi"

  alertmanager_storage_size = "5Gi"

  storage_class_name = "gp2"

  acm_certificate_arn = ""
  alb_scheme          = "internet-facing"
  alb_group_name      = "monitoring"

  depends_on = [
    module.primary_eks,
    module.primary_argocd
  ]
}

# # =============================================================================
# # root/variables.tf  (additions needed)
# # =============================================================================

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

# variable "grafana_admin_user" {
#   description = "Grafana admin username."
#   type        = string
#   default     = "admin"
# }

# variable "grafana_admin_password" {
#   description = "Grafana admin password. Pass via TF_VAR env var or a secrets backend — never hardcode."
#   type        = string
#   sensitive   = true
# }

# variable "acm_certificate_arn" {
#   description = "ARN of the ACM certificate that covers the grafana hostname."
#   type        = string
# }

# =============================================================================
# root/outputs.tf  (additions needed)
# =============================================================================

# output "grafana_url" {
#   description = "Grafana dashboard URL."
#   value       = module.monitoring.grafana_url
# }

# output "grafana_admin_username" {
#   description = "Grafana admin username."
#   value       = module.monitoring.grafana_admin_username
# }

# output "grafana_admin_password" {
#   description = "Grafana admin password."
#   value       = module.monitoring.grafana_admin_password
#   sensitive   = true
# }

# output "monitoring_namespace" {
#   description = "Kubernetes namespace for monitoring components."
#   value       = module.monitoring.monitoring_namespace
# }

# # =============================================================================
# # root/terraform.tfvars  (example — DO NOT commit real passwords to Git)
# # =============================================================================
# # cluster_name           = "my-eks-cluster"
# # environment            = "production"
# # domain_name            = "example.com"
# # grafana_admin_user     = "admin"
# # acm_certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/xxxx"
# #
# # grafana_admin_password is intentionally omitted here.
# # Supply it via environment variable:
# #   export TF_VAR_grafana_admin_password="<secure-password>"
# # or via a secrets backend integration (AWS Secrets Manager, Vault, etc.)
