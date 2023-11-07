data "aws_lb_target_group" "target_group" {
  count = var.target_group_arn == null ? 1 : 0
}

data "aws_lb" "balancer" {
  count = var.balancer_arn == null ? 1 : 0

  name = var.balancer_name
}

locals {
  balancer      = split("loadbalancer/", var.balancer_arn == null ? data.aws_lb.balancer[0].arn : var.balancer_arn)[1]
  balancer_name = split("/", local.balancer)[1]
  target_group  = "targetgroup/${split("targetgroup/", var.target_group_arn == null ? data.aws_lb_target_group.target_group[0].arn : var.target_group_arn)[1]}"
}
