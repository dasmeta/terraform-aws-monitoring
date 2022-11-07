data "aws_region" "current" {
  count = var.region == "" ? 1 : 0
}

locals {
  region = var.region != "" ? var.region : data.aws_region.current[0].name
}
