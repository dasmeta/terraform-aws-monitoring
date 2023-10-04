module "this" {
  source = "../../"

  log_group_name = aws_cloudwatch_log_group.log_group_test.name

  metrics_patterns = [
    {
      name       = "error1"
      pattern    = "ERROR"
      dimensions = {}
    },
    {
      name    = "error2"
      pattern = "{ $.ClusterName = \"*provider-test-new3*\" }"
      dimensions = {
        "ClusterName" = "$.ClusterName"
      }
    },
    {
      name       = "error3"
      pattern    = "ERROR"
      dimensions = {}
    }
  ]
}
