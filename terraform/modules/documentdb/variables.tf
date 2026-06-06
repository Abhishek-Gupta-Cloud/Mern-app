variable "cluster_identifier" {
  description = "DocumentDB cluster identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the DocumentDB cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DocumentDB"
  type        = list(string)
}

variable "eks_security_group_ids" {
  description = "Security groups allowed to connect to DocumentDB"
  type        = list(string)
  default     = []
}

variable "private_cidr_blocks" {
  description = "Fallback private CIDR blocks allowed to connect to DocumentDB when security groups are not provided"
  type        = list(string)
  default     = []
}

variable "documentdb_username" {
  description = "DocumentDB admin user"
  type        = string
  default     = "admin"
}

variable "documentdb_database_name" {
  description = "DocumentDB database name"
  type        = string
  default     = "mernapp"
}

variable "documentdb_engine_version" {
  description = "Amazon DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "documentdb_instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.r5.large"
}

variable "instance_count" {
  description = "Number of DocumentDB instances to create in the cluster"
  type        = number
  default     = 2
}

variable "documentdb_backup_retention_period" {
  description = "Backup retention period for DocumentDB cluster"
  type        = number
  default     = 7
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

variable "parameter_group_family" {
  description = "DocumentDB cluster parameter group family"
  type        = string
  default     = "docdb5.0"
}

variable "environment" {
  description = "Environment name for DocumentDB"
  type        = string
}

variable "tags" {
  description = "Tags to apply to DocumentDB resources"
  type        = map(string)
}
