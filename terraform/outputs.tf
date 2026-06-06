output "primary_cluster_name" {
  description = "Name of primary EKS cluster"
  value       = module.primary_eks.cluster_name
}

output "primary_cluster_endpoint" {
  description = "Endpoint for primary EKS cluster"
  value       = module.primary_eks.cluster_endpoint
  sensitive   = false
}

output "primary_cluster_security_group_id" {
  description = "Security group ID of primary EKS cluster"
  value       = module.primary_eks.cluster_security_group_id
}

output "primary_alb_dns_name" {
  description = "DNS name of primary ALB"
  value       = module.primary_eks.alb_dns_name
}

output "primary_autoscaling_group_name" {
  description = "Name of primary ASG"
  value       = module.primary_eks.asg_name
}

output "secondary_cluster_name" {
  description = "Name of secondary EKS cluster (if enabled)"
  value       = try(module.secondary_eks[0].cluster_name, "N/A - secondary region disabled")
}

output "secondary_cluster_endpoint" {
  description = "Endpoint for secondary EKS cluster (if enabled)"
  value       = try(module.secondary_eks[0].cluster_endpoint, "N/A - secondary region disabled")
  sensitive   = false
}

output "secondary_cluster_security_group_id" {
  description = "Security group ID of secondary EKS cluster (if enabled)"
  value       = try(module.secondary_eks[0].cluster_security_group_id, "N/A - secondary region disabled")
}

output "secondary_alb_dns_name" {
  description = "DNS name of secondary ALB (if enabled)"
  value       = try(module.secondary_eks[0].alb_dns_name, "N/A - secondary region disabled")
}

output "secondary_autoscaling_group_name" {
  description = "Name of secondary ASG (if enabled)"
  value       = try(module.secondary_eks[0].asg_name, "N/A - secondary region disabled")
}

# DocumentDB Outputs
output "primary_documentdb_endpoint" {
  description = "Primary DocumentDB cluster endpoint"
  value       = try(module.primary_documentdb.cluster_endpoint, "N/A - primary DocumentDB not created")
  sensitive   = true
}

output "primary_documentdb_cluster_id" {
  description = "Primary DocumentDB cluster identifier"
  value       = try(module.primary_documentdb.cluster_id, "N/A - primary DocumentDB not created")
}

output "primary_documentdb_reader_endpoint" {
  description = "Primary DocumentDB reader endpoint"
  value       = try(module.primary_documentdb.reader_endpoint, "N/A - primary DocumentDB not created")
  sensitive   = true
}

output "primary_documentdb_secret_arn" {
  description = "Secrets Manager ARN for primary DocumentDB credentials"
  value       = try(module.primary_documentdb.secret_arn, "N/A - primary DocumentDB not created")
  sensitive   = true
}

output "primary_documentdb_mongo_uri" {
  description = "Primary DocumentDB MONGO_URI connection string"
  value       = try(module.primary_documentdb.mongo_uri, "N/A - primary DocumentDB not created")
  sensitive   = true
}

output "secondary_documentdb_endpoint" {
  description = "Secondary DocumentDB cluster endpoint (if enabled)"
  value       = try(module.secondary_documentdb[0].cluster_endpoint, "N/A - secondary region disabled")
  sensitive   = true
}

output "secondary_documentdb_cluster_id" {
  description = "Secondary DocumentDB cluster identifier (if enabled)"
  value       = try(module.secondary_documentdb[0].cluster_id, "N/A - secondary region disabled")
}

output "secondary_documentdb_reader_endpoint" {
  description = "Secondary DocumentDB reader endpoint (if enabled)"
  value       = try(module.secondary_documentdb[0].reader_endpoint, "N/A - secondary region disabled")
  sensitive   = true
}

output "secondary_documentdb_mongo_uri" {
  description = "Secondary DocumentDB MONGO_URI connection string"
  value       = try(module.secondary_documentdb[0].mongo_uri, "N/A - secondary region disabled")
  sensitive   = true
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = try(module.global_routing[0].zone_id, "N/A - Route53 failover routing not enabled")
}

output "application_url" {
  description = "Application URL with failover"
  value       = "https://${var.domain_name}"
}

# Configure kubectl outputs
output "configure_kubectl_primary" {
  description = "Command to configure kubectl for primary cluster"
  value       = "aws eks update-kubeconfig --region ${var.primary_region} --name ${module.primary_eks.cluster_name}"
}

output "configure_kubectl_secondary" {
  description = "Command to configure kubectl for secondary cluster"
  value       = try("aws eks update-kubeconfig --region ${var.secondary_region} --name ${module.secondary_eks[0].cluster_name}", "N/A - secondary region disabled")
}

# Monitoring
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.primary_region}#dashboards:name=${var.project_name}"
}

output "monitoring_summary" {
  description = "Monitoring configuration summary"
  value = {
    primary_region                = var.primary_region
    secondary_region              = var.secondary_region
    monitoring_enabled            = var.enable_monitoring
    kubernetes_monitoring_enabled = var.enable_monitoring
    alarms_enabled                = true
    alarm_email                   = var.alarm_email
  }
}

output "primary_grafana_url" {
  description = "Grafana URL for the primary EKS cluster"
  value       = try(module.primary_kube_monitoring[0].grafana_url, "N/A - primary monitoring disabled")
}

output "secondary_grafana_url" {
  description = "Grafana URL for the secondary EKS cluster"
  value       = try(module.secondary_kube_monitoring[0].grafana_url, "N/A - secondary cluster disabled")
}

output "primary_prometheus_url" {
  description = "Prometheus endpoint for the primary EKS cluster"
  value       = try(module.primary_kube_monitoring[0].prometheus_url, "N/A - primary monitoring disabled")
}

output "secondary_prometheus_url" {
  description = "Prometheus endpoint for the secondary EKS cluster"
  value       = try(module.secondary_kube_monitoring[0].prometheus_url, "N/A - secondary cluster disabled")
}

# Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    primary_cluster = {
      name     = module.primary_eks.cluster_name
      region   = var.primary_region
      version  = var.kubernetes_version
      endpoint = module.primary_eks.cluster_endpoint
    }
    secondary_cluster = {
      name     = try(module.secondary_eks[0].cluster_name, "N/A - secondary region disabled")
      region   = var.secondary_region
      version  = var.kubernetes_version
      endpoint = try(module.secondary_eks[0].cluster_endpoint, "N/A - secondary region disabled")
    }
    database = {
      engine  = "DocumentDB"
      name    = var.documentdb_database_name
      primary = try(module.primary_documentdb.cluster_endpoint, "N/A - primary DocumentDB not created")
      replica = try(module.secondary_documentdb[0].cluster_endpoint, "N/A - secondary region disabled")
    }
    networking = {
      domain_name   = var.domain_name
      primary_alb   = module.primary_eks.alb_dns_name
      secondary_alb = try(module.secondary_eks[0].alb_dns_name, "N/A - secondary region disabled")
    }
  }
}

# ArgoCD Outputs
output "primary_argocd_url" {
  description = "ArgoCD UI URL for primary cluster"
  value       = try("https://${module.primary_argocd.ingress_host}", "N/A - argocd not enabled")
}

output "primary_argocd_admin_username" {
  description = "ArgoCD admin username for primary cluster"
  value       = try(module.primary_argocd.admin_username, "admin")
}

output "primary_argocd_admin_password" {
  description = "ArgoCD admin password for primary cluster"
  value       = try(module.primary_argocd.admin_password, "")
  sensitive    = true
}

output "secondary_argocd_url" {
  description = "ArgoCD UI URL for secondary cluster"
  value       = try("https://${module.secondary_argocd[0].ingress_host}", "N/A - secondary region disabled")
}

output "secondary_argocd_admin_username" {
  description = "ArgoCD admin username for secondary cluster"
  value       = try(module.secondary_argocd[0].admin_username, "admin")
}

output "secondary_argocd_admin_password" {
  description = "ArgoCD admin password for secondary cluster"
  value       = try(module.secondary_argocd[0].admin_password, "")
  sensitive    = true
}
