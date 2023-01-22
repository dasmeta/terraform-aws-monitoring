terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    
    opsgenie = {
      source  = "opsgenie/opsgenie"
      version = "~> 3.0"
    }
  }
}
