data "aws_region" "current" {}

data "aws_alb" "balancer" {
  name = var.balancer
}

locals {
  balancer = split("loadbalancer/", data.aws_alb.balancer.arn)[1]
}
