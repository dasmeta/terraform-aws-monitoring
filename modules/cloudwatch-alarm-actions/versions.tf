terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.2, < 7.0"
    }
  }

  required_version = ">= 1.3.0"
}
