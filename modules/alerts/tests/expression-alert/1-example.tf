module "expression_alert" {
  source = "../../"


  sns_topic = aws_sns_topic.tets_topic_for_alarm_actions.name
  expression_alert = {
    "excl_5xx" = {
      equation  = "lt"
      threshold = 90
      metrics = [
        {
          id          = "m5x"
          period      = 0
          return_data = false
          # metric = []
          metric = [{
            dimensions  = { "LoadBalancer" = "app/alb-test/803783" }
            metric_name = "HTTPCode_Target_5XX_Count"
            namespace   = "AWS/ApplicationELB"
            period      = 300
            stat        = "Average"
            }
          ]
        },
        {
          id          = "mTotal"
          period      = 0
          return_data = false

          metric = [{
            dimensions  = { "LoadBalancer" = "app/alb-test/803783" }
            metric_name = "RequestCount"
            namespace   = "AWS/ApplicationELB"
            period      = 300
            stat        = "Average"
          }]
        },
        {
          expression  = "100*(mTotal-m5x)/mTotal"
          id          = "e1"
          label       = "Expression1"
          period      = 0
          return_data = true
        }
      ]
    }
  }
  enable_insufficient_data_actions = false
  enable_ok_actions                = false
}
