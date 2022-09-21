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

output "text" {
  value = flatten(local.text)
}
