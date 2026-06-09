terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "random_password" "argocd_admin" {
  length           = 24
  special          = true
  override_special = "@#$%&*()-_=+[]{}<>?"
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      app         = "argocd"
      environment = var.project_name
    }
  }
}

resource "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      app = "argocd"
    }
  }

  data = {
    username = base64encode(var.admin_username)
    password = base64encode(random_password.argocd_admin.result)
  }

  type = "Opaque"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [yamlencode({
    server = {
      service   = { type = "ClusterIP" }
    }
    controller = {
      replicas = var.replica_count
    }
    repoServer = { replicas = var.replica_count }
    redis      = { enabled = true }
    configs = {
      secret = {
        existingSecret = kubernetes_secret.argocd_admin.metadata[0].name
      }
    }
    dex = {
      enabled = var.enable_dex
    }
    metrics   = { enabled = true }
    serverTLS = { enabled = true }
  })]

  depends_on = [kubernetes_namespace.argocd, kubernetes_secret.argocd_admin]
}

# Create an Ingress resource for ALB (AWS Load Balancer Controller)
resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    annotations = merge(
      {
        "kubernetes.io/ingress.class"            = "alb"
        "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"  = "ip"
        "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
        # Redirect HTTP -> HTTPS
        "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      },
      var.load_balancer_name != "" ? { "alb.ingress.kubernetes.io/load-balancer-name" = var.load_balancer_name } : {},
      var.argocd_certificate_arn != "" ? { "alb.ingress.kubernetes.io/certificate-arn" = var.argocd_certificate_arn } : {}
    )
  }

  spec {
    rule {
      host = var.argocd_hostname != "" ? var.argocd_hostname : "argocd-${var.cluster_name}.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}

# # Optionally lookup the ALB created by AWS LB Controller if a name was supplied
# data "aws_lb" "argocd_alb" {
#   count    = var.load_balancer_name != "" ? 1 : 0
#   provider = aws
#   name     = var.load_balancer_name
# }

output "argocd_admin_password" {
  value     = random_password.argocd_admin.result
  sensitive = true
}

output "argocd_admin_username" {
  value = var.admin_username
}

output "argocd_ingress_host" {
  value = "argocd-${var.cluster_name}.${var.domain_name}"
}

# output "argocd_alb_dns" {
#   value = var.load_balancer_name != "" ? data.aws_lb.argocd_alb[0].dns_name : ""
# }
