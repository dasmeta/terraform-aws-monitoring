data "aws_lb" "balancer" {
  name = var.balancer
}

# locals {
#   balancer      = split("loadbalancer/", var.balancer
#   balancer_name = split("/", local.balancer)[1]
# }
