provider "aws" {
  region = var.region
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}


terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = "~>4.50"
    }
  }
  cloud {
    organization = "corify"
    workspaces {
      tags = ["component:monitoring"]
    }
  }
}
