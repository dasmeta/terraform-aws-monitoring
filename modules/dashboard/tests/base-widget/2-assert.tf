locals {
  rows = [
    [
      {
        type = "a"
      },
      {
        type = "b"
      },
      {
        type = "b"
      },
      {
        type = "c"
      }
    ],
    [
      {
        type = "a"
      },
      {
        type = "d"
      },
      {
        type = "e"
      },
      {
        type = "c"
      }
    ]
  ]
  result = { for key, item in flatten(local.rows) : item.type => item... }
  expected_result = {
    a = [{ type = "a" }]
    b = [{ type = "b" }]
    c = [{ type = "c" }]
  }
}

resource "test_assertions" "api_url" {
  component = "cloudwatch-dashboard-basic"

  equal "scheme" {
    description = "As module does not have any output and data just make sure the case runs. Probably can be thrown away."
    got         = local.result
    want        = local.expected_result
  }
}
