# TODO: it is most possible that we can use same buckets for loki and tempo as storages, by having custom prefix(parent dir) for them, please check this possibility
module "loki_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.8.2"

  bucket                  = local.loki_bucket
  ignore_public_acls      = false # TODO: check if this hardcoded permissions need to be passed as variable or changed
  restrict_public_buckets = false
  block_public_acls       = false
  block_public_policy     = false
}

module "tempo_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.8.2"

  bucket                  = local.tempo_bucket
  ignore_public_acls      = false
  restrict_public_buckets = false
  block_public_acls       = false
  block_public_policy     = false
}

resource "aws_iam_policy" "this" {
  name = "grafana-stack-s3-access-${var.s3_bucket_prefix}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:ListObjects",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutLifecycleConfiguration",
          "s3:PutObjectAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::${module.loki_bucket.s3_bucket_id}",
          "arn:aws:s3:::${module.loki_bucket.s3_bucket_id}/*",
          "arn:aws:s3:::${module.tempo_bucket.s3_bucket_id}",
          "arn:aws:s3:::${module.tempo_bucket.s3_bucket_id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "this" {
  name = "grafana-stack-s3-access-${var.s3_bucket_prefix}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.eks_oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${regex("^arn:aws:iam::[0-9]+:oidc-provider/(.*)$", var.eks_oidc_provider_arn)[0]}:aud": "sts.amazonaws.com",
          "${regex("^arn:aws:iam::[0-9]+:oidc-provider/(.*)$", var.eks_oidc_provider_arn)[0]}:sub": "system:serviceaccount:${var.namespace}:${local.service_account_name}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}
