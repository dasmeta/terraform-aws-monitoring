resource "aws_securityhub_account" "sec-hub" {
}

resource "aws_securityhub_action_target" "sec-hub-target" {
  depends_on  = [aws_securityhub_account.sec-hub]
  name        = "Send-to-sns"
  identifier  = "SendToSns"
  description = "This  is custom action sends selected findings to sns"
}

resource "aws_securityhub_finding_aggregator" "sec-hub-aggregator" {
  linking_mode = "ALL_REGIONS"

  depends_on = [aws_securityhub_account.sec-hub]
}