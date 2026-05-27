variable "cluster_names" {
  description = "List of EKS cluster names"
  type        = list(string)
}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email for alarm notifications"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}
