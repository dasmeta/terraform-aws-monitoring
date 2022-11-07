terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.3"
    }

    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.13.3"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }
}
