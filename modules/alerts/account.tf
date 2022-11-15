data "aws_caller_identity" "logging" {
  provider = aws.logging
}

data "aws_caller_identity" "project" {
  provider = aws
}


data "aws_region" "logging" {
  provider = aws.logging
}

data "aws_region" "project" {
  provider = aws
}
