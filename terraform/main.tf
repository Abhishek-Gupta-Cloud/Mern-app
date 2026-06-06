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

  # Uncomment after first apply to enable remote state
  # backend "s3" {
  #   bucket         = "mern-app-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_eks_cluster_auth" "primary" {
  name = module.primary_eks.cluster_name
}

provider "kubernetes" {
  alias = "primary"
  host  = module.primary_eks.cluster_endpoint

  cluster_ca_certificate = base64decode(module.primary_eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.primary.token
}

provider "helm" {
  alias = "primary"
  kubernetes {
    host                   = module.primary_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.primary_eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.primary.token
  }
}

provider "kubernetes" {
  alias = "secondary"
  host  = var.secondary_region != "" ? module.secondary_eks[0].cluster_endpoint : "https://127.0.0.1"

  cluster_ca_certificate = var.secondary_region != "" ? base64decode(module.secondary_eks[0].cluster_ca_certificate) : ""
  token                  = var.secondary_region != "" ? data.aws_eks_cluster_auth.secondary[0].token : ""
}

provider "helm" {
  alias = "secondary"
  kubernetes {
    host                   = var.secondary_region != "" ? module.secondary_eks[0].cluster_endpoint : "https://127.0.0.1"
    cluster_ca_certificate = var.secondary_region != "" ? base64decode(module.secondary_eks[0].cluster_ca_certificate) : ""
    token                  = var.secondary_region != "" ? data.aws_eks_cluster_auth.secondary[0].token : ""
  }
}

data "aws_eks_cluster_auth" "secondary" {
  count    = var.secondary_region != "" ? 1 : 0
  provider = aws.secondary
  name     = module.secondary_eks[0].cluster_name
}

# Primary Region EKS Cluster
module "primary_eks" {
  source = "./modules/eks"

  cluster_name       = "${var.project_name}-primary"
  cluster_version    = var.kubernetes_version
  region             = var.primary_region
  vpc_cidr           = var.primary_vpc_cidr
  environment        = var.environment
  node_group_desired = var.primary_node_group_desired
  node_group_min     = var.primary_node_group_min
  node_group_max     = var.primary_node_group_max
  instance_types     = var.instance_types
  enable_monitoring  = var.enable_monitoring
  enable_autoscaling = var.enable_autoscaling
  enable_ingress     = var.enable_ingress

  tags = var.tags
}

# Secondary Region EKS Cluster (Optional - for HA/DR)
# To disable: set secondary_region = "" in terraform.tfvars
# Savings: $300/month when disabled
module "secondary_eks" {
  count  = var.secondary_region != "" ? 1 : 0
  source = "./modules/eks"
  providers = {
    aws = aws.secondary
  }

  cluster_name       = "${var.project_name}-secondary"
  cluster_version    = var.kubernetes_version
  region             = var.secondary_region
  vpc_cidr           = var.secondary_vpc_cidr
  environment        = var.environment
  node_group_desired = var.secondary_node_group_desired
  node_group_min     = var.secondary_node_group_min
  node_group_max     = var.secondary_node_group_max
  instance_types     = var.instance_types
  enable_monitoring  = var.enable_monitoring
  enable_autoscaling = var.enable_autoscaling
  enable_ingress     = var.enable_ingress

  tags = var.tags
}

# DocumentDB Database in Primary Region
module "primary_documentdb" {
  source = "./modules/documentdb"

  cluster_identifier           = "${var.project_name}-primary-docdb"
  vpc_id                       = module.primary_eks.vpc_id
  private_subnet_ids           = module.primary_eks.private_subnet_ids
  eks_security_group_ids        = [module.primary_eks.cluster_security_group_id]
  private_cidr_blocks          = [var.primary_vpc_cidr]
  environment                  = var.environment
  documentdb_username          = var.documentdb_username
  documentdb_database_name     = var.documentdb_database_name
  documentdb_engine_version                  = var.documentdb_engine_version
  documentdb_instance_class                  = var.documentdb_instance_class
  instance_count                             = var.documentdb_instance_count
  documentdb_backup_retention_period         = var.documentdb_backup_retention_period
  documentdb_preferred_backup_window         = var.documentdb_preferred_backup_window
  documentdb_preferred_maintenance_window    = var.documentdb_preferred_maintenance_window
  parameter_group_family                     = var.documentdb_parameter_group_family
  tags                                       = var.tags
}

module "secondary_documentdb" {
  count  = var.secondary_region != "" ? 1 : 0
  source = "./modules/documentdb"
  providers = {
    aws = aws.secondary
  }

  cluster_identifier           = "${var.project_name}-secondary-docdb"
  vpc_id                       = module.secondary_eks[0].vpc_id
  private_subnet_ids           = module.secondary_eks[0].private_subnet_ids
  eks_security_group_ids        = [module.secondary_eks[0].cluster_security_group_id]
  private_cidr_blocks          = [var.secondary_vpc_cidr]
  environment                  = var.environment
  documentdb_username                          = var.documentdb_username
  documentdb_database_name                     = var.documentdb_database_name
  documentdb_engine_version                    = var.documentdb_engine_version
  documentdb_instance_class                    = var.documentdb_instance_class
  instance_count                               = var.documentdb_instance_count
  documentdb_backup_retention_period           = var.documentdb_backup_retention_period
  documentdb_preferred_backup_window           = var.documentdb_preferred_backup_window
  documentdb_preferred_maintenance_window      = var.documentdb_preferred_maintenance_window
  parameter_group_family                       = var.documentdb_parameter_group_family
  tags                         = var.tags
}

# Route53 Health Checks and Failover (Optional - only if secondary region enabled)
module "global_routing" {
  count  = var.secondary_region != "" ? 1 : 0
  source = "./modules/route53"

  zone_name         = var.domain_name
  primary_region    = var.primary_region
  secondary_region  = var.secondary_region
  primary_alb_dns   = module.primary_eks.alb_dns_name
  secondary_alb_dns = module.secondary_eks[0].alb_dns_name
  environment       = var.environment

  tags = var.tags
}

# CloudWatch Monitoring across regions
module "monitoring" {
  source = "./modules/monitoring"

  cluster_names = concat(
    [module.primary_eks.cluster_name],
    var.secondary_region != "" ? [module.secondary_eks[0].cluster_name] : []
  )
  primary_region   = var.primary_region
  secondary_region = var.secondary_region
  environment      = var.environment
  enable_dashboard = var.enable_monitoring
  enable_alarms    = true
  alarm_email      = var.alarm_email

  tags = var.tags
}

# Kubernetes-native Prometheus + Grafana monitoring for each cluster
module "primary_kube_monitoring" {
  count  = var.enable_monitoring && var.enable_kubernetes_monitoring ? 1 : 0
  source = "./modules/kube_monitoring"
  providers = {
    kubernetes = kubernetes.primary
    helm       = helm.primary
  }

  cluster_name                  = module.primary_eks.cluster_name
  cluster_endpoint              = module.primary_eks.cluster_endpoint
  cluster_ca_certificate        = module.primary_eks.cluster_ca_certificate
  domain_name                   = var.domain_name
  environment                   = var.environment
  region                        = var.primary_region
  grafana_host                  = "grafana-${module.primary_eks.cluster_name}.${var.domain_name}"
  storage_class_name            = var.monitoring_storage_class_name
  grafana_persistence_size      = var.grafana_persistence_size
  prometheus_persistence_size   = var.prometheus_persistence_size
  alertmanager_persistence_size = var.alertmanager_persistence_size
  tags                          = var.tags
}

module "secondary_kube_monitoring" {
  count  = var.enable_monitoring && var.enable_kubernetes_monitoring && var.secondary_region != "" ? 1 : 0
  source = "./modules/kube_monitoring"
  providers = {
    kubernetes = kubernetes.secondary
    helm       = helm.secondary
  }

  cluster_name                  = module.secondary_eks[0].cluster_name
  cluster_endpoint              = module.secondary_eks[0].cluster_endpoint
  cluster_ca_certificate        = module.secondary_eks[0].cluster_ca_certificate
  domain_name                   = var.domain_name
  environment                   = var.environment
  region                        = var.secondary_region
  grafana_host                  = "grafana-${module.secondary_eks[0].cluster_name}.${var.domain_name}"
  storage_class_name            = var.monitoring_storage_class_name
  grafana_persistence_size      = var.grafana_persistence_size
  prometheus_persistence_size   = var.prometheus_persistence_size
  alertmanager_persistence_size = var.alertmanager_persistence_size
  tags                          = var.tags
}

# ArgoCD - Primary
module "primary_argocd" {
  source = "./modules/argocd"
  providers = {
    kubernetes = kubernetes.primary
    helm       = helm.primary
    aws        = aws
  }


  project_name          = var.project_name
  cluster_name          = module.primary_eks.cluster_name
  domain_name           = var.domain_name
  region                = var.primary_region
  admin_username        = "admin"
  replica_count         = 2
  load_balancer_name    = "${var.project_name}-${module.primary_eks.cluster_name}-argocd"
  argocd_hostname       = var.argocd_hostname != "" ? var.argocd_hostname : "argocd-${module.primary_eks.cluster_name}.${var.domain_name}"
  argocd_certificate_arn = var.argocd_certificate_arn

  # Ensure EKS cluster and ALB controller are created first
  depends_on = [module.primary_eks]
}

# ArgoCD - Secondary (optional)
module "secondary_argocd" {
  count  = var.secondary_region != "" ? 1 : 0
  source = "./modules/argocd"
  providers = {
    kubernetes = kubernetes.secondary
    helm       = helm.secondary
    aws        = aws.secondary
  }

  project_name   = var.project_name
  cluster_name   = module.secondary_eks[0].cluster_name
  domain_name    = var.domain_name
  region         = var.secondary_region
  admin_username = "admin"
  replica_count  = 2
  load_balancer_name = var.secondary_region != "" ? "${var.project_name}-${module.secondary_eks[0].cluster_name}-argocd" : ""
  argocd_hostname       = var.secondary_region != "" ? (var.argocd_hostname != "" ? var.argocd_hostname : "argocd-${module.secondary_eks[0].cluster_name}.${var.domain_name}") : ""
  argocd_certificate_arn = var.argocd_certificate_arn

  depends_on = [module.secondary_eks]
}
