resource "aws_s3_bucket_notification" "incoming" {
  for_each = { for bucket in var.bucket_name : bucket => bucket }
  bucket   = each.value

  lambda_function {
    lambda_function_arn = module.lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:Put"]
  }

  depends_on = [aws_lambda_permission.s3_permission_to_trigger_lambda]
}

resource "aws_lambda_permission" "s3_permission_to_trigger_lambda" {
  for_each = { for bucket in var.bucket_name : bucket => bucket }

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${each.value}"
}
