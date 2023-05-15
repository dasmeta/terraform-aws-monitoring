module "base" {
  source = "../base"

  coordinates = var.coordinates

  name = "SLA/SLO/SLI (${local.balancer_name})"

  # stats
  stat   = "Sum"
  period = var.period
  view   = "gauge"
  yAxis  = { left = { min = 0, max = 100 } }

  setPeriodToTimeRange     = true 
  singleValueFullPrecision = false 
  sparkline                = false 
  stacked                  = false 
  start                    = "-PT8640H" 
  trend                    = false
  end                      = "P0D"


  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    LoadBalancer    = local.balancer
    accountId       = var.account_id
  }

  metrics = [
    { id = "mTotal", MetricName = "RequestCount", visible = false },
    { id = "mt1x", MetricName = "HTTPCode_Target_1XX_Count", visible = false },
    { id = "mt2x", MetricName = "HTTPCode_Target_2XX_Count", visible = false },
    { id = "mt3x", MetricName = "HTTPCode_Target_3XX_Count", visible = false },
    { id = "mt4x", MetricName = "HTTPCode_Target_4XX_Count", visible = false },
    { id = "mt5x", MetricName = "HTTPCode_Target_5XX_Count", visible = false },
    { id = "me1x", MetricName = "HTTPCode_ELB_1XX_Count", visible = false },
    { id = "me2x", MetricName = "HTTPCode_ELB_2XX_Count", visible = false },
    { id = "me3x", MetricName = "HTTPCode_ELB_3XX_Count", visible = false },
    { id = "me4x", MetricName = "HTTPCode_ELB_4XX_Count", visible = false },
    { id = "me5x", MetricName = "HTTPCode_ELB_5XX_Count", visible = false }
  ]

  expressions = [
    {
      expression = "100*(mTotal-me5x)/mTotal"
      label      = "ALB (excl. 5xx) %"
      color      = "#2ca02c"
    },
    {
      expression = "100*(mTotal-me5x-me4x)/mTotal"
      label      = "ALB (excl. 5xx+4xx) %"
      color      = "#bcbd22"
    },
    {
      expression = "100*(mTotal-mt5x)/mTotal"
      label      = "Target (excl. 5xx) %"
    },
    {
      expression = "100*(mTotal-mt4x-mt5x)/mTotal"
      label      = "Target (excl. 5xx+4xx) %"
      color      = "#17becf"
    }
  ]
}
