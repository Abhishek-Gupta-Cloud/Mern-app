resource "kubernetes_manifest" "argocd_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "mern-app"
      namespace = var.namespace
    }
    spec = {
      description = "Project for MERN microservices"
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      sourceRepos = [var.git_repo_url]
    }
  }

  depends_on = [helm_release.argocd]
}

locals {
  apps = {
    frontend     = var.service_paths["frontend"]
    api-gateway  = var.service_paths["api-gateway"]
    auth-service = var.service_paths["auth-service"]
    task-service = var.service_paths["task-service"]
  }
}

resource "kubernetes_manifest" "argocd_app" {
  for_each = local.apps

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.key
      namespace = var.namespace
      labels = {
        app = "argocd"
      }
    }
    spec = {
      project = "mern-app"
      source = {
        repoURL        = var.git_repo_url
        path           = each.value
        targetRevision = var.git_repo_revision
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [kubernetes_manifest.argocd_project, helm_release.argocd]
}

output "applications" {
  value = [for k, v in kubernetes_manifest.argocd_app : {
    name   = k
    status = try(v.manifest.status, {})
  }]
}
