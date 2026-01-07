provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}



data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.platform.outputs.cluster_name
}


provider "kubernetes" {
  host = data.terraform_remote_state.platform.outputs.cluster_endpoint

  cluster_ca_certificate = base64decode(
    data.terraform_remote_state.platform.outputs.cluster_ca_certificate
  )

  token = data.aws_eks_cluster_auth.this.token
}


provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  
  
  }
}

