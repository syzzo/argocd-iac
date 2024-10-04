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

variable "hosted_zone_id" {
  description = "Hosted zone Id"
  type        = string
}

variable "hosted_zone_domain" {
  description = "Hosted zone domain"
  type        = string
}