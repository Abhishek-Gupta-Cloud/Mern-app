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

# RDS Outputs
output "primary_db_endpoint" {
  description = "Primary database endpoint"
  value       = module.primary_rds.db_endpoint
  sensitive   = true
}

output "primary_db_instance_id" {
  description = "Primary database instance ID"
  value       = module.primary_rds.db_instance_id
}

output "secondary_db_endpoint" {
  description = "Secondary database endpoint (read replica - if enabled)"
  value       = try(module.secondary_rds[0].db_endpoint, "N/A - secondary region disabled")
  sensitive   = true
}

output "secondary_db_instance_id" {
  description = "Secondary database instance ID (if enabled)"
  value       = try(module.secondary_rds[0].db_instance_id, "N/A - secondary region disabled")
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.global_routing.zone_id
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
  value       = "aws eks update-kubeconfig --region ${var.secondary_region} --name ${module.secondary_eks.cluster_name}"
}

# Monitoring
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.primary_region}#dashboards:name=${var.project_name}"
}

output "monitoring_summary" {
  description = "Monitoring configuration summary"
  value = {
    primary_region   = var.primary_region
    secondary_region = var.secondary_region
    monitoring_enabled = var.enable_monitoring
    alarms_enabled    = true
    alarm_email      = var.alarm_email
  }
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
      name     = module.secondary_eks.cluster_name
      region   = var.secondary_region
      version  = var.kubernetes_version
      endpoint = module.secondary_eks.cluster_endpoint
    }
    database = {
      engine  = var.db_engine
      name    = var.db_name
      primary = module.primary_rds.db_endpoint
      replica = module.secondary_rds.db_endpoint
    }
    networking = {
      domain_name = var.domain_name
      primary_alb = module.primary_eks.alb_dns_name
      secondary_alb = module.secondary_eks.alb_dns_name
    }
  }
}
