data "aws_lb" "balancer" {
  count = var.balancer_arn == null ? 1 : 0

  name = var.balancer_name
}

locals {
  balancer      = split("loadbalancer/", var.balancer_arn == null ? data.aws_lb.balancer[0].arn : var.balancer_arn)[1]
  balancer_name = split("/", local.balancer)[1]
}
