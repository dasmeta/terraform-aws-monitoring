data "aws_caller_identity" "project" {
  provider = aws
}

data "aws_region" "project" {
  provider = aws
}
