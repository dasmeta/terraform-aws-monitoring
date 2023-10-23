data "aws_route53_zone" "selected" {
  name = var.zone_name
}

locals {
  zone_id = data.aws_route53_zone.selected.zone_id
}
