terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.59"
    }
  }

  required_version = "~> 1.3"
}
