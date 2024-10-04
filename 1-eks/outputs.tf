output "cluster_iam_role_arn" {
  value       = module.eks.cluster_iam_role_arn
  description = "Cluster IAM Role ARN"
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OIDC Issuer ARN"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC Provider ARN"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Cluster name"
}