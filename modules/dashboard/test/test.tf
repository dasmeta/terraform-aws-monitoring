locals {
  new_dashboards_structure = [
    {
      name : "Dashboard_name",
      defaults : {
        period : 300
        namespace : "default"
        clustername : "dasmeta-test-new3"
        width : 8
        height : 5
      }
      rows : [
        [
          {
            type : "text",
            content : "Nginx"
          }
        ],
        [
          {
            type : "container/cpu",
            period : 300,
            container : "nginx",
          },
          {
            type : "container/memory",
            container : "nginx",
          },
          {
            type : "container/restarts",
            container : "nginx",
          }
        ],
        [
          {
            type : "text",
            content : "Row title2"
          }
        ],
        [
          {
            type : "container/network",
            container : "nginx",
          },
          {
            type : "container/traffic",
            container : "nginx"
          }
        ]
      ]
    }
  ]
}


module "dashboards" {
  source     = "../"
  dashboards = yamldecode(file("./test.yaml"))
  # dashboards = local.new_dashboards_structure
}

output "yaml" {
  value = yamldecode(file("/Users/juliaaghamyan/Desktop/dasmeta/terraform-aws-monitoring/modules/dashboard/test/test.yaml"))
}
# output "traffic_2xx" {
#   value = module.dashboards.traffic_2xx
# }
# output "memory" {
#   value = module.dashboards.memory
# }
# output "network" {
#   value = module.dashboards.network
# }
# output "restarts" {
#   value = module.dashboards.restarts
# }
# output "disk" {
#   value = module.dashboards.disk
# }
# output "traffic" {
#   value = module.dashboards.traffic
# }
# output "widget" {
#   value = module.dashboards.widget
# }

# output "widget_memory" {
#   value = module.dashboards.widget_memory
# }

# output "widget_network" {
#   value = module.dashboards.widget_network
# }

output "merged_config" {
  value = module.dashboards.merged_config
}
