output "cpu" {
  value = flatten(local.cpu)
}

output "memory" {
  value = flatten(local.memory)
}

output "restarts" {
  value = flatten(local.restarts)
}

output "network" {
  value = flatten(local.network)
}

output "traffic_5xx" {
  value = flatten(local.traffic_5xx)
}

output "traffic_4xx" {
  value = flatten(local.traffic_4xx)
}

output "traffic_2xx" {
  value = flatten(local.traffic_2xx)
}


output "application_metric" {
  value = flatten(local.application_metric)
}

output "custom_metric" {
  value = flatten(local.custom_metric)
}

output "text" {
  value = flatten(local.text)
}

output "all_widget" {
  value = [
    // Container
    flatten(local.cpu),
    flatten(local.memory),
    flatten(local.restarts),
    flatten(local.network),


    // ALB
    flatten(local.traffic_5xx),
    flatten(local.traffic_4xx),
    flatten(local.traffic_2xx),

    // Aplication
    flatten(local.application_metric),

    // Log_Base
    flatten(local.log_base),

    // Custom
    flatten(local.custom_metric)
  ]
}
