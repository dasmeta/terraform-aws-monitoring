module "s3-to-lambda" {
  source = "../../"

  name        = "CloudwatchtoLambda"
  bucket_name = "aws-cloudtrail-logs-753273213401-85b50618"

  lambda_configs = {
    environment_variables = {
      url = "https://4eb8-195-250-69-234.ngrok-free.app/aws"
    }
  }
}
