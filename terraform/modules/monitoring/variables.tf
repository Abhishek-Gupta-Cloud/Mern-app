variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch resources"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "autoscaling_group_names" {
  description = "List of Auto Scaling Group names for EKS worker nodes"
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable_node_alarms || length(var.autoscaling_group_names) > 0
    error_message = "If node alarms are enabled, at least one autoscaling_group_names entry is required."
  }
}

variable "enable_dashboard" {
  description = "Enable the CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_log_monitoring" {
  description = "Enable CloudWatch log group and metric filter"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
}

variable "tags" {
  description = "Tags to apply to monitoring resources"
  type        = map(string)
  default     = {}
}

variable "dashboard_name" {
  description = "CloudWatch dashboard name"
  type        = string
  default     = "eks-cluster-dashboard"
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold percent for node CPU alarms"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold percent for node memory alarms"
  type        = number
  default     = 80
}

variable "alarm_5xx_threshold" {
  description = "HTTP 5XX count threshold for ALB alarms"
  type        = number
  default     = 10
}

variable "alarm_latency_threshold" {
  description = "Target response time threshold in seconds for ALB latency alarms"
  type        = number
  default     = 5
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for alarms"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Alarm evaluation period in seconds"
  type        = number
  default     = 300
}

variable "log_retention_in_days" {
  description = "Retention period for CloudWatch log group"
  type        = number
  default     = 7
}

variable "enable_memory_metrics" {
  description = "Whether node memory metrics are available via CloudWatch Agent"
  type        = bool
  default     = true
}

variable "enable_eks_health_metrics" {
  description = "Enable EKS cluster health metrics on the dashboard and alarms"
  type        = bool
  default     = true
}

variable "enable_node_failure_alarm" {
  description = "Enable EKS node failure alarm"
  type        = bool
  default     = true
}

variable "enable_alb_alarms" {
  description = "Enable ALB alarms"
  type        = bool
  default     = true
}

variable "enable_node_alarms" {
  description = "Enable EC2 node alarms"
  type        = bool
  default     = true
}

variable "enable_composite_alarm" {
  description = "Enable composite system health alarm"
  type        = bool
  default     = true
}

variable "alarm_actions_enabled" {
  description = "Enable or disable alarm actions"
  type        = bool
  default     = true
}

variable "dashboard_widget_period" {
  description = "Dashboard widget period in seconds"
  type        = number
  default     = 300
}
