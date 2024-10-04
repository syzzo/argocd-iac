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
  description = "Keycloak route53 endpoint (e.g. keycloak.domain.com)"
  type        = string
}

variable "argo_endpoint" {
  description = "Argo route53 endpoint (e.g. argo.domain.com)"
  type        = string
}

variable "argo_client_secret" {
  description = "Argo client secret"
  type        = string
  default     = ""
}

variable "argo_client_id" {
  description = "Argo client id"
  type        = string
}