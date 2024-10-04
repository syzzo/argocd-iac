# The 2-EKS-Setup is meant to install the lb controller (allows us to use the aws alb ingress), 
# external-dns (to create route53 records automatically based on an ingress annotation) and 
# cert-manager as TLS will terminate at the ALB level but we want to avoid the issue where keycloak 
# receives an https request and sends and http response. For that we'll be using let's encrypt certificates
# so that the traffic between the load balancer and the keycloak service is also encrypted
locals {
  name = "${var.environment}-${var.product}-${var.service}"
}

# Fetching current caller identity information (i.e. same as aws sts get-caller-identity)
data "aws_caller_identity" "current" {}

# Creating configs namespace to segregate these cluster-wide components
resource "kubernetes_namespace" "configs" {
  metadata {
    name = "configs"
  }
}

data "aws_iam_policy_document" "dns_and_cluster_autoscaler" {

  statement {
    sid    = "Route53Actions"
    effect = "Allow"
    actions = [
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:ChangeResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "eks:DescribeNodegroup"
    ]
  }
}

resource "aws_iam_policy" "kubernetes_cluster_autoscaler" {
  name        = "${local.name}-autoscaler"
  description = "Cluster Autoscaler IAM policy"
  policy      = data.aws_iam_policy_document.dns_and_cluster_autoscaler.json
}

data "aws_iam_policy_document" "kubernetes_cluster_autoscaler_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:configs:cluster-autoscaler",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "kubernetes_cluster_autoscaler" {
  name               = "${local.name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_cluster_autoscaler_assume.json
}

resource "aws_iam_role_policy_attachment" "kubernetes_cluster_autoscaler" {
  role       = aws_iam_role.kubernetes_cluster_autoscaler.name
  policy_arn = aws_iam_policy.kubernetes_cluster_autoscaler.arn
}

# Cluster Autoscaler Helm release
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "configs"
  version    = "9.43.0"

  set {
    name  = "fullnameOverride"
    value = "aws-cluster-autoscaler"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = local.name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.kubernetes_cluster_autoscaler.arn
  }
}

# External DNS Setup
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = "configs"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "domainFilters[0]"
    value = var.hosted_zone_domain
  }

  # Makes it so that it cannot delete any route53 records, it can only add
  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = local.name
  }

  set {
    name  = "sources[0]"
    value = "service"
  }

  set {
    name  = "sources[1]"
    value = "ingress"
  }

  set {
    name  = "zoneIdFilters[0]"
    value = var.hosted_zone_id
  }
}

# Service account for the lb controller
resource "kubernetes_service_account" "lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "configs"
  }

  automount_service_account_token = true
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "http://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "configs"

  set {
    name  = "clusterName"
    value = local.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller_sa.metadata[0].name
  }
}

# Setting up cert manager as keycloak will require it
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.12.0"

  set {
    name  = "installCRDs"
    value = "true"
  }

  create_namespace = true
  depends_on       = [helm_release.aws_lb_controller]
}