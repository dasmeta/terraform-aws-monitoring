locals {
  yaml_decode = yamldecode(file("./test.yaml"))
}


module "dashboard" {
  source = "../../"

  // Yaml values
  rows     = local.yaml_decode["rows"]
  defaults = local.yaml_decode["defaults"]
  name     = local.yaml_decode["name"]
}
