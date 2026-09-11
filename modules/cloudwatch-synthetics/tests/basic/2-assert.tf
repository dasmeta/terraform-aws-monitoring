resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({ example_token = "not-a-real-secret" })

  lifecycle {
    precondition {
      condition     = length(module.this.canary_arns) == 2
      error_message = "Module must create one canary for each fixture entry."
    }

    precondition {
      condition     = length(module.this.alarm_arns) == 2
      error_message = "Module must create one enabled failure alarm for each fixture entry."
    }

    precondition {
      condition = alltrue([
        for version_id in values(module.this.script_object_version_ids) : version_id != null && version_id != ""
      ])
      error_message = "Each fixture ZIP must be uploaded as a versioned S3 object."
    }

    precondition {
      condition = alltrue([
        for key, object_key in module.this.script_object_keys :
        startswith(object_key, "scripts/") && endswith(object_key, "/bundle.zip")
      ])
      error_message = "Each fixture ZIP must use the generic script object key layout."
    }
  }
}
