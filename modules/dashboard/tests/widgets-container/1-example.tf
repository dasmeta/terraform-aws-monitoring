locals {
  cluster   = "prod-6"
  container = "query-me-app-superset-helm"
}

module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-container-metrics-test"
  defaults = {
    cluster : local.cluster
    anomaly_detection : true
  }
  rows = [
    [{ type : "text/title", text : "Superset" }],
    [
      { type : "container/cpu", container : local.container },
      { type : "container/memory", container : local.container },
      { type : "container/network", container : local.container },
      { type : "container/network-in", container : local.container }
    ],
    [
      { type : "container/network-out", container : local.container },
      { type : "container/restarts", container : local.container, },
      { type : "container/replicas", container : local.container, },
    ],
  ]
}
