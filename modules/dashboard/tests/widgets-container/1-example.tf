module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-container-metrics-test"
  rows = [
    [
      {
        type : "container/cpu",
        period : 300,
        container : "smm",
        cluster : "dev"
      },
      {
        type : "container/memory",
        period : 300,
        container : "smm",
        cluster : "dev"
      },
      {
        type : "container/network",
        period : 300,
        container : "smm",
        cluster : "dev",
      },
      {
        type : "container/restarts",
        period : 300,
        container : "smm",
        cluster : "dev",
      },
      {
        type : "container/replicas",
        period : 300,
        container : "smm",
        cluster : "dev",
        x : 20,
        y : 20
      },
    ]
  ]
}
