# AWS GuardDuty basic example
# This example enables AWS GuardDuty with default settings

module "guardduty" {
  source = "../../"

  # GuardDuty will be enabled with default settings:
  # - Finding publishing frequency: FIFTEEN_MINUTES
  # - S3 protection: enabled
  # - Kubernetes protection: enabled
  # - Malware protection: enabled
}
