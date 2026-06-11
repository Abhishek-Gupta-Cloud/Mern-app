# =============================================================================
# modules/monitoring/outputs.tf
# =============================================================================
# Outputs expose key values so the root Terraform configuration (or other
# modules) can reference them without digging through the state file.
# =============================================================================

# -----------------------------------------------------------------------------
# Grafana URL
# -----------------------------------------------------------------------------
# Returns the Grafana URL based on whether a custom hostname was provided:
#   - Custom hostname → https://<grafana_hostname>
#   - No hostname     → informational placeholder (actual URL is assigned by
#                       AWS after the ALB is provisioned; retrieve it with
#                       kubectl get ingress -n monitoring)
# -----------------------------------------------------------------------------
output "grafana_url" {
  description = <<-EOT
    URL for accessing the Grafana dashboard.
    If grafana_hostname was set, this is the HTTPS URL for that domain.
    If no hostname was set, retrieve the ALB DNS name from the Ingress:
      kubectl get ingress grafana-ingress -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  EOT
  value = var.grafana_hostname != "" ? "https://${var.grafana_hostname}" : "https://<alb-dns-name> (run: kubectl get ingress grafana-ingress -n monitoring)"
}

# -----------------------------------------------------------------------------
# Grafana Admin Username
# -----------------------------------------------------------------------------
# Echoed back as an output so the root config can surface it without the caller
# needing to remember which variable name was used inside the module.
# -----------------------------------------------------------------------------
output "grafana_admin_username" {
  description = "Grafana admin username configured for this deployment."
  value       = var.grafana_admin_user
}

# -----------------------------------------------------------------------------
# Grafana Admin Password
# -----------------------------------------------------------------------------
# Marked sensitive so Terraform redacts it in terminal output. The value is
# still accessible programmatically (e.g. via `terraform output -json`).
# -----------------------------------------------------------------------------
output "grafana_admin_password" {
  description = "Grafana admin password (sensitive). Access via: terraform output -raw grafana_admin_password"
  value       = var.grafana_admin_password
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Monitoring Namespace
# -----------------------------------------------------------------------------
output "monitoring_namespace" {
  description = "Kubernetes namespace where all monitoring components are deployed."
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

# -----------------------------------------------------------------------------
# Helm Release Metadata
# -----------------------------------------------------------------------------
output "helm_release_status" {
  description = "Status of the kube-prometheus-stack Helm release (e.g. 'deployed')."
  value       = helm_release.kube_prometheus_stack.status
}

output "helm_release_version" {
  description = "Chart version of the deployed kube-prometheus-stack release."
  value       = helm_release.kube_prometheus_stack.version
}

# -----------------------------------------------------------------------------
# Ingress Name (useful for scripting / CI pipelines that need to poll ALB DNS)
# -----------------------------------------------------------------------------
output "grafana_ingress_name" {
  description = "Name of the Kubernetes Ingress resource created for Grafana."
  value       = kubernetes_ingress_v1.grafana.metadata[0].name
}
