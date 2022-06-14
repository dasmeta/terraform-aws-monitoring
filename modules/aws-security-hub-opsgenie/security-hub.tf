resource "aws_securityhub_account" "sec-hub" {
}

resource "aws_securityhub_action_target" "sec-hub-target" {
  depends_on  = [aws_securityhub_account.sec-hub]
  name        = var.securityhub-name
  identifier  = "SendToSns"
  description = "This  is custom action sends selected findings to sns"
}

resource "aws_securityhub_finding_aggregator" "sec-hub-aggregator" {
  linking_mode = var.link-mode

  depends_on = [aws_securityhub_account.sec-hub]
}
