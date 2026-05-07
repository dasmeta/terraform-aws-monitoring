data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  expected_alarm_url_base = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#alarmsV2:alarm/"

  expected_standard_alarm_metadata = join("\n", [
    "account - \"${data.aws_caller_identity.current.account_id}\"",
    "source - \"${local.expected_alarm_url_base}${replace(urlencode("Frontend has too many restarts (eks-dev)"), "+", "%20")}\"",
  ])
}

module "this" {
  source                  = "../../"
  name                    = "dev"
  client_name             = "dasmeta-platform"
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
      description = "Application log failures should keep their summary before metadata lines"
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
      description = "Frontend restart alarm should keep its primary description"
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
  expression_alert = {
    "test-alb-5xx-success-rate" = {
      description = "ALB success-rate expression alarm should keep its primary description"
      equation    = "lt"
      threshold   = 90
      metrics = [
        {
          id          = "m5x"
          period      = 0
          return_data = false
          metric = [{
            dimensions  = { LoadBalancer = aws_lb.test.arn_suffix }
            metric_name = "HTTPCode_Target_5XX_Count"
            namespace   = "AWS/ApplicationELB"
            period      = 300
            stat        = "Average"
          }]
        },
        {
          id          = "mTotal"
          period      = 0
          return_data = false
          metric = [{
            dimensions  = { LoadBalancer = aws_lb.test.arn_suffix }
            metric_name = "RequestCount"
            namespace   = "AWS/ApplicationELB"
            period      = 300
            stat        = "Average"
          }]
        },
        {
          expression  = "100*(mTotal-m5x)/mTotal"
          id          = "e1"
          label       = "SuccessRate"
          period      = 0
          return_data = true
        }
      ]
    }
  }
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

output "expected_standard_alarm_metadata" {
  value = local.expected_standard_alarm_metadata
}
