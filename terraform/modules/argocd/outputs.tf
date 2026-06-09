output "admin_username" {
  value = var.admin_username
}

output "admin_password" {
  value     = random_password.argocd_admin.result
  sensitive = true
}

output "ingress_host" {
  value = var.argocd_hostname != "" ? var.argocd_hostname : "argocd-${var.cluster_name}.${var.domain_name}"
}

# output "alb_dns" {
#   value = var.load_balancer_name != "" ? data.aws_lb.argocd_alb[0].dns_name : ""
# }
