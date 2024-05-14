module "expression_alert" {
  source = "../../"

  sns_topic = aws_sns_topic.tets_topic_for_alarm_actions.name
  alerts = [
    {
      name   = "WAF: High Volume of Blocked Requests Across All Rules on waf-prod"
      source = "AWS/WAFV2/BlockedRequests"
      filters = {
        WebACL = "prod-waf"
        Rule   = "ALL",
        Region = data.aws_region.current.name
      }
      period                 = 60
      statistic              = "count"
      threshold              = 100
      fill_insufficient_data = true
    },
    {
      name   = "WAF: High Blocks for Known Bad Inputs on waf-prod"
      source = "AWS/WAFV2/BlockedRequests"
      filters = {
        WebACL = "prod-waf"
        Rule   = "AWS-AWSManagedRulesKnownBadInputsRuleSet",
        Region = data.aws_region.current.name
      }
      period    = 60
      statistic = "count"
      threshold = 100
    },
  ]
}
