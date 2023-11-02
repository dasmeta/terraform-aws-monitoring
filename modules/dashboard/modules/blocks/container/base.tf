data "aws_caller_identity" "project" {
  provider = aws
}

locals {
  account_id = var.account_id == null ? "${data.aws_caller_identity.project.account_id}" : var.account_id
  cluster    = var.cluster
  container  = var.container
  //TODO-?: find a solution
  target_group_arn = var.target_group_arn
  balancer_name    = var.balancer_name
  //TODO-?: keep healthcheck ID in somewhere
  healthcheck_id = var.healthcheck_id
  # container_2 = "superset-helm"
}

module "dashboard-with-container-metrics" {
  source = "../../.."

  name = "container"

  create_dashboard = false

  defaults = {
    cluster : local.cluster
    anomaly_detection : true
  }

  rows = [
    [
      { type : "text/title", text : "Superset" }
    ],
    [
      { type : "container/cpu", container : local.container },
      { type : "container/memory", container : local.container },
      { type : "container/network", container : local.container },
      { type : "container/network-in", container : local.container }
    ],
    [
      { type : "container/network-out", container : local.container },
      { type : "container/restarts", container : local.container },
      { type : "container/replicas", container : local.container },
      { type : "container/request-count", container : local.container, target_group_arn : local.target_group_arn },
    ],
    [
      { type : "container/response-time", container : local.container, target_group_arn : local.target_group_arn, balancer_name : local.balancer_name },
      { type : "container/external-health-check", container : local.container, healthcheck_id : local.healthcheck_id },
      { type : "container/error-rate", container : local.container, target_group_arn : local.target_group_arn, balancer_name : local.balancer_name },
      { type : "container/all-requests", container : local.container, target_group_arn : local.target_group_arn, balancer_name : local.balancer_name },
    ],
    [
      { type : "container/health-check", container : local.container, target_group_arn : local.target_group_arn, balancer_name : local.balancer_name },
    ]
  ]
}
