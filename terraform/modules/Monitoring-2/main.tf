# =============================================================================
# modules/monitoring/main.tf
# =============================================================================
# This module deploys a full observability stack on AWS EKS using Helm.
# It installs the kube-prometheus-stack (Prometheus + Grafana + Alertmanager +
# kube-state-metrics + node-exporter) and exposes Grafana via an AWS ALB
# Ingress backed by the AWS Load Balancer Controller.
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Namespace: monitoring
# -----------------------------------------------------------------------------
# Creates a dedicated namespace to isolate all monitoring components from
# application workloads. Labels are added for better observability and
# potential NetworkPolicy targeting.
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = var.environment
      managed-by  = "terraform"
    }

    annotations = {
      description = "Namespace for Prometheus, Grafana, and Alertmanager monitoring stack"
    }
  }
}

# -----------------------------------------------------------------------------
# Helm Release: kube-prometheus-stack
# -----------------------------------------------------------------------------
# Installs the kube-prometheus-stack chart which bundles:
#   - Prometheus Operator (manages Prometheus/Alertmanager via CRDs)
#   - Prometheus          (metrics collection & storage)
#   - Alertmanager        (alert routing & notification)
#   - Grafana             (metrics visualisation dashboards)
#   - kube-state-metrics  (exposes Kubernetes object-level metrics)
#   - node-exporter       (exposes host-level hardware/OS metrics)
#
# `wait = true` blocks Terraform until all pods are Running/Ready, ensuring
# downstream resources (e.g. Ingress) are only created once Grafana is healthy.
# `timeout = 900` gives the stack up to 15 minutes to become ready, which is
# enough even on cold node-group scale-outs.
# -----------------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Block until all workloads are healthy before Terraform moves on
  wait    = true
  timeout = 900

  # ── Prometheus ──────────────────────────────────────────────────────────────
  # Enable the Prometheus instance and configure its retention period and
  # storage. A PVC is created so metrics survive pod restarts.
  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Allow Prometheus to scrape ServiceMonitors from ALL namespaces, not just
  # its own. This is required so application-level metrics (from the MERN
  # microservices namespace) are collected automatically.
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"
    value = "false"
  }

  # ── Grafana ─────────────────────────────────────────────────────────────────
  # Enable Grafana and inject the admin credentials supplied via variables.
  # Default dashboards for Kubernetes/Node are pre-provisioned automatically
  # by the chart's sidecar.
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Persist Grafana state (dashboards saved in the UI, datasource tweaks)
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = var.storage_class_name
  }

  # Disable the chart's built-in Grafana Ingress — we manage our own below
  # using an ALB Ingress resource with HTTPS and ACM certificate support.
  set {
    name  = "grafana.ingress.enabled"
    value = "false"
  }

  # ── Alertmanager ────────────────────────────────────────────────────────────
  # Alertmanager receives firing alerts from Prometheus and routes them to
  # receivers (e.g. Slack, PagerDuty). Persistence ensures alert state and
  # silences survive pod restarts.
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
  }

  # ── kube-state-metrics ───────────────────────────────────────────────────────
  # Exposes metrics about the state of Kubernetes objects (Deployments,
  # Pods, Nodes, PVCs, etc.) sourced from the Kubernetes API server.
  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  # ── node-exporter ────────────────────────────────────────────────────────────
  # Runs as a DaemonSet on every node to expose low-level OS/hardware metrics
  # (CPU, memory, disk I/O, network) to Prometheus.
  set {
    name  = "prometheus-node-exporter.enabled"
    value = "true"
  }

  # ── EKS-specific scrape targets ─────────────────────────────────────────────
  # EKS does not expose the scheduler or controller-manager endpoints by default.
  # Disable those scrape jobs to avoid constant "target not found" errors in
  # the Prometheus UI and noisy alert noise.
  set {
    name  = "kubeScheduler.enabled"
    value = "false"
  }

  set {
    name  = "kubeControllerManager.enabled"
    value = "false"
  }

  set {
    name  = "kubeEtcd.enabled"
    value = "false"
  }

  # kubelet and kube-proxy metrics ARE available on EKS — keep them enabled.
  set {
    name  = "kubelet.enabled"
    value = "true"
  }

  set {
    name  = "kubeProxy.enabled"
    value = "true"
  }

  # Enable default Prometheus alerting rules (node down, pod crash-loop, etc.)
  set {
    name  = "defaultRules.create"
    value = "true"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# -----------------------------------------------------------------------------
# Kubernetes Ingress: Grafana ALB
# -----------------------------------------------------------------------------
# Creates an ALB-backed Ingress that terminates HTTPS using the supplied ACM
# certificate. Traffic is then forwarded to the Grafana ClusterIP service on
# port 80 (the chart's default).
#
# Annotations drive the AWS Load Balancer Controller behaviour:
#   - scheme: internet-facing  → public ALB (use "internal" for private)
#   - target-type: ip          → required for EKS pod networking (no NodePort)
#   - certificate-arn          → ACM certificate for HTTPS termination
#   - ssl-redirect             → auto-redirect HTTP (80) → HTTPS (443)
# -----------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "grafana" {
  # Wait until the Helm release is fully deployed before creating the Ingress,
  # so the Grafana Service already exists when the ALB controller reconciles.
  depends_on = [helm_release.kube_prometheus_stack]

  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name

    annotations = {
      # Tell Kubernetes which Ingress controller should handle this resource
      "kubernetes.io/ingress.class" = "alb"

      # Create a public-facing (internet-facing) ALB
      "alb.ingress.kubernetes.io/scheme" = var.alb_scheme

      # "ip" target type routes directly to pod IPs — required for Fargate and
      # recommended for EKS managed node groups with VPC CNI
      "alb.ingress.kubernetes.io/target-type" = "ip"

    #   # Attach the ACM TLS certificate to the ALB listener on port 443
    #   "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn

    #   # Listen on both 80 and 443; HTTP → HTTPS redirect is handled below
    #   "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])

    #   # Automatically redirect all HTTP requests to HTTPS (301)
    #   "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }])

      # Health-check path used by the ALB target group
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"

      # Tag the ALB resources for cost allocation and identification
      "alb.ingress.kubernetes.io/tags" = "Environment=${var.environment},ManagedBy=terraform,Component=grafana"

      # Group name allows multiple Ingresses to share a single ALB (reduces cost)
      "alb.ingress.kubernetes.io/group.name" = var.alb_group_name
    }
  }

  spec {
    # Default backend catches all paths not matched by explicit rules below
    default_backend {
      service {
        # This is the Service name created by the kube-prometheus-stack chart
        name = "kube-prometheus-stack-grafana"
        port {
          number = 80
        }
      }
    }

    rule {
      # If a custom hostname is provided, restrict the rule to that host.
      # Leave var.grafana_hostname empty to accept all hostnames.
      host = var.grafana_hostname != "" ? var.grafana_hostname : null

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
