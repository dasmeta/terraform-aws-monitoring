output "cpu" {
  value = module.splite_config["Dashboard_name"].cpu
}

output "traffic" {
  value = module.splite_config["Dashboard_name"].traffic
}

output "disk" {
  value = module.splite_config["Dashboard_name"].disk
}

output "restarts" {
  value = module.splite_config["Dashboard_name"].restarts
}

output "memory" {
  value = module.splite_config["Dashboard_name"].memory
}

output "network" {
  value = module.splite_config["Dashboard_name"].network
}

output "widget" {
  value = module.container_cpu_widget["Dashboard_name"].widget
}

output "widget_memory" {
  value = module.container_memory_widget["Dashboard_name"].widget
}

output "widget_network" {
  value = module.container_network_widget["Dashboard_name"].widget
}

output "merged_config" {
  value = local.merged_config
}
