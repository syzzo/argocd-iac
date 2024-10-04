# Creates the realm
resource "keycloak_realm" "argocd_realm" {
  realm        = "argocd"
  enabled      = true
  display_name = "ArgoCD Realm"
}

# Creates the client for ArgoCD
resource "keycloak_openid_client" "argocd_client" {
  realm_id                     = keycloak_realm.argocd_realm.id
  client_id                    = "argocd"
  name                         = "argocd"
  enabled                      = true
  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  service_accounts_enabled     = true
  valid_redirect_uris = [
    "https://${var.argo_endpoint}/*",
    "https://${var.argo_endpoint}"
  ]
  web_origins = [
    "https://${var.argo_endpoint}",
    "https://${var.argo_endpoint}/*"
  ]
  root_url  = "https://${var.argo_endpoint}"
  admin_url = "https://${var.argo_endpoint}"
  base_url  = "/"
}

# Creates a Keycloak user for authentication
resource "keycloak_user" "argocd_user" {
  realm_id   = keycloak_realm.argocd_realm.id
  username   = var.argo_user_name
  enabled    = true
  email      = var.argo_user_email
  first_name = var.argo_user_first_name
  last_name  = var.argo_user_last_name

  initial_password {
    value     = var.argo_user_password
    temporary = false
  }
}

# Assign default scopes to the client, including openid, profile, email, and roles
resource "keycloak_openid_client_default_scopes" "client_default_scopes" {
  realm_id  = keycloak_realm.argocd_realm.id
  client_id = keycloak_openid_client.argocd_client.id
  default_scopes = [
    "openid",
    "profile",
    "email",
    "roles"
  ]
  depends_on = [keycloak_openid_client.argocd_client, keycloak_realm.argocd_realm]
}

# Create a client role for ArgoCD
resource "keycloak_role" "argocd_admin" {
  realm_id    = keycloak_realm.argocd_realm.id
  client_id   = keycloak_openid_client.argocd_client.id
  name        = "argocd-admin"
  description = "ArgoCD Administrator"
}

# Assign the client role to the user
resource "keycloak_user_roles" "argocd_user_client_roles" {
  realm_id = keycloak_realm.argocd_realm.id
  user_id  = keycloak_user.argocd_user.id
  role_ids = [keycloak_role.argocd_admin.id]
}
