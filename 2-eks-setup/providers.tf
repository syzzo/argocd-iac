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

# Fetch config from eks deployment
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../1-eks/terraform.tfstate"
  }
}

# We can also fetch it by name in case you don't like remote states all we need is to create a variable
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}