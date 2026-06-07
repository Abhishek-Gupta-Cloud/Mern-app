variable "cluster_name" {
  description = "EKS cluster name used for release naming"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for EKS cluster"
  type        = string
}

variable "domain_name" {
  description = "Base DNS domain for Grafana ingress"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace that contains application services"
  type        = string
  default     = "mern-app"
}

variable "namespace" {
  description = "Namespace where monitoring is deployed"
  type        = string
  default     = "monitoring"
}

variable "grafana_host" {
  description = "Host name for Grafana ingress"
  type        = string
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_secret_name" {
  description = "Name of the Kubernetes secret that stores Grafana admin credentials"
  type        = string
  default     = "grafana-admin-credentials"
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "gp3"
}

variable "grafana_persistence_size" {
  description = "Grafana persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "prometheus_persistence_size" {
  description = "Prometheus persistent volume size"
  type        = string
  default     = "50Gi"
}

variable "alertmanager_persistence_size" {
  description = "Alertmanager persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "app_services" {
  description = "Application services exposed in the cluster to scrape via ServiceMonitor"
  type = list(object({
    name         = string
    namespace    = string
    port         = number
    metrics_path = string
  }))
  default = [
    {
      name         = "auth-service"
      namespace    = "mern-app"
      port         = 5001
      metrics_path = "/metrics"
    },
    {
      name         = "api-gateway"
      namespace    = "mern-app"
      port         = 4000
      metrics_path = "/metrics"
    },
    {
      name         = "tasks-service"
      namespace    = "mern-app"
      port         = 5002
      metrics_path = "/metrics"
    },
    {
      name         = "frontend"
      namespace    = "mern-app"
      port         = 80
      metrics_path = "/metrics"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to monitoring resources"
  type        = map(string)
  default     = {}
}
