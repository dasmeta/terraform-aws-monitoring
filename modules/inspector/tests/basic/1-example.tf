# AWS Inspector v2 basic example
# This example enables AWS Inspector v2 with default settings

module "inspector" {
  source = "../../"

  # Inspector will be enabled with default settings:
  # - Resource types: EC2, ECR, LAMBDA
  # - Automatically scans all regions in the account
}
