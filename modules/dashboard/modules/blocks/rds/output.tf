output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "Database (${var.name})", link_to_jump = "https://${var.region}.console.aws.amazon.com/rds/home?region=${var.region}#database:id=${var.name};is-cluster=false;tab=connectivity" }
    ],
    [
      { type : "rds/free-storage", rds_name : var.name },
      { type : "rds/connections", rds_name : var.name, db_max_connections_count : var.db_max_connections_count },
      { type : "rds/disk-latency", rds_name : var.name },
      { type : "rds/network", rds_name : var.name },
    ],
    [
      { type : "rds/cpu", rds_name : var.name, anomaly_detection : true },
      { type : "rds/iops", rds_name : var.name },
      { type : "rds/swap", rds_name : var.name },
      # { type : "rds/performance", rds_name : var.name },
    ]
  ]
}
