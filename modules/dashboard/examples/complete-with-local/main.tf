locals {
  new_dashboards_structure = {
    name : var.dashboard_name,
    defaults : {
      period : var.default_period
      namespace : var.default_namespace
      clustername : var.default_clustername
      width : var.default_width
      height : var.default_height
    }
    rows : var.rows
  }
}

module "dashboard" {
  //  source = "dasmeta/monitoring/aws//modules/dashboard"
  source = "../../"


  // Local values
  rows     = local.new_dashboards_structure["rows"]
  defaults = local.new_dashboards_structure["defaults"]
  name     = local.new_dashboards_structure["name"]
}
