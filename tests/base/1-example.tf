module "this" {
  source                  = "../../"
  name                    = "dev"
  sns_topic_name          = "alarm-dev"
  enable_log_base_metrics = true
  health_checks = [
    {
      host = "dasmeta.com"
      path = "/"
    }
  ]
  log_base_metrics = [
    {
      name           = "container_exception_error_fail_crash_critical"
      pattern        = "{$.log = *error* || $.log = *fail* || $.log = *crash* || $.log = *critical* || $.log = *exception*}"
      log_group_name = aws_cloudwatch_log_group.test.name
    },
  ]
  application_channel_alerts = [
    {
      name      = "Too many exception/fail/crash/error/critical in logs"
      source    = "LogGroupFilter/container_exception_error_fail_crash_critical_dev"
      statistic = "sum"
      threshold = 100
      period    = 600
      filters   = {}
    },
  ]
  alerts = [
    // Restarts
    {
      name   = "Frontend has too many restarts (eks-dev)"
      source = "ContainerInsights/pod_number_of_container_restarts"
      filters = {
        PodName     = "test-application",
        ClusterName = "eks-dev",
        Namespace   = "test-app"
      }
      period    = 86400
      statistic = "sum"
      threshold = 2
    },
  ]
  eks_monitroing_dashboard = [
    [
      {
        type : "text/title"
        text : "Nodes"
      }
    ],
  ]
  application_monitroing_dashboard = [
    [
      {
        width         = 24
        height        = 8
        type          = "sla-slo-sli",
        balancer_name = aws_lb.test.name
        region        = "eu-central-1"
      }
    ],
  ]
  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }

  depends_on = [aws_cloudwatch_log_group.test, aws_lb.test]
}
