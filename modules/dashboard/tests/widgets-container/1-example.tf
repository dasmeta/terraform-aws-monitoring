locals {
  cluster     = "prod-6"
  container_1 = "superset-helm"
  //TODO-?: find a solution
  target_group_arn_1 = "arn:aws:elasticloadbalancing:eu-central-1:123456789:targetgroup/k8s-default-dsb00d/24124124214124asd"
  balancer_name      = "query-me-prod"
  //TODO-?: keep healthcheck ID in somewhere
  healthcheck_id_1 = "smhfh234234-safasf-rtgdf-a782-gdgdsfr32542"
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
      { type : "container/response-time", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_name : local.balancer_name },
      { type : "container/external-health-check", container : local.container_1, healthcheck_id : local.healthcheck_id_1 },
    ]
  ]
}
