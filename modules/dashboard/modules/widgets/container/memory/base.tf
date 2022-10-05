module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Memory / ${var.container}"

  metrics = [
    { "ContainerInsights" : "pod_memory_utilization", },
    { "ContainerInsights" : "pod_memory_reserved_capacity", "Style" : { "color" : "#d62728" } }
  ]
}
