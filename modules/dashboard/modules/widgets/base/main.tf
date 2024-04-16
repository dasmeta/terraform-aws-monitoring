module "base_cloudwatch" {
  source = "./platforms/cloudwatch"

  count = var.platform == "cloudwatch" ? 1 : 0

  name                     = var.name
  coordinates              = var.coordinates
  metrics                  = var.metrics
  expressions              = var.expressions
  defaults                 = var.defaults
  stat                     = var.stat
  period                   = var.period
  region                   = local.region
  anomaly_detection        = var.anomaly_detection
  anomaly_deviation        = var.anomaly_deviation
  type                     = var.type
  query                    = var.query
  sources                  = var.sources
  view                     = var.view
  stacked                  = var.stacked
  annotations              = var.annotations
  alarms                   = var.alarms
  properties_type          = var.properties_type
  yAxis                    = var.yAxis
  setPeriodToTimeRange     = var.setPeriodToTimeRange
  singleValueFullPrecision = var.singleValueFullPrecision
  sparkline                = var.sparkline
  start                    = var.start
  trend                    = var.trend
  end                      = var.end
}

module "base_grafana" {
  source = "./platforms/grafana"

  count = var.platform == "grafana" ? 1 : 0

  name              = var.name
  data_source_uid   = var.data_source_uid
  coordinates       = var.coordinates
  metrics           = var.metrics
  defaults          = var.defaults
  stat              = var.stat
  period            = var.period
  region            = local.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation
  type              = var.type
  query             = var.query
  sources           = var.sources
  view              = var.view
  stacked           = var.stacked
  annotations       = var.annotations
  alarms            = var.alarms
  properties_type   = var.properties_type
}
