resource "aws_securityhub_account" "sec-hub" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_action_target" "sec-hub-target" {
  depends_on  = [aws_securityhub_account.sec-hub]
  name        = var.securityhub_action_target_name
  identifier  = "SendToSns"
  description = "This  is custom action sends selected findings to sns"
}

resource "aws_securityhub_finding_aggregator" "sec-hub-aggregator" {
  linking_mode = var.link_mode

  count = var.enable_security_hub_finding_aggregator ? 1 : 0

  depends_on = [aws_securityhub_account.sec-hub]
}
