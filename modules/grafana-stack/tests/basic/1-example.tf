module "this" {
  source = "../../"

  host                  = "grafana.sb-ak.proalpha.dev"
  s3_bucket_prefix      = "sb-ak-grafana"
  eks_oidc_provider_arn = "arn:aws:iam::xxxxxxxxxx:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/xxxxxxxxxxxxxxxxxx"
  adminPassword         = "sadADas24das"
}
