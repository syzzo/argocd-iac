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

variable "subnet_ids" {
  description = "The subnet IDs where all the resources will be deployed to"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "The subnet IDS for the control plane"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the cluster is meant to be deployed at"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes cluster version (defaults to 1.30)"
  type        = string
  default     = "1.30"
}

variable "hosted_zone_id" {
  description = "Hosted zone Id"
  type        = string
}

variable "hosted_zone_domain" {
  description = "Hosted zone domain (e.g. domain.com)"
  type        = string
}