run "valid_string_concat" {
  module {
    source = "../../"
  }
  variables {
    name                       = "CloudwatchtoLambda"
    cloudwatch_log_group_names = ["aws-cloudtrail-logs-753273213401-85b50618"]

    lambda_configs = {
      environment_variables = {
        url = "https://4eb8-195-250-6etwyeywtey-4w32.ngrok-free.app/aws"
      }
    }
  }
}
