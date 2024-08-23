terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# get region default vpc and its public subnets
data "aws_vpc" "default" {
  default  = true
  provider = aws
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# create test alb
resource "aws_lb" "test" {
  name     = "test-dashboard-alb"
  provider = aws
  subnets  = data.aws_subnets.default.ids
}

# create test log group
resource "aws_cloudwatch_log_group" "test" {
  name = "test-dashboard-log-group"
}
