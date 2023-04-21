resource "helm_release" "grafana_stack" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  chart            = "${path.module}/helm/grafana-stack"

  values = [
    templatefile("${path.module}/resources/values.yaml.tftpl", {
      host                     = var.host,
      loki_bucket              = module.loki_bucket.s3_bucket_id,
      tempo_bucket             = module.tempo_bucket.s3_bucket_id,
      region                   = data.aws_region.current.name
      service_account_name     = local.service_account_name
      adminPassword            = var.adminPassword
      prometheusRemoteWriteUrl = "http://${var.name}-prometheus-server.${var.namespace}:80/api/v1/write"
    })
  ]

  depends_on = [
    kubernetes_service_account.grafana_stack
  ]
}

resource "kubernetes_service_account" "grafana_stack" {
  metadata {
    name      = local.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
}
