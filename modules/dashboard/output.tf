# output "cpu" {
#   value = module.splite_config.cpu
# }

# output "restarts" {
#   value = module.splite_config.restarts
# }

# output "memory" {
#   value = module.splite_config.memory
# }

# output "network" {
#   value = module.splite_config.network
# }

# output "widget" {
#   value = module.container_cpu_widget.widget
# }

# output "widget_memory" {
#   value = module.container_memory_widget.widget
# }

output "traffic_2xx" {
  value = local.merged_config
}

output "merged_config" {
  value = module.splite_config.all_widget
}
