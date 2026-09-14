module "primary" {
  source = "../../"

  depends_on = [
    aws_sns_topic.alerts,
    aws_secretsmanager_secret.example,
    aws_secretsmanager_secret.customer_key,
  ]

  name_prefix                   = "example-basic"
  sns_topic_name                = aws_sns_topic.alerts.name
  artifact_bucket_force_destroy = true

  canaries = {
    fixture-default = {
      secret_name = aws_secretsmanager_secret.example.name
      source_files = {
        "python/canary.py" = "fixtures/python/canary.py"
      }
      config = {
        environment = "example"
      }
    }
    fixture-customer-key = {
      secret_name = aws_secretsmanager_secret.customer_key.name
      source_files = {
        "python/canary.py" = "fixtures/python/canary.py"
      }
      config = {
        environment = "example"
      }
    }
  }

  default_tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

module "secondary" {
  source = "../../"

  depends_on = [
    aws_sns_topic.alerts,
    aws_secretsmanager_secret.example,
  ]

  name_prefix                   = "example-secondary"
  sns_topic_name                = aws_sns_topic.alerts.name
  artifact_bucket_force_destroy = true

  canaries = {
    fixture-default = {
      secret_name = aws_secretsmanager_secret.example.name
      source_files = {
        "python/canary.py" = "fixtures/python/canary.py"
      }
      config = {
        environment = "example-secondary"
      }
    }
  }
}
