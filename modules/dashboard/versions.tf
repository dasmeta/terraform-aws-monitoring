terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.3"
    }

    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.13.3"
    }
  }
}
