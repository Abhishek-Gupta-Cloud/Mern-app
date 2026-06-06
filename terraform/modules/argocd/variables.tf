variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "domain_name" {
  type = string
}

variable "region" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "argocd_hostname" {
  description = "Hostname to expose ArgoCD under (e.g., argocd.example.com). If empty, defaults to argocd-<cluster>.<domain_name>"
  type        = string
  default     = ""
}

variable "argocd_certificate_arn" {
  description = "ACM certificate ARN for ArgoCD HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_dex" {
  type    = bool
  default = false
}

variable "replica_count" {
  type    = number
  default = 2
}

variable "load_balancer_name" {
  type    = string
  default = ""
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD to watch"
  type        = string
  default     = "https://github.com/your-org/your-repo"
}

variable "git_repo_revision" {
  description = "Git revision (branch/tag) to track"
  type        = string
  default     = "main"
}

variable "service_paths" {
  description = "Map of application names to their k8s manifest paths in the repo"
  type        = map(string)
  default = {
    frontend     = "k8s/frontend"
    api-gateway  = "k8s/api-gateway"
    auth-service = "k8s/auth-service"
    task-service = "k8s/tasks-service"
  }
}
