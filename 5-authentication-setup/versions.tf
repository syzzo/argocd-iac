terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.69"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 3.0"
    }
  }
}