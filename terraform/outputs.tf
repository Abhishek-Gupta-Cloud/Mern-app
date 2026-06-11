output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.primary_eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.primary_eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of EKS cluster"
  value       = module.primary_eks.cluster_security_group_id
}

output "alb_dns_name" {
  description = "ALB DNS name for the cluster"
  value       = module.primary_eks.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN for the cluster"
  value       = module.primary_eks.alb_arn
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name for node group"
  value       = module.primary_eks.asg_name
}

# # DocumentDB Outputs
# output "documentdb_endpoint" {
#   description = "DocumentDB cluster endpoint"
#   value       = try(module.primary_documentdb.cluster_endpoint, "N/A - primary DocumentDB not created")
#   sensitive   = true
# }

# output "documentdb_reader_endpoint" {
#   description = "DocumentDB reader endpoint"
#   value       = try(module.primary_documentdb.reader_endpoint, "")
#   sensitive   = true
# }

# Configure kubectl output
output "configure_kubectl" {
  description = "Command to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.primary_eks.cluster_name}"
}

# # Monitoring
# output "cloudwatch_dashboard_url" {
#   description = "CloudWatch dashboard URL"
#   value       = try("https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}", "")
# }

# output "monitoring_summary" {
#   description = "Monitoring configuration summary"
#   value = {
#     aws_region                    = var.aws_region
#     monitoring_enabled            = var.enable_monitoring
#     kubernetes_monitoring_enabled = var.enable_kubernetes_monitoring
#     alarms_enabled                = true
#     alarm_email                   = var.alarm_email
#   }
# }

# output "grafana_url" {
#   description = "Grafana URL for the cluster"
#   value       = try(module.primary_kube_monitoring[0].grafana_url, "N/A - monitoring disabled")
# }

# output "prometheus_url" {
#   description = "Prometheus endpoint for the cluster"
#   value       = try(module.primary_kube_monitoring[0].prometheus_url, "N/A - monitoring disabled")
# }

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    cluster = {
      name     = module.primary_eks.cluster_name
      region   = var.aws_region
      version  = var.kubernetes_version
      endpoint = module.primary_eks.cluster_endpoint
    }
    # database = {
    #   engine  = "DocumentDB"
    #   name    = var.documentdb_database_name
    #   primary = try(module.primary_documentdb.cluster_endpoint, "N/A - primary DocumentDB not created")
    # }
    networking = {
      domain_name = var.domain_name
      alb         = module.primary_eks.alb_dns_name
    }
  }
}

# ArgoCD Outputs
output "argocd_url" {
  description = "ArgoCD UI URL for the cluster"
  value       = try("https://${module.primary_argocd.ingress_host}", "N/A - argocd not enabled")
}

output "argocd_admin_username" {
  description = "ArgoCD admin username for primary cluster"
  value       = try(module.primary_argocd.admin_username, "admin")
}

output "argocd_admin_password" {
  description = "ArgoCD admin password for primary cluster"
  value       = try(module.primary_argocd.admin_password, "")
  sensitive   = true
}
# output "grafana_url" {
# #   description = "Grafana dashboard URL."
# #   value       = module.monitoring.grafana_url
# # }

# # output "grafana_admin_username" {
# #   description = "Grafana admin username."
# #   value       = module.monitoring.grafana_admin_username
# # }

# # output "grafana_admin_password" {
# #   description = "Grafana admin password."
# #   value       = module.monitoring.grafana_admin_password
# #   sensitive   = true
# # }

# # output "monitoring_namespace" {
# #   description = "Kubernetes namespace for monitoring components."
# #   value       = module.monitoring.monitoring_namespace
# # }
