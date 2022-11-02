# // balancer
module "container_balancer_2xx_widget" {
  source = "./modules/widgets/balancer/2xx"

  count = length(local.balancer_2xx)

  # coordinates
  coordinates = local.balancer_2xx[count.index].coordinates

  # stats
  period = local.balancer_2xx[count.index].period

  # balancer
  balancer_arn = try(local.balancer_2xx[count.index].balancer_arn, null)

  account_id        = try(local.balancer_2xx[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.balancer_2xx[count.index].anomaly_detection, false)
}

module "container_balancer_4xx_widget" {
  source = "./modules/widgets/balancer/4xx"

  count = length(local.balancer_4xx)

  # coordinates
  coordinates = local.balancer_4xx[count.index].coordinates

  # stats
  period = local.balancer_4xx[count.index].period

  # balancer
  balancer_arn = try(local.balancer_4xx[count.index].balancer_arn, null)

  account_id = try(local.balancer_4xx[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_4xx[count.index].anomaly_detection, false)
}

module "container_balancer_5xx_widget" {
  source = "./modules/widgets/balancer/5xx"

  count = length(local.balancer_5xx)

  # coordinates
  coordinates = local.balancer_5xx[count.index].coordinates

  # stats
  period = local.balancer_5xx[count.index].period

  # balancer
  balancer_arn = try(local.balancer_5xx[count.index].balancer_arn, null)

  account_id = try(local.balancer_5xx[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_5xx[count.index].anomaly_detection, false)
}
