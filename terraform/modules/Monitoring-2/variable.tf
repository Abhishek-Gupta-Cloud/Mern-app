# =============================================================================
# modules/monitoring/variables.tf
# =============================================================================
# All configurable inputs for the monitoring module.
# Sensible defaults are provided where possible so the module can be used
# with minimal required inputs in non-production environments.
# =============================================================================

# -----------------------------------------------------------------------------
# General / Environment
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, production). Used for resource tagging and ALB tags."
  type        = string
  default     = "production"
}

variable "namespace" {
  description = "Kubernetes namespace where all monitoring components will be deployed."
  type        = string
  default     = "monitoring"
}

# -----------------------------------------------------------------------------
# Helm Chart
# -----------------------------------------------------------------------------

variable "chart_version" {
  description = <<-EOT
    Version of the kube-prometheus-stack Helm chart to install.
    Pin this to a specific version for reproducible deployments.
    Latest releases: https://github.com/prometheus-community/helm-charts/releases
  EOT
  type        = string
  default     = "58.2.2" # Latest stable as of mid-2024; update as needed
}

# -----------------------------------------------------------------------------
# Grafana
# -----------------------------------------------------------------------------

variable "grafana_admin_user" {
  description = "Grafana admin username. Exposed as an output so it can be referenced by other modules or the root configuration."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = <<-EOT
    Grafana admin password. Marked sensitive so it is redacted in plan/apply output.
    In production, source this from AWS Secrets Manager or HashiCorp Vault rather
    than passing it as a plain-text variable.
  EOT
  type      = string
  sensitive = true
}

variable "grafana_hostname" {
  description = <<-EOT
    Optional fully-qualified domain name for Grafana (e.g. grafana.example.com).
    When set, the ALB Ingress rule is restricted to this hostname and the output
    Grafana URL will use it. Leave empty to accept all hostnames (useful during
    initial setup before DNS is configured).
  EOT
  type    = string
  default = ""
}

variable "grafana_storage_size" {
  description = "Size of the PersistentVolumeClaim for Grafana's data directory (dashboards, plugins, SQLite DB)."
  type        = string
  default     = "10Gi"
}

# -----------------------------------------------------------------------------
# Prometheus
# -----------------------------------------------------------------------------

variable "prometheus_retention" {
  description = "How long Prometheus retains time-series data. Increase for longer dashboards; balance with storage cost."
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Size of the PersistentVolumeClaim for Prometheus TSDB storage."
  type        = string
  default     = "50Gi"
}

# -----------------------------------------------------------------------------
# Alertmanager
# -----------------------------------------------------------------------------

variable "alertmanager_storage_size" {
  description = "Size of the PersistentVolumeClaim for Alertmanager (stores silence and notification state)."
  type        = string
  default     = "5Gi"
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

variable "storage_class_name" {
  description = <<-EOT
    Kubernetes StorageClass used for all PersistentVolumeClaims (Prometheus, Grafana, Alertmanager).
    On EKS, "gp2" (default) or "gp3" (recommended for performance) are common choices.
    Ensure the StorageClass exists in your cluster before applying.
  EOT
  type    = string
  default = "gp2"
}

# -----------------------------------------------------------------------------
# AWS Load Balancer / Ingress
# -----------------------------------------------------------------------------

variable "acm_certificate_arn" {
  description = <<-EOT
    ARN of the AWS Certificate Manager (ACM) certificate used to terminate HTTPS
    on the Grafana ALB listener. The certificate must be in the same AWS region
    as the EKS cluster and must cover the grafana_hostname (or be a wildcard cert).
    Example: arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  EOT
  type = string
default     = ""
 }

variable "alb_scheme" {
  description = <<-EOT
    ALB scheme. Use "internet-facing" to expose Grafana publicly (requires public subnets),
    or "internal" to restrict access to within the VPC (e.g. via VPN or bastion host).
  EOT
  type    = string
  default = "internet-facing"

  validation {
    condition     = contains(["internet-facing", "internal"], var.alb_scheme)
    error_message = "alb_scheme must be either 'internet-facing' or 'internal'."
  }
}

variable "alb_group_name" {
  description = <<-EOT
    ALB IngressGroup name. Ingress resources sharing the same group name will be
    consolidated onto a single ALB, reducing cost. Set to a unique value if you
    prefer a dedicated ALB for monitoring.
  EOT
  type    = string
  default = "monitoring"
}
