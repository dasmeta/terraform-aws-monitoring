# AWS Config basic example
# This example enables AWS Config with default settings

module "config" {
  source = "../../"

  name = "test-config"

  # Config will be enabled with default settings:
  # - Records all supported resource types
  # - Includes global resources (IAM, etc.)
  # - Creates S3 bucket automatically
  # - Delivery frequency: TwentyFour_Hours
}
