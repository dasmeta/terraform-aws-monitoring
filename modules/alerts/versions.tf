terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"

      configuration_aliases = [aws, aws.logging]
    }
  }

  required_version = ">= 1.3.0"
}
