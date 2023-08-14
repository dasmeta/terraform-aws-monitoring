data "aws_region" "project" {
  provider = aws.virginia
}

data "aws_caller_identity" "project" {}
