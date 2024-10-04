locals {
  name = "${var.environment}-${var.product}-${var.service}"
}

# This (cluster issuer) will allow the the kubernetes api to leverage cert-manager to
# automatically issue TLS certificates using Let’s Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acm-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "alb"
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "argocd_keycloak" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "keycloak"
      namespace  = "argo"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://codecentric.github.io/helm-charts"
        targetRevision = "*"
        chart          = "keycloakx"
        helm = {
          values = yamlencode({
            service = {
              type = "ClusterIP"
              port = 8080
              #   httpManagementPort : 9000
              #   extraPorts = [
              #     {
              #       name       = "metrics"
              #       port       = 9000
              #       targetPort = 9000
              #     }
              #   ]
              #   annotations = {
              #     "prometheus.io/scrape" = "true"
              #     "prometheus.io/port"   = 9000
              #     "prometheus.io/path"   = "/metrics"
              #   }
            }
            ingress = {
              enabled   = true
              className = "alb"
              annotations = {
                "kubernetes.io/ingress.class"                        = "alb"
                "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
                "alb.ingress.kubernetes.io/target-type"              = "ip"
                "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTP\":80},{\"HTTPS\":443}]"
                "alb.ingress.kubernetes.io/ssl-redirect"             = "443"
                "alb.ingress.kubernetes.io/group.name"               = "identity"
                "alb.ingress.kubernetes.io/load-balancer-attributes" = "routing.http.x_amzn_tls_version_and_cipher_suite.enabled=true,routing.http.xff_client_port.enabled=true,routing.http.xff_header_processing.mode=append"
                "external-dns.alpha.kubernetes.io/hostname"          = var.keycloak_endpoint
                "alb.ingress.kubernetes.io/backend-protocol"         = "HTTP"
                "alb.ingress.kubernetes.io/ssl-policy"               = "ELBSecurityPolicy-TLS-1-2-2017-01"
                "cert-manager.io/cluster-issuer"                     = "letsencrypt-prod"
              }
              rules = [{
                host = var.keycloak_endpoint
                paths = [{
                  path     = "/"
                  pathType = "Prefix"
                }]
              }]
              tls = [{
                hosts      = [var.keycloak_endpoint]
                secretName = "keycloak-tls"
              }]
            }
            http = {
              relativePath = "/"
            }
            hostname = {
              hostname = var.keycloak_endpoint
            }
            # configuration = <<-EOT
            #   metrics.enabled=true
            #   metrics.exposedEndpoints=metrics
            # EOT
            extraEnv      = <<-EOT
              # - name: KC_HTTP_MANAGEMENT_ENABLED
              #   value: "true"
              # - name: KC_HTTP_MANAGEMENT_PORT
              #   value: "9000"
              # - name: KEYCLOAK_METRICS_ENABLED
              #   value: "true"
              # - name: KEYCLOAK_STATISTICS
              #   value: "all"
              - name: KEYCLOAK_ADMIN
                value: admin
              - name: KEYCLOAK_ADMIN_PASSWORD
                value: ${var.keycloak_admin_password}
              - name: JAVA_OPTS_APPEND
                value: >-
                  -Djgroups.dns.query={{ .Release.Name }}-headless
              - name: KC_HOSTNAME_STRICT
                value: "false"
              - name: KC_PROXY_ADDRESS_FORWARDING
                value: "true"
              - name: KC_HOSTNAME
                value: "https://${var.keycloak_endpoint}"
              - name: KC_HOSTNAME_URL
                value: "https://${var.keycloak_endpoint}"
              - name: KC_HOSTNAME_ADMIN_URL
                value: "https://${var.keycloak_endpoint}"
              - name: KC_HTTP_ENABLED
                value: "false"
              - name: KC_HTTP_RELATIVE_PATH
                value: "/"
              - name: KC_HTTPS_PORT
                value: "443"
              - name: KEYCLOAK_LOGLEVEL
                value: DEBUG
              # - name: KC_METRICS_ENABLED
              #   value: "true"
            EOT
            args = [
              "start",
              "--optimized",
              #"--http-enabled=true",
              "--https-port=443",
              #"--http-port=8080",
              "--hostname-strict=false",
              "--proxy-headers=forwarded",
              #"--metrics-enabled=true",
              #"-Dkeycloak.profile.feature.metrics=enabled",
            ]
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "identity"
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