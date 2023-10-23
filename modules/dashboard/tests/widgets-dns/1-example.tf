locals {
  zone_name = "example.com"
}

module "dashboard-with-dns-metrics" {
  source = "../../"
  name   = "dashboard-with-dns-metrics-test"

  defaults = {
    period : 300
  }

  rows = [
    [
      { type : "dns/queries-gauge", zone_name : local.zone_name },
      { type : "dns/queries-chart", zone_name : local.zone_name },
    ]
  ]
}
