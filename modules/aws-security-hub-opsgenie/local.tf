locals {
  lambda_function_file_path_teams = "${path.module}/src/teams/lambda.py"
  lambda_function_file_path_slack = "${path.module}/src/slack/lambda.py"

  lambda_function_hash_teams = filesha256(local.lambda_function_file_path_teams)
  lambda_function_hash_slack = filesha256(local.lambda_function_file_path_slack)

  lambda_function_output_path_teams = "${path.module}/builds/lambda-${data.aws_region.current.name}-${local.lambda_function_hash_teams}.zip"
  lambda_function_output_path_slack = "${path.module}/builds/lambda-${data.aws_region.current.name}-${local.lambda_function_hash_slack}.zip"
}
