# Amazon Macie v2 basic example
# This example enables Amazon Macie v2

module "macie" {
  source = "../../"

  # Macie will be enabled for the account
  # Automatically scans S3 buckets across all regions
}
