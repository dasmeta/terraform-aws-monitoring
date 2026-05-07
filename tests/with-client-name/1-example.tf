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
  enable_log_base_metrics = false

  alerts = [
    {
      description = "Frontend restart alarm should keep its primary description"
      name        = "Frontend has too many restarts (eks-dev)"
      source      = "ContainerInsights/pod_number_of_container_restarts"
      filters = {
        PodName     = "test-application"
        ClusterName = "eks-dev"
        Namespace   = "test-app"
      }
      period    = 86400
      statistic = "sum"
      threshold = 2
    },
  ]

  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }
}

output "expected_standard_alarm_metadata" {
  value = local.expected_standard_alarm_metadata
}
