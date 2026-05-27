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

# AWS Regions
variable "primary_region" {
  description = "Primary AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.primary_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1, eu-west-1)."
  }
}

variable "secondary_region" {
  description = "Secondary AWS region for HA/DR (leave empty to disable)"
  type        = string
  default     = ""  # CHANGE to "us-west-2" for multi-region HA

  validation {
    condition     = var.secondary_region == "" || can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.secondary_region))
    error_message = "Must be empty (disabled) or a valid AWS region (e.g., us-east-1, eu-west-1)."
  }
}

# VPC Configuration
variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary VPC (only used if secondary_region is enabled)"
  type        = string
  default     = "10.1.0.0/16"
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
  default     = ["t3.medium", "t3.large"]
}

# Primary Region Node Group
variable "primary_node_group_desired" {
  description = "Desired number of nodes in primary region"
  type        = number
  default     = 3

  validation {
    condition     = var.primary_node_group_desired >= 1 && var.primary_node_group_desired <= 100
    error_message = "Desired nodes must be between 1 and 100."
  }
}

variable "primary_node_group_min" {
  description = "Minimum number of nodes in primary region"
  type        = number
  default     = 2
}

variable "primary_node_group_max" {
  description = "Maximum number of nodes in primary region"
  type        = number
  default     = 10
}

# Secondary Region Node Group (only used if secondary_region is enabled - adds $300/month)
variable "secondary_node_group_desired" {
  description = "Desired number of nodes in secondary region (for HA/DR)"
  type        = number
  default     = 2

  validation {
    condition     = var.secondary_node_group_desired >= 1 && var.secondary_node_group_desired <= 100
    error_message = "Desired nodes must be between 1 and 100."
  }
}

variable "secondary_node_group_min" {
  description = "Minimum number of nodes in secondary region"
  type        = number
  default     = 1
}

variable "secondary_node_group_max" {
  description = "Maximum number of nodes in secondary region"
  type        = number
  default     = 5
}

# RDS Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "merndb"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mongodb"

  validation {
    condition     = contains(["mongodb", "mysql", "postgres"], var.db_engine)
    error_message = "Must be mongodb, mysql, or postgres."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "7.0"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
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

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Owner       = "DevOps"
    CostCenter  = "Engineering"
    Compliance  = "SOC2"
  }
}
