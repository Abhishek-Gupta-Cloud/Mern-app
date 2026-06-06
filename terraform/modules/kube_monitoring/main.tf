terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

resource "random_password" "grafana_admin" {
  length           = 24
  special          = true
  override_special = "@#$%&*()-_=+[]{}<>?"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      app         = "kube-monitoring"
      environment = var.environment
    }
  }
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = var.grafana_admin_secret_name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  data = {
    admin-user     = base64encode(var.grafana_admin_user)
    admin-password = base64encode(random_password.grafana_admin.result)
  }

  type = "Opaque"
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack-${var.cluster_name}"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  values = [yamlencode({
    grafana = {
      enabled = true
      admin = {
        existingSecret    = kubernetes_secret.grafana_admin.metadata[0].name
        existingSecretKey = "admin-password"
      }
      ingress = {
        enabled = true
        hosts = [
          {
            host = var.grafana_host
            paths = ["/"]
          }
        ]
        annotations = {
          "kubernetes.io/ingress.class"       = "alb"
          "alb.ingress.kubernetes.io/scheme"  = "internet-facing"
          "alb.ingress.kubernetes.io/target-type" = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }])
          "alb.ingress.kubernetes.io/healthcheck-path" = "/"
          "alb.ingress.kubernetes.io/healthcheck-port" = "80"
        }
      }
      service = {
        type = "ClusterIP"
      }
      persistence = {
        enabled          = true
        storageClassName = var.storage_class_name
        size             = var.grafana_persistence_size
      }
      sidecar = {
        dashboards = {
          enabled = true
          label   = "grafana_dashboard"
          folder  = "/"
        }
      }
    }
    prometheus = {
      enabled = true
      prometheusSpec = {
        retention               = "15d"
        serviceMonitorSelectorNilUsesHelmValues = false
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.prometheus_persistence_size
                }
              }
              storageClassName = var.storage_class_name
            }
          }
        }
      }
      service = {
        type = "ClusterIP"
      }
    }
    alertmanager = {
      enabled = true
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.alertmanager_persistence_size
                }
              }
              storageClassName = var.storage_class_name
            }
          }
        }
      }
      config = {
        global = {
          resolve_timeout = "5m"
        }
        route = {
          receiver = "default"
        }
        receivers = [
          {
            name = "default"
          }
        ]
      }
    }
    kubeStateMetrics = {
      enabled = true
    }
    nodeExporter = {
      enabled = true
    }
    prometheusOperator = {
      admissionWebhooks = {
        enabled = false
      }
    }
    additionalServiceMonitors = [
      for svc in var.app_services : {
        name = "${svc.name}-servicemonitor"
        namespaceSelector = {
          matchNames = [svc.namespace]
        }
        selector = {
          matchLabels = {
            app = svc.name
          }
        }
        endpoints = [
          {
            port     = tostring(svc.port)
            interval = "30s"
            path     = svc.metrics_path
            scheme   = "http"
          }
        ]
      }
    ]
    additionalPrometheusRules = [
      {
        name = "custom-k8s-alerts"
        groups = [
          {
            name = "kubernetes.rules"
            rules = [
              {
                alert = "NodeNotReady"
                expr  = "kube_node_status_condition{condition=\"Ready\",status=\"false\"} == 1"
                for   = "5m"
                labels = {
                  severity = "critical"
                }
                annotations = {
                  summary     = "Node not ready"
                  description = "Node {{ $labels.node }} has not been ready for more than 5 minutes."
                }
              },
              {
                alert = "PodCrashLoopBackOff"
                expr  = "sum by (namespace, pod) (kube_pod_container_status_waiting_reason{reason=\"CrashLoopBackOff\"}) > 0"
                for   = "5m"
                labels = {
                  severity = "critical"
                }
                annotations = {
                  summary     = "Pod CrashLoopBackOff"
                  description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} is in CrashLoopBackOff."
                }
              },
              {
                alert = "HighCPUUsage"
                expr  = "sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!\"\",image!\"\"}[5m])) / sum by (namespace, pod) (kube_pod_container_resource_limits_cpu_cores{container!\"\",pod!\"\"}) > 0.8"
                for   = "10m"
                labels = {
                  severity = "warning"
                }
                annotations = {
                  summary     = "High CPU usage"
                  description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has CPU usage over 80%."
                }
              },
              {
                alert = "HighMemoryUsage"
                expr  = "sum by (namespace, pod) (container_memory_working_set_bytes{container!\"\",image!\"\"}) / sum by (namespace, pod) (kube_pod_container_resource_limits_memory_bytes{container!\"\",pod!\"\"}) > 0.8"
                for   = "10m"
                labels = {
                  severity = "warning"
                }
                annotations = {
                  summary     = "High memory usage"
                  description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} memory usage is above 80%."
                }
              },
              {
                alert = "ServiceDown"
                expr  = "kube_endpoint_address_available == 0"
                for   = "5m"
                labels = {
                  severity = "critical"
                }
                annotations = {
                  summary     = "Service has no available endpoints"
                  description = "Service {{ $labels.service }} in namespace {{ $labels.namespace }} has no ready endpoints."
                }
              },
              {
                alert = "DiskUsageHigh"
                expr  = "(node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.15 and node_filesystem_device!~\"(rootfs|tmpfs|overlay)\""
                for   = "10m"
                labels = {
                  severity = "warning"
                }
                annotations = {
                  summary     = "Node disk usage high"
                  description = "Filesystem {{ $labels.mountpoint }} on node {{ $labels.node }} is above 85% used."
                }
              }
            ]
          }
        ]
      }
    ]
  })]

  depends_on = [kubernetes_secret.grafana_admin]
}

resource "kubernetes_config_map" "grafana_cluster_health" {
  metadata {
    name      = "grafana-cluster-health-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
      app               = "grafana"
    }
  }

  data = {
    "cluster-health-dashboard.json" = jsonencode({
      uid         = "cluster-health"
      title       = "Cluster Health"
      schemaVersion = 30
      version     = 1
      panels = [
        {
          type  = "stat"
          title = "Nodes Ready"
          datasource = "Prometheus"
          targets = [{ expr = "count(kube_node_status_condition{condition=\"Ready\",status=\"true\"})", refId = "A" }]
          fieldConfig = { defaults = { unit = "short" } }
          gridPos = { x = 0, y = 0, w = 6, h = 6 }
        },
        {
          type  = "stat"
          title = "Pods Running"
          datasource = "Prometheus"
          targets = [{ expr = "count(kube_pod_status_phase{phase=\"Running\"})", refId = "A" }]
          fieldConfig = { defaults = { unit = "short" } }
          gridPos = { x = 0, y = 0, w = 12, h = 8 }
        },
        {
          type  = "stat"
          title = "Deployments Available"
          datasource = "Prometheus"
          targets = [{ expr = "sum(kube_deployment_status_replicas_available)", refId = "A" }]
          fieldConfig = { defaults = { unit = "short" } }
          gridPos = { x = 0, y = 8, w = 12, h = 8 }
        },
        {
          type  = "graph"
          title = "API Server Request Rate"
          datasource = "Prometheus"
          targets = [{ expr = "rate(apiserver_request_total[5m])", refId = "A" }]
          gridPos = { x = 0, y = 6, w = 12, h = 8 }
        }
      ]
    })
  }
}

resource "kubernetes_config_map" "grafana_node_pod_usage" {
  metadata {
    name      = "grafana-node-pod-usage-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
      app               = "grafana"
    }
  }

  data = {
    "node-pod-usage-dashboard.json" = jsonencode({
      uid         = "node-pod-usage"
      title       = "Node & Pod Resource Usage"
      schemaVersion = 30
      version     = 1
      panels = [
        {
          type  = "timeseries"
          title = "Node CPU Usage"
          datasource = "Prometheus"
          targets = [{ expr = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)", refId = "A" }]
          gridPos = { x = 0, y = 0, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Node Memory Usage"
          datasource = "Prometheus"
          targets = [{ expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)", refId = "A" }]
          gridPos = { x = 0, y = 8, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Pod CPU Usage (Top 10)"
          datasource = "Prometheus"
          targets = [{ expr = "topk(10, sum by (pod, namespace) (rate(container_cpu_usage_seconds_total{container!=\"\",namespace=\"${var.app_namespace}\"}[5m])))", refId = "A" }]
          gridPos = { x = 12, y = 0, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Pod Memory Usage (Top 10)"
          datasource = "Prometheus"
          targets = [{ expr = "topk(10, sum by (pod, namespace) (container_memory_working_set_bytes{container!=\"\",namespace=\"${var.app_namespace}\"}))", refId = "A" }]
          gridPos = { x = 12, y = 8, w = 12, h = 8 }
        },
      ]
    })
  }
}

resource "kubernetes_config_map" "grafana_app_performance" {
  metadata {
    name      = "grafana-app-performance-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
      app               = "grafana"
    }
  }

  data = {
    "app-performance-dashboard.json" = jsonencode({
      uid         = "app-performance"
      title       = "Application Performance"
      schemaVersion = 30
      version     = 1
      panels = [
        {
          type  = "timeseries"
          title = "Application CPU Usage"
          datasource = "Prometheus"
          targets = [{ expr = "sum by (namespace) (rate(container_cpu_usage_seconds_total{container!=\"\",namespace=\"${var.app_namespace}\"}[5m]))", refId = "A" }]
          gridPos = { x = 0, y = 0, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Application Memory Usage"
          datasource = "Prometheus"
          targets = [{ expr = "sum by (namespace) (container_memory_working_set_bytes{container!=\"\",namespace=\"${var.app_namespace}\"})", refId = "A" }]
          gridPos = { x = 0, y = 8, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Network Receive (App Namespace)"
          datasource = "Prometheus"
          targets = [{ expr = "sum by (namespace) (rate(container_network_receive_bytes_total{namespace=\"${var.app_namespace}\"}[5m]))", refId = "A" }]
          gridPos = { x = 12, y = 0, w = 12, h = 8 }
        },
        {
          type  = "timeseries"
          title = "Network Transmit (App Namespace)"
          datasource = "Prometheus"
          targets = [{ expr = "sum by (namespace) (rate(container_network_transmit_bytes_total{namespace=\"${var.app_namespace}\"}[5m]))", refId = "A" }]
          gridPos = { x = 12, y = 8, w = 12, h = 8 }
        }
      ]
    })
  }
}
