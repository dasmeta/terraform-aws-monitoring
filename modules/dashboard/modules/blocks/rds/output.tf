variable "name" {
  type        = string
  description = "description"
}

output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "RDS (${var.name})", link_to_jump = "https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#database:id=${var.name};is-cluster=false;tab=connectivity" }
    ],
    [
      { type : "rds/free-storage", rds_name : var.name },
      { type : "rds/connections", rds_name : var.name, db_max_connections_count : 100 },
      { type : "rds/performance", rds_name : var.name },
      { type : "rds/network", rds_name : var.name },
    ],
    [
      { type : "rds/cpu", rds_name : var.name, anomaly_detection : true },
      { type : "rds/iops", rds_name : var.name },
      { type : "rds/swap", rds_name : var.name },
      { type : "rds/disk-latency", rds_name : var.name },
    ]
  ]
}
