variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, prod)"
  type        = string
}

variable "product" {
  description = "The name of the product"
  type        = string
}

variable "service" {
  description = "The service to deploy (e.g. jira, test, etc...)"
  type        = string
}

variable "profile" {
  description = "AWS CLI profile to use for the deployment"
  type        = string
  default     = "default"
}


variable "argo_endpoint" {
  description = "Argo HTTPS endpoint (e.g. argocd.example.com)"
  type        = string
}

variable "argo_user_name" {
  description = "The username for ArgoCD user"
  type        = string
  default     = "argocd-user"
}

variable "argo_user_email" {
  description = "The email address for the ArgoCD user"
  type        = string
  default     = "bob@domain.com"
}

variable "argo_user_first_name" {
  description = "The first name of the ArgoCD user"
  type        = string
  default     = "Bob"
}

variable "argo_user_last_name" {
  description = "The last name of the ArgoCD user"
  type        = string
  default     = "Bobson"
}

variable "argo_user_password" {
  description = "The password for the ArgoCD user"
  type        = string
  default     = "argocd-password"
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Keycloak's admin password (the same as in step 4-keycloak)"
  type        = string
  sensitive   = true
}