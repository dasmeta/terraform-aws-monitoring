# resource "test_assertions" "secret_redaction" {
#   component = "cloudwatch-synthetics-secret-redaction"
#
#   equal "canary_created" {
#     description = "Forced-failure canary is provisioned for redaction scenario"
#     got         = length(module.this.canary_arns)
#     want        = 1
#   }
# }
