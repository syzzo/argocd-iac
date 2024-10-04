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

variable "keycloak_endpoint" {
  description = "Keycloak endpoint"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak's admin password"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email to be used for let's encrypt certificates"
  type        = string
}
