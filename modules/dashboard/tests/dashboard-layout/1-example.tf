# this is going to create dashboard with container widgets
module "dashboard-to-test-layout" {
  source = "../../"

  name = "dashboard-to-test-layout"
  rows = [
    [
      {
        type : "text/title"
        text : "smm (block 1)"
      }
    ],
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
    ],
    [
      {
        type : "text/title"
        text : "smm 2 (block 2)"
      }
    ],
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
      }
    ]
  ]
}
