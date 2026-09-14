data "aws_secretsmanager_secret" "canary" {
  for_each = var.canaries

  name = each.value.secret_name
}

data "aws_kms_key" "secret_encryption" {
  for_each = var.canaries

  key_id = coalesce(
    data.aws_secretsmanager_secret.canary[each.key].kms_key_id,
    "alias/aws/secretsmanager",
  )
}

data "aws_sns_topic" "alerts" {
  name = var.sns_topic_name
}
