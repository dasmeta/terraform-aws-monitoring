module "dashboard" {
  source = "../.."

  name = "dashboard-to-test-container-widgets"
  # defaults = local.yaml_decode["defaults"]
  rows = [
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
    ]
  ]
}
