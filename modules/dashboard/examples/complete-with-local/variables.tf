variable "dashboard_name" {
  type    = string
  default = "Dashboard_name"
}

variable "default_period" {
  type    = number
  default = 300
}

variable "default_namespace" {
  type    = string
  default = "default"
}

variable "default_clustername" {
  type    = string
  default = "dasmeta-test-new3"
}

variable "default_width" {
  type    = number
  default = 6
}

variable "default_height" {
  type    = number
  default = 5
}

variable "rows" {
  type = any
  default = [
    [
      // ROW1
      {
        type : "text",
        name : "Nginx"
      }
    ],
    // ROW2
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
    // ROW3
    [
      {
        type : "text",
        content : "ELB"
      }
    ],
    // ROW4
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
    ],
    // ROW5
    [
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        container : "rpc-app-cont"
      },
      {
        type : "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
      }
    ]
  ]
}
