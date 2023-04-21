terraform {
  required_version = ">= 1.3"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 1.0"
    }
  }
}

# set AWS_* env variables to setup aws provider
provider "aws" {
  region = "eu-central-1"
}

# set KUBE_CONFIG_PATH env variable to prepare helm provider
provider "helm" {}
