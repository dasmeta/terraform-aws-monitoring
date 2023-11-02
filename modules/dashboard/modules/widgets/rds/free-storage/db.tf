data "aws_db_instance" "database" {
  db_instance_identifier = var.rds_name
}

locals {
  max_allocated_storage = data.aws_db_instance.database.allocated_storage
}
