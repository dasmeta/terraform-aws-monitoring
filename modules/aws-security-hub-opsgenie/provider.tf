terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    opsgenie = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

  provider "aws" {
    region = "eu-central-1"
  }

  provider "opsgenie" {
    region = "eu-central-1"
  }
