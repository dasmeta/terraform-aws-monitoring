# this is going to create rds dashboard
locals {
  rds = "prod"
}

module "dashboard_rds" {
  source = "../../"

  name = "dashboard-with-rds-metrics-test"
  rows = [
    [
      { type : "text/title", text : "RDS (prod))" }
    ],
    [
      { type : "rds/cpu", rds_name : local.rds, anomaly_detection : true },
      # { type : "rds/memory", rds_name : local.rds },
      # { type : "rds/disk", rds_name : local.rds },
      { type : "rds/connections", rds_name : local.rds, db_max_connections_count : 100 },
      { type : "rds/network", rds_name : local.rds },
      { type : "rds/iops", rds_name : local.rds },
    ],
    [
      { type : "rds/performance", rds_name : local.rds },
      { type : "rds/free-storage", rds_name : local.rds },
      { type : "rds/swap", rds_name : local.rds },
      { type : "rds/disk-latency", rds_name : local.rds },
    ]
  ]
}
