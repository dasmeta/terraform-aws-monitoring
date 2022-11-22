locals {
  dashboard_title = "${data.aws_caller_identity.project.account_id}-${var.name}"
}


resource "aws_cloudwatch_dashboard" "dashboards" {
  count = var.platform == "cloudwatch" ? 1 : 0

  dashboard_name = local.dashboard_title
  dashboard_body = <<EOF
  {
    "widgets": ${jsonencode(local.widget_result)}
  }
  EOF

}
# TODO: Resource and Provider comented, because all clients doesn't use grafana dashboard. 
#       We should be create new module for grafana dashboard

# resource "grafana_dashboard" "metrics" {
#   count = var.platform == "grafana" ? 1 : 0

#   config_json = jsonencode({
#     uid                  = try(random_string.grafana_dashboard_id[0].result, null)
#     title                = local.dashboard_title
#     style                = "dark"
#     timezone             = "browser"
#     editable             = true
#     schemaVersion        = 35
#     fiscalYearStartMonth = 0
#     graphTooltip         = 0
#     links                = []
#     liveNow              = false
#     annotations          = {}
#     refresh              = "5s"
#     tags                 = []
#     templating = {
#       list = []
#     }
#     time = {
#       from = "now-6h"
#       to   = "now"
#     }
#     timepicker = {}
#     weekStart  = ""
#     panels     = local.widget_result
#   })
# }

# resource "random_string" "grafana_dashboard_id" {
#   count = var.platform == "grafana" ? 1 : 0

#   length  = 16
#   special = false
# }
