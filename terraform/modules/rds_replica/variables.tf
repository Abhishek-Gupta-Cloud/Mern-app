variable "source_db_identifier" {
  description = "Source database identifier"
  type        = string
}

variable "replica_identifier" {
  description = "Read replica identifier"
  type        = string
}

variable "replica_region" {
  description = "Region for read replica"
  type        = string
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}
