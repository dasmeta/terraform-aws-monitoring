module "expression_alert" {
  source = "../../"

  sns_topic = aws_sns_topic.tets_topic_for_alarm_actions.name
  alerts = [
    {
      name   = "WAF: High Volume of Blocked Requests Across All Rules on waf-prod"
      source = "AWS/WAFV2/BlockedRequests"
      filters = {
        WebACL = "waf-prod"
        Rule   = "ALL",
        Region = data.aws_region.current.name
      }
      period                 = try(var.alarms.custom_values.all.period, 60)
      statistic              = try(var.alarms.custom_values.all.statistic, "count")
      threshold              = try(var.alarms.custom_values.all.threshold, 100)
      fill_insufficient_data = true
    },
    {
      name   = "WAF: High Blocks for Known Bad Inputs on waf-prod"
      source = "AWS/WAFV2/BlockedRequests"
      filters = {
        WebACL = "waf-prod"
        Rule   = "AWS-AWSManagedRulesKnownBadInputsRuleSet",
        Region = data.aws_region.current.name
      }
      period                 = try(var.alarms.custom_values.knownbadinputsruleset.period, 60)
      statistic              = try(var.alarms.custom_values.knownbadinputsruleset.statistic, "count")
      threshold              = try(var.alarms.custom_values.knownbadinputsruleset.threshold, 100)
      fill_insufficient_data = true
    },
  ]
}
