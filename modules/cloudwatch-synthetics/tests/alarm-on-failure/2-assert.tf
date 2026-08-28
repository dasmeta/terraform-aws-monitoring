# resource "test_assertions" "alarm_on_failure" {
#   component = "cloudwatch-synthetics-alarm-on-failure"
#
#   equal "alarm_created" {
#     description = "Canary failure alarm is created and wired to SNS"
#     got         = length(module.this.alarm_arns)
#     want        = 1
#   }
# }
