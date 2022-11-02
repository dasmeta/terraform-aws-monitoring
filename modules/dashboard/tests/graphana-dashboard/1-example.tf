module "dashboard-with-logs-insight-metrics-cloudwatch" {
  source   = "../../"
  name     = "dashboard-with-logs-insight-metrics"
  platform = "cloudwatch"
  defaults = {
    width     = 8
    container = "aws-cloudwatch-metrics"
    cluster   = "sandbox"
    namespace = "amazon-cloudwatch"
  }

  rows = local.rows
}


module "dashboard-with-logs-insight-metrics-grafana" {
  source          = "../../"
  name            = "dashboard-with-logs-insight-metrics"
  platform        = "grafana"
  data_source_uid = "zR-0vclnk" # The data source additional param for grafana dashboard metrics
  defaults = {
    width     = 8
    container = "aws-cloudwatch-metrics"
    cluster   = "sandbox"
    namespace = "amazon-cloudwatch"
  }

  rows = local.rows
}