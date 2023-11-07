data "aws_cloudfront_distribution" "test" {
  id = var.distribution
}

locals {
  balancer = split("loadbalancer/", data.aws_alb.balancer.arn)[1]
}
