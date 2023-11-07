data "aws_lb_target_group" "target_group" {
  count = var.target_group_arn == null ? 1 : 0
}

locals {
  target_group = "targetgroup/${split("targetgroup/", var.target_group_arn == null ? data.aws_lb_target_group.target_group[0].arn : var.target_group_arn)[1]}"
}
