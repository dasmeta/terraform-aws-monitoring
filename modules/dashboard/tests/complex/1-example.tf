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
  yaml_decode = yamldecode(file("${path.module}/test.yaml"))
}

module "dashboard" {
  source = "../../"

  // Yaml values
  name     = local.yaml_decode["name"]
  defaults = local.yaml_decode["defaults"]
  rows     = local.yaml_decode["rows"]
}

output "merged_config" {
  value = module.dashboard.merged_config
}
