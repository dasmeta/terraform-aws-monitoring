module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = local.title

  # stats
  stat   = local.stat
  period = var.period

  defaults = {
    "DistributionId" : var.distribution
  }

  metrics = [
    { local.namespace : "RequestCount" }
  ]
}
