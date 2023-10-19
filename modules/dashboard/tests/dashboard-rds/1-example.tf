# this is going to create rds dashboard
locals {
  rds = "db-prod"
}

module "dashboard_rds" {
  source = "../../"

  name = "dashboard-with-rds-metrics-test"
  rows = [
    [
      { type : "text/title", text : "RDS (db-prod)" }
    ],
    [
      { type : "rds/cpu", rds_name : local.rds, anomaly_detection : true },
      # { type : "rds/memory", rds_name : local.rds },
      # { type : "rds/disk", rds_name : local.rds },
      { type : "rds/connections", rds_name : local.rds },
      { type : "rds/network", rds_name : local.rds },
      { type : "rds/iops", rds_name : local.rds },
    ],
    [
      { type : "rds/performance", rds_name : local.rds },
    ]
  ]
}
