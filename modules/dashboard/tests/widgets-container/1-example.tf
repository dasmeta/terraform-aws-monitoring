locals {
  cluster            = "prod-6"
  container_1        = "app-1"
  target_group_arn_1 = "arn:aws:elasticloadbalancing:eu-central-1:12345678:targetgroup/k8s-default/sdsf234242423"
  balancer_arn_1     = "arn:aws:elasticloadbalancing:eu-central-1:12345678:loadbalancer/app/app-1/sfsafweewfsada"
  healthcheck_id_1   = "sdasdas-be63-4a0d-dsds-3423rdscza"
}

module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-container-metrics-test"
  defaults = {
    cluster : local.cluster
    anomaly_detection : true
  }
  rows = [
    [
      { type : "text/title", text : "Superset" }
    ],
    [
      { type : "container/cpu", container : local.container_1 },
      { type : "container/memory", container : local.container_1 },
      { type : "container/network", container : local.container_1 },
      { type : "container/network-in", container : local.container_1 }
    ],
    [
      { type : "container/network-out", container : local.container_1 },
      { type : "container/restarts", container : local.container_1 },
      { type : "container/replicas", container : local.container_1 },
      { type : "container/request-count", container : local.container_1, target_group_arn : local.target_group_arn_1 },
    ],
    [
      { type : "container/response-time", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_arn : local.balancer_arn_1 },
      { type : "container/external-health-check", container : local.container_1, healthcheck_id : local.healthcheck_id_1 },
    ]
  ]
}
