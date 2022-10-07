data "aws_region" "current" {
  count = var.region == "" ? 1 : 0
}
