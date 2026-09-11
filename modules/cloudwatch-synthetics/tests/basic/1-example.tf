module "this" {
  source = "../../"

  name_prefix                   = "example-basic"
  sns_topic_arn                 = aws_sns_topic.alerts.arn
  artifact_bucket_force_destroy = true

  canaries = {
    fixture-one = {
      script_zip_path = data.archive_file.fixture.output_path
      secret_arn      = aws_secretsmanager_secret.example.arn
    }
    fixture-two = {
      script_zip_path = data.archive_file.fixture.output_path
      secret_arn      = aws_secretsmanager_secret.example.arn
    }
  }

  default_tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
