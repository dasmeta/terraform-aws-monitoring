variable "name" {
  type        = string
  description = "description"
}

output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "SQS (${var.name})", link_to_jump = "https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#database:id=${var.name};is-cluster=false;tab=connectivity" }
    ],
    [
      { type : "sqs/free-storage", rds_name : var.name },
      { type : "sqs/connections", rds_name : var.name, db_max_connections_count : 100 },
      { type : "sqs/performance", rds_name : var.name },
      { type : "sqs/network", rds_name : var.name },
    ],
    [
      { type : "sqs/cpu", rds_name : var.name, anomaly_detection : true },
      { type : "sqs/iops", rds_name : var.name },
      { type : "sqs/swap", rds_name : var.name },
      { type : "sqs/disk-latency", rds_name : var.name },
    ]
  ]
}
