module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Log Based / ${var.metric}"

  defaults = {}

  metrics = [
    { "ContainerInsights" : "pod_cpu_utilization", },
    { "ContainerInsights" : "pod_cpu_reserved_capacity", "Style" : { "color" : "#d62728" } }
  ]
}
