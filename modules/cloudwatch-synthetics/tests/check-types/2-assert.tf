# resource "test_assertions" "check_types" {
#   component = "cloudwatch-synthetics-check-types"
#
#   equal "canary_count" {
#     description = "All four supported check types are provisioned"
#     got         = length(module.this.canary_arns)
#     want        = 4
#   }
# }
