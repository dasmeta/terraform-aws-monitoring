module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Restarts / ${var.container}"

  metrics = [
    { "ContainerInsights" : "pod_number_of_container_restarts", "Style" : { "color" : "#d62728" } }
  ]
}
