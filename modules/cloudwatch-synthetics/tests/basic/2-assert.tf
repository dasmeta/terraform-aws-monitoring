resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({ example_token = "not-a-real-secret" })

  lifecycle {
    precondition {
      condition     = length(module.primary.canary_arns) == 2 && length(module.secondary.canary_arns) == 1
      error_message = "Module instances must create the expected neutral canaries."
    }

    precondition {
      condition     = length(module.primary.alarm_arns) == 2 && length(module.secondary.alarm_arns) == 1
      error_message = "Module instances must create enabled failure alarms."
    }

    precondition {
      condition = alltrue([
        for version_id in concat(values(module.primary.script_object_version_ids), values(module.secondary.script_object_version_ids)) : version_id != null && version_id != ""
      ])
      error_message = "Each generated source package must be uploaded as a versioned S3 object."
    }

    precondition {
      condition = alltrue([
        for key, object_key in module.primary.script_object_keys :
        startswith(object_key, "scripts/") && endswith(object_key, "/bundle.zip")
      ])
      error_message = "Each generated package must use the generic script object key layout."
    }
  }
}

resource "aws_secretsmanager_secret_version" "customer_key" {
  secret_id     = aws_secretsmanager_secret.customer_key.id
  secret_string = jsonencode({ example_token = "not-a-real-secret" })
}
