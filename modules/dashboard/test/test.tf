locals {
  new_dashboards_structure = {
    name : "Dashboard_name",
    defaults : {
      period : 300
      namespace : "default"
      clustername : "dasmeta-test-new3"
      width : 6
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
        },
        {
          type : "container/network",
          container : "nginx",
        }
      ],
      [
        {
          type : "text",
          content : "ELB"
        }
      ],
      [
        {
          type : "traffic/5xx"
          loadbalancer : "app/fa5487/cd9b9f"
        },
        {
          type : "traffic/4xx"
          loadbalancer : "app/fa5487/cd9b9f"
        },
        {
          type : "traffic/2xx"
          loadbalancer : "app/fa5487/cd9b9f"
        }
      ]
    ]
  }
  yaml_decode = yamldecode(file("./test.yaml"))
}


module "dashboard" {
  source = "../"

  // Yaml values
  rows     = local.yaml_decode["rows"]
  defaults = local.yaml_decode["defaults"]
  name     = local.yaml_decode["name"]

  // Local values
  # rows     = local.new_dashboards_structure["rows"]
  # defaults = local.new_dashboards_structure["defaults"]
  # name     = local.new_dashboards_structure["name"]
}

# output "yaml" {
#   value = yamldecode(file("/Users/juliaaghamyan/Desktop/dasmeta/terraform-aws-monitoring/modules/dashboard/test/test.yaml"))
# }

output "merged_config" {
  value = module.dashboard.merged_config
}
