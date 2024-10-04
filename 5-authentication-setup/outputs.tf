output "client_id" {
  description = "Argo Client ID"
  value       = keycloak_openid_client.argocd_client.client_id
}

output "client_secret" {
  description = "Argo Client Secret"
  value       = keycloak_openid_client.argocd_client.client_secret
  sensitive   = true
}

output "client_secret_instruction" {
  description = "Argo Client Secret Instructions"
  value       = "1 - terraform output -raw client_secret\n2 - cd ../3-argo and replace argo_client_secret in your tfvars\n3 - terraform apply --auto-approve"
}