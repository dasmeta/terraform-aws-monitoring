data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "archive_file" "lambda_code_zip_teams" {
  type        = "zip"
  source_file = local.lambda_function_file_path_teams
  output_path = local.lambda_function_output_path_teams
}

data "archive_file" "lambda_code_zip_slack" {
  type        = "zip"
  source_file = local.lambda_function_file_path_slack
  output_path = local.lambda_function_output_path_slack
}
