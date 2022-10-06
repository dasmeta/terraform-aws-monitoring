# this is going to create emplty dashboard
module "base" {
  source = "../../modules/widgets/base"

  name = "Base Widget"

  region = "whatever"

  coordinates = {
    width  = 6
    height = 6
    x      = 0
    y      = 0
  }

  defaults = {
    "ClusterName" : "whatever",
    "Namespace" : "default"
    "PodName" : "test-container"
  }

  metrics = [
    { "ContainerInsights" : "pod_cpu_utilization", },
    { "ContainerInsights" : "pod_cpu_reserved_capacity", "Style" : { "color" : "#d62728" } }
  ]
}
