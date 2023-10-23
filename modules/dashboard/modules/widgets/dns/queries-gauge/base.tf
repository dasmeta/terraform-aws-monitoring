data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Queries"

  region = "us-east-1"

  defaults = {
    MetricNamespace = "AWS/Route53"
    HostedZoneId    = local.zone_id
  }

  view    = "gauge"
  stat    = "Sum"
  yAxis   = { left = { min = 0, max = 500 } }
  stacked = false

  annotations = {
    horizontal = [
      [
        {
          color : "#FF0F3C",
          label : "Acceptable",
          value : 100
        },
        {
          value : 50,
          label : "Acceptable"
        }
      ],
      {
        color : "#FF774D",
        label : "Min",
        value : 50,
        fill : "below"
      },
      [
        {
          color : "#FFC300",
          label : "Good",
          value : 200
        },
        {
          value : 100,
          label : "Good"
        }
      ],
      {
        color : "#3ECE76",
        label : "Great",
        value : 200,
        fill : "above"
      }
    ]
  }
  period = var.period

  metrics = [
    { MetricName = "DNSQueries" },
  ]
}
