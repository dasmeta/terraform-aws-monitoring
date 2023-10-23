data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Free Storage"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  view    = "gauge"
  yAxis   = { left = { min = 0, max = local.max_allocated_storage } }
  stacked = false

  annotations = {
    horizontal = [
      {
        color : "#fe6e73",
        label : "Too Low",
        value : 10,
        fill : "below"
      },
      [
        {
          color : "#f7db8a",
          label : "Low",
          value : 50
        },
        {
          value : 10,
          label : "Low"
        }
      ],
      [
        {
          color : "#b2df8d",
          label : "Acceptable",
          value : 50
        },
        {
          value : 100,
          label : "Acceptable"
        }
      ],
      {
        color : "#69ae34",
        label : "Good",
        value : 100,
        fill : "above"
      }
    ]
  }
  period = var.period

  metrics = [
    { MetricName = "FreeStorageSpace" },
  ]
}
