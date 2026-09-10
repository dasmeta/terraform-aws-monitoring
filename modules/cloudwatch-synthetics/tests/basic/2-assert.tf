# resource "test_assertions" "basic" {
#   component = "cloudwatch-synthetics-basic"
#
#   equal "canary_count" {
#     description = "Module creates one canary per map entry"
#     got         = length(module.this.canary_arns)
#     want        = 2
#   }
# }
