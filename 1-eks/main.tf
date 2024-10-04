locals {
  name = "${var.environment}-${var.product}-${var.service}"
}

# Fetch current caller identity data
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Creating the role for the ebs csi
resource "aws_iam_role" "volume_csi_driver_role" {
  name = "${local.name}-volume-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

# Adding the configs for external dns and aws alb immediately
data "aws_iam_policy_document" "extra_configs" {
  statement {
    sid    = "Route53Actions"
    effect = "Allow"
    actions = [
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
    sid    = "IAMCreateServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "EC2DescribeAndELBDescribeActions"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",

      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",

      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",

      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",

      "ec2:CreateSecurityGroup",

      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = "EC2CreateTags"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "EC2ModifyTags"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid    = "EC2DeleteSecurityGroup"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",

      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "ELBCreateResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "ELBAddRemoveTags"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/*/*",
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid    = "ELBAddRemoveTagsListeners"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/*/*/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "ELBAddRemoveTagsTG"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/*/*",
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateTargetGroup", "CreateLoadBalancer"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "ELBRegisterDeregisterTargets"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/*/*"]
  }

  statement {
    sid       = "ExternalDNS"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
  }
}
resource "aws_iam_policy" "extra_configs" {
  name        = "${local.name}-extra-configs"
  description = "Cluster Extra Configs IAM policy"
  policy      = data.aws_iam_policy_document.extra_configs.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  role       = aws_iam_role.volume_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Creating the EKS cluster via community module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      addon_version = "v1.11.1-eksbuild.11"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.3"
    }
    vpc-cni = {
      addon_version = "v1.18.3-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.33.0-eksbuild.1"
      resolve_conflicts        = "NONE"
      service_account_role_arn = aws_iam_role.volume_csi_driver_role.arn
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids
  iam_role_use_name_prefix = false

  eks_managed_node_group_defaults = {
    iam_role_use_name_prefix = false
    use_name_prefix          = false
    instance_types           = ["m6i.2xlarge"]
    iam_role_additional_policies = {
      ebs = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      extra_configs  = aws_iam_policy.extra_configs.arn
    }
  }

  eks_managed_node_groups = {
    blue = {
      iam_role_use_name_prefix = false

      min_size     = 3
      max_size     = 15
      desired_size = 3

      instance_types = ["m6i.2xlarge"]

      launch_template_tags = {
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }
    }
  }
}

# A simple local exec just to add it to my kube config for testing. Feel free to comment it but it's necessary to perform port-forwarding for 5-authentication-setup
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${local.name} --region ${data.aws_region.current.name} --profile ${var.profile}"
  }

  depends_on = [
    module.eks
  ]
}
