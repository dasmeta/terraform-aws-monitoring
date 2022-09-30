resource "test_assertions" "api_url" {
  component = "cloudwatch-dashboard-basic"

  equal "scheme" {
    description = "As module does not have any output and data just make sure the case runs."
    got         = "all good"
    want        = "all good"
  }

  # check "port_number" {
  #   description = "default port number is 8080"
  #   condition   = can(regex(":8080$", local.api_url_parts.authority))
  # }
}
