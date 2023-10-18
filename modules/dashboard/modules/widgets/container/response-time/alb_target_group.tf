data "aws_lb_target_group" "target_group" {
  count = var.target_group_arn == null ? 1 : 0
}

data "aws_alb" "balancer" {
  count = var.balancer_arn == null ? 1 : 0
}

locals {
  balancer     = split("loadbalancer/", var.balancer_arn == null ? data.aws_alb.balancer[0].arn : var.balancer_arn)[1]
  target_group = "targetgroup/${split("targetgroup/", var.target_group_arn == null ? data.aws_lb_target_group.target_group[0].arn : var.target_group_arn)[1]}"
}
