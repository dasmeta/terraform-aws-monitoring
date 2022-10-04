# // Container
module "container_cpu_widget" {
  source = "./modules/widgets/container/cpu"

  count = length(local.widget_config["container/cpu"])

  # container
  container = local.widget_config["container/cpu"][count.index].container
  cluster   = local.widget_config["container/cpu"][count.index].cluster
  namespace = local.widget_config["container/cpu"][count.index].namespace

  # stats
  period = local.widget_config["container/cpu"][count.index].period

  # coordinates
  # row : row_number,
  # column : column_number,
  # row_count : length(var.rows),
  # column_count : length(row)
  coordinates = {
    height = local.widget_config["container/cpu"][count.index].height
    width  = local.widget_config["container/cpu"][count.index].width
    x      = local.widget_config["container/cpu"][count.index].column
    y      = local.widget_config["container/cpu"][count.index].row
  }

  #         {
  #           type : "container/cpu",
  #           period : 300,
  #           container : "nginx",
  #         },
  #         {
  #           type : "container/memory",
  #           container : "nginx",
  #         },
  #         {
  #           type : "container/restarts",
  #           container : "nginx",
  #         },
  #         {
  #           type : "container/network",
  #           container : "nginx",
  #         }
}

# module "container_memory_widget" {
#   source = "./modules/widgets/container/memory"

#   memory = local.widget_config["container/memory"]
#   # default = var.defaults
# }

# module "container_network_widget" {
#   source = "./modules/widgets/container/network"

#   network = local.widget_config["container/network"]
#   # default = var.defaults
# }

# module "container_restarts_widget" {
#   source = "./modules/widgets/container/restart"

#   restart = local.widget_config["container/restarts"]
#   # default = var.defaults
# }
