resource "aws_securityhub_account" "sec-hub" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_action_target" "sec-hub-target" {
  name        = var.name
  identifier  = "SendToTargets"
  description = "This  is custom action sends selected findings to Targets"

  depends_on = [
    aws_securityhub_account.sec-hub
  ]
}

resource "aws_securityhub_finding_aggregator" "sec-hub-aggregator" {
  linking_mode = var.link_mode

  count = var.enable_security_hub_finding_aggregator ? 1 : 0

  depends_on = [
    aws_securityhub_account.sec-hub
  ]
}

resource "aws_securityhub_member" "account" {
  for_each = var.securityhub_members

  account_id = each.value
  email      = each.key
  invite     = true
}
