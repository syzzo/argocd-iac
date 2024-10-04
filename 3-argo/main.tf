# Fetch the certificate for the argo endpoint, could also be 
# passed as a variable but I personally prefer not to have arns as variables
data "aws_acm_certificate" "argo" {
  domain   = var.argo_endpoint
  statuses = ["ISSUED"]
}

# Helm release for argocd. The idea here is to launch argo with the oidc settings even though
# keycloak will be created later. As soon as keycloak is up and running (4-keycloak), we will 
# configure it (5-authentication-setup) and re-exectute this terraform with the created realm's client-secret

# The rest of the parameters are essentially monitoring configuration and ingress setup
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argo"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.6.7"
  create_namespace = true

  values = [
    <<-EOT
    configs:
      params:
        server.insecure: true
      cm:
        create: true
        oidc.config: |
          name: Keycloak
          issuer: https://${var.keycloak_endpoint}/realms/argocd
          clientID: argocd
          clientSecret: ${var.argo_client_secret}
          insecureEnableGroups: true
          insecureSkipIssuerValidation: true
          requestedScopes: ["openid"]
      rbac:
        policy.default: role:readonly
        "policy.csv": |
          g, argocd-admin, role:admin

    global:
      domain: ${var.argo_endpoint}

    server:
      extraArgs:
        - --insecure
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
          alb.ingress.kubernetes.io/ssl-redirect: "443"
          alb.ingress.kubernetes.io/certificate-arn: ${data.aws_acm_certificate.argo.arn}
          alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
          external-dns.alpha.kubernetes.io/hostname: ${var.argo_endpoint}
        hosts:
          - ${var.argo_endpoint}
        paths:
          - /
      config:
        oidc.tls.insecure.skip.verify: true
      rbacConfig:
        policy.csv: |
          g, argocd-admin, role:admin
        policy.default: role:readonly
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "8083"
            prometheus.io/path: "/metrics"

    repoServer:
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "8084"
            prometheus.io/path: "/metrics"

    applicationSet:
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "8080"
            prometheus.io/path: "/metrics"

    controller:
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "8082"
            prometheus.io/path: "/metrics"
    EOT
  ]

  set_sensitive {
    name  = "configs.secret.oidc\\.keycloak\\.clientSecret"
    value = var.argo_client_secret
  }
}