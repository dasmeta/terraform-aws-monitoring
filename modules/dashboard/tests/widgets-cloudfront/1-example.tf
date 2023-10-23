locals {
  cdn_id = "E1KE24SFESF0852Y"
}
module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-cloudfront-metrics-test"

  defaults = {
    period : 300
  }

  rows = [
    [
      # { type : "cloudfront/combined", distribution : local.cdn_id },
      { type : "cloudfront/error-rate", distribution : local.cdn_id },
      { type : "cloudfront/errors", distribution : local.cdn_id },
      { type : "cloudfront/requests", distribution : local.cdn_id },
      { type : "cloudfront/traffic-bytes", distribution : local.cdn_id },
    ]
  ]
}
