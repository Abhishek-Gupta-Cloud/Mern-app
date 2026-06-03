terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
      CreatedAt   = timestamp()
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
      CreatedAt   = timestamp()
    }
  }
}

# Primary Region EKS Cluster
module "primary_eks" {
  source = "./modules/eks"

  cluster_name           = "${var.project_name}-primary"
  cluster_version        = var.kubernetes_version
  region                 = var.primary_region
  vpc_cidr               = var.primary_vpc_cidr
  environment            = var.environment
  node_group_desired     = var.primary_node_group_desired
  node_group_min         = var.primary_node_group_min
  node_group_max         = var.primary_node_group_max
  instance_types         = var.instance_types
  enable_monitoring      = var.enable_monitoring
  enable_autoscaling     = var.enable_autoscaling
  enable_ingress         = var.enable_ingress

  tags = var.tags
}

# Secondary Region EKS Cluster (Optional - for HA/DR)
# To disable: set secondary_region = "" in terraform.tfvars
# Savings: $300/month when disabled
module "secondary_eks" {
  count = var.secondary_region != "" ? 1 : 0
  source = "./modules/eks"
  providers = {
    aws = aws.secondary
  }

  cluster_name           = "${var.project_name}-secondary"
  cluster_version        = var.kubernetes_version
  region                 = var.secondary_region
  vpc_cidr               = var.secondary_vpc_cidr
  environment            = var.environment
  node_group_desired     = var.secondary_node_group_desired
  node_group_min         = var.secondary_node_group_min
  node_group_max         = var.secondary_node_group_max
  instance_types         = var.instance_types
  enable_monitoring      = var.enable_monitoring
  enable_autoscaling     = var.enable_autoscaling
  enable_ingress         = var.enable_ingress

  tags = var.tags
}

# RDS Database in Primary Region
module "primary_rds" {
  count = var.db_engine == "mongodb" ? 0 : 1
  source = "./modules/rds"

  db_instance_identifier = "${var.project_name}-primary-db"
  db_name                = var.db_name
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  multi_az               = var.db_multi_az
  vpc_id                 = module.primary_eks.vpc_id
  subnet_ids             = module.primary_eks.private_subnet_ids
  environment            = var.environment

  tags = var.tags
}

# RDS Read Replica in Secondary Region (Optional - for HA/DR)
# To disable: set secondary_region = "" in terraform.tfvars
# Savings: $100/month when disabled
module "secondary_rds" {
  count = var.secondary_region != "" && var.db_engine != "mongodb" ? 1 : 0
  source = "./modules/rds_replica"

  source_db_identifier   = module.primary_rds[0].db_instance_id
  replica_identifier     = "${var.project_name}-secondary-db"
  replica_region         = var.secondary_region
  instance_class         = var.db_instance_class
  environment            = var.environment

  tags = var.tags

  depends_on = [module.primary_rds]
}

# Route53 Health Checks and Failover (Optional - only if secondary region enabled)
module "global_routing" {
  count = var.secondary_region != "" ? 1 : 0
  source = "./modules/route53"

  zone_name              = var.domain_name
  primary_region         = var.primary_region
  secondary_region       = var.secondary_region
  primary_alb_dns        = module.primary_eks.alb_dns_name
  secondary_alb_dns      = module.secondary_eks[0].alb_dns_name
  environment            = var.environment

  tags = var.tags
}

# CloudWatch Monitoring across regions
module "monitoring" {
  source = "./modules/monitoring"

  cluster_names          = [module.primary_eks.cluster_name, module.secondary_eks.cluster_name]
  primary_region         = var.primary_region
  secondary_region       = var.secondary_region
  environment            = var.environment
  enable_dashboard       = var.enable_monitoring
  enable_alarms          = true
  alarm_email            = var.alarm_email

  tags = var.tags
}
