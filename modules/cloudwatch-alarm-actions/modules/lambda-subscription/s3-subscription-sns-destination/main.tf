data "aws_s3_bucket" "this" {
  bucket = var.s3_bucket
}

resource "aws_s3_bucket_notification" "incoming" {
  bucket = data.aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:Put"]
    # filter_prefix       = "foldername"
    # filter_suffix       = ".zip"
  }

  depends_on = [aws_lambda_permission.s3_permission_to_trigger_lambda]
}

resource "aws_lambda_permission" "s3_permission_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.this.arn
}

data "aws_iam_policy_document" "destination_on_success" {
  statement {
    actions = [
      "sns:Publish",
      "sqs:SendMessage",
      "lambda:InvokeFunction",
      "events:PutEvents"
    ]
    resources = [
      var.sns_topic_arn
    ]
  }
}

resource "aws_iam_role_policy" "destination_on_success" {
  name   = "lambda-destination-sns"
  policy = data.aws_iam_policy_document.destination_on_success.json
  role   = var.role_name
}


resource "aws_lambda_function_event_invoke_config" "destination" {
  function_name = var.lambda_function_arn

  destination_config {
    on_failure {
      destination = var.sns_topic_arn
    }

    on_success {
      destination = var.sns_topic_arn
    }
  }

  depends_on = [
    aws_iam_role_policy.destination_on_success
  ]
}
