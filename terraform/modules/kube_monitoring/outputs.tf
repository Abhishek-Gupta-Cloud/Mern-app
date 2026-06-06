output "grafana_url" {
  description = "External Grafana URL for this cluster"
  value       = "https://${var.grafana_host}"
}

output "prometheus_url" {
  description = "Internal Prometheus endpoint for this cluster"
  value       = "http://prometheus-operated.${var.namespace}.svc.cluster.local:9090"
}

output "grafana_admin_username" {
  description = "Grafana admin username"
  value       = var.grafana_admin_user
}

output "grafana_admin_secret_name" {
  description = "Kubernetes secret holding Grafana credentials"
  value       = var.grafana_admin_secret_name
}

output "monitoring_namespace" {
  description = "Namespace used for monitoring components"
  value       = var.namespace
}
