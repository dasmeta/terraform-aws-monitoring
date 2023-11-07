data "aws_route53_zone" "selected" {
  name = var.zone_name
}

output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "DNS Zone", link_to_jump = "https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=eu-central-1#ListRecordSets/${data.aws_route53_zone.selected.zone_id}" }
    ],
    [
      { type : "dns/queries-gauge", zone_name : var.zone_name },
      { type : "dns/queries-chart", width : 18, zone_name : var.zone_name },
    ],
  ]
}
