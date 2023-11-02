# DNS widgets
module "widget_dns_queries_gauge" {
  source = "./modules/widgets/dns/queries-gauge"

  count = length(local.dns_queries_gauge)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.dns_queries_gauge[count.index].coordinates

  # stats
  period = local.dns_queries_gauge[count.index].period

  # zone name
  zone_name = local.dns_queries_gauge[count.index].zone_name
}

module "widget_dns_queries_chart" {
  source = "./modules/widgets/dns/queries-chart"

  count = length(local.dns_queries_chart)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.dns_queries_chart[count.index].coordinates

  # stats
  period = local.dns_queries_chart[count.index].period

  # zone name
  zone_name = local.dns_queries_chart[count.index].zone_name
}
