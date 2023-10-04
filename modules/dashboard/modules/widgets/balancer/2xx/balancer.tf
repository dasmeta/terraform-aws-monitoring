data "aws_alb" "balancer" {
  count = var.balancer_arn == null ? 1 : 0
}

locals {
  balancer      = split("loadbalancer/", var.balancer_arn == null ? data.aws_alb.balancer[0].arn : var.balancer_arn)[1]
  balancer_name = split("/", local.balancer)[1]
}
