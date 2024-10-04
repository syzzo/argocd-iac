# Creates the argo application using the prometheus helm chart
# and sets the scrape configs (static) for argocd 
resource "kubernetes_manifest" "argocd_prometheus" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "prometheus"
      namespace = "argo"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://prometheus-community.github.io/helm-charts"
        targetRevision = "25.27.0"
        chart          = "prometheus"
        helm = {
          values = yamlencode({
            server = {
              persistentVolume = {
                size         = "8Gi"
                storageClass = "gp2"
              }
              extraScrapeConfigs = <<-EOF
                - job_name: 'argocd-server-metrics'
                  static_configs:
                    - targets: ['argocd-server-metrics.argo.svc.cluster.local:8083']
                - job_name: 'argocd-repo-server-metrics'
                  static_configs:
                    - targets: ['argocd-repo-server.argo.svc.cluster.local:8084']
                - job_name: 'argocd-application-controller-metrics'
                  static_configs:
                    - targets: ['argocd-application-controller-metrics.argo.svc.cluster.local:8082']
                - job_name: 'argocd-redis-metrics'
                  static_configs:
                    - targets: ['argocd-redis-metrics.argo.svc.cluster.local:9121']
                - job_name: 'argocd-applicationset-controller-metrics'
                  static_configs:
                    - targets: ['argocd-applicationset-controller.argo.svc.cluster.local:8080']
                - job_name: 'argocd-notifications-controller-metrics'
                  static_configs:
                    - targets: ['argocd-notifications-controller.argo.svc.cluster.local:9001']


                # Keycloak metrics (keeping the existing configuration)
                - job_name: 'keycloak'
                  static_configs:
                    - targets: ['keycloak.identity.svc.cluster.local:9000']
                  metrics_path: /metrics
              EOF
            }
            alertmanager = {
              persistentVolume = {
                size         = "2Gi"
                storageClass = "gp2"
              }
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "monitoring"
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
}

# Fetch the certificate for the argo endpoint, could also be 
# passed as a variable but I personally prefer not to have arns as variables
data "aws_acm_certificate" "grafana" {
  domain   = var.grafana_endpoint
  statuses = ["ISSUED"]
}

# Creates the argo application using the grafana helm chart
# Also creates some dashboards for k8s monitoring and 1 for argo
resource "kubernetes_manifest" "argocd_grafana" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "grafana"
      namespace = "argo"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://grafana.github.io/helm-charts"
        targetRevision = "8.5.2"
        chart          = "grafana"
        helm = {
          values = yamlencode({
            ingress = {
              enabled          = true
              ingressClassName = "alb"
              annotations = {
                "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
                "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80},{\"HTTPS\":443}]"
                "alb.ingress.kubernetes.io/certificate-arn" = data.aws_acm_certificate.grafana.arn
                "kubernetes.io/ingress.class"               = "alb"
                "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
                "alb.ingress.kubernetes.io/target-type"     = "ip"
                "external-dns.alpha.kubernetes.io/hostname" = var.grafana_endpoint
              }
              hosts = [var.grafana_endpoint]
              path  = "/"
            }
            persistence = {
              enabled          = true
              size             = "5Gi"
              storageClassName = "gp2"
            }
            dashboardProviders = {
              "dashboardproviders.yaml" = {
                apiVersion = 1
                providers = [
                  {
                    name            = "default"
                    orgId           = 1
                    folder          = ""
                    type            = "file"
                    disableDeletion = false
                    allowUiUpdates  = true
                    options = {
                      path = "/var/lib/grafana/dashboards"
                    }
                  }
                ]
              }
            }
            dashboards = {
              default = {
                "argocd" = {
                  url = "https://raw.githubusercontent.com/argoproj/argo-cd/master/examples/dashboard.json"
                }
                "k8s-addons-prometheus" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-addons-prometheus.json"
                }
                "k8s-system-api-server" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-system-api-server.json"
                }
                "k8s-system-coredns" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-system-coredns.json"
                }
                "k8s-views-global" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-global.json"
                }
                "k8s-views-namespaces" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-namespaces.json"
                }
                "k8s-views-nodes" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-nodes.json"
                }
                "k8s-views-pods" = {
                  url = "https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-pods.json"
                }
              }
            }
            datasources = {
              "datasources.yaml" = {
                apiVersion = 1
                datasources = [
                  {
                    name      = "Prometheus"
                    type      = "prometheus"
                    url       = "http://prometheus-server.monitoring.svc.cluster.local"
                    access    = "proxy"
                    isDefault = true
                  }
                ]
              }
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "monitoring"
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
}
