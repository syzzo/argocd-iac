provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      "environment" = var.environment
      "product"     = var.product
      "service"     = var.service
      "usage"       = "temporary"
    }
  }
}
