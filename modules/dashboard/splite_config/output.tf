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

output "disk" {
  value = flatten(local.disk)
}

output "traffic" {
  value = flatten(local.traffic)
}

output "text" {
  value = flatten(local.text)
}
