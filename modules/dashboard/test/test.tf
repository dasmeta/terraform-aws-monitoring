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
        {
          "row0" = [
            {
              type : "text",
              content : "Nginx"
            }
          ]
        },
        {
          "row1" = [
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
          ]
        },
        {
          "row3" = [
            {
              type : "text",
              content : "Row title2"
            }
          ]
        },
        {
          "row4" = [
            {
              type : "container/network",
              container : "nginx",
            },
            {
              type : "container/traffic",
              container : "nginx"
            }
          ]
        }
      ]
    }
  ]
}


module "dashboards" {
  source = "../"
  # dashboards = yamldecode(file("./test.yaml"))
  dashboards = local.new_dashboards_structure
}
