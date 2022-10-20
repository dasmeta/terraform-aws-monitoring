module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-container-metrics"

  defaults = {
    cluster = "test-cluster"
    # accountId = "12345435435"
  }
  rows = [
    [
      {
        type : "container/cpu",
        period : 300,
        container : "App 1",
        cluster : "test-cluster"
      },
      {
        type : "container/memory",
        period : 300,
        container : "App 1",
        cluster : "test-cluster"
      },
      {
        type : "container/network",
        period : 300,
        container : "App 1",
        cluster : "test-cluster"
      },
      {
        type : "container/restarts",
        period : 300,
        container : "App 1"
        accountId : "232323232323223232"
      },
    ]
  ]
}
