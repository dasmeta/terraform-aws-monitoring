terraform {
  required_version = ">= 1.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {
  # Configuration options
}
