module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = var.container
  type = "log"
  view = "table"

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  query = <<-EOT
      fields @timestamp, time, `kubernetes.labels.${var.version_label}` as Version
      | filter kubernetes.namespace_name = "${var.namespace}" and `kubernetes.labels.app.kubernetes.io/name` = "${var.container}"
      | parse time /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})T(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})\.\d+/
      | display Version,concat(hour, ":", minute, " ", day, ":", month, ":", year) as `Release Date`
      | sort @timestamp asc
      | dedup Version
      | limit 5
    EOT

  sources = [var.log_group_name]
}
