# this is going to create dashboard with container widgets
module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-container-metrics"
  rows = [
    [
      {
        type : "text/title"
        text : "App 1 (block 1)"
      }
    ],
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
    ],
    [
      {
        type : "text/title"
        text : "App 2 (block 2)"
      }
    ],
    [
      {
        type : "container/cpu",
        period : 300,
        container : "App 2",
        cluster : "test-cluster"
      },
      {
        type : "container/memory",
        period : 300,
        container : "App 2",
        cluster : "test-cluster"
      }
    ]
  ]
}
