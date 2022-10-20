module "dashboard-with-application-metrics" {
  source = "../../"
  name   = "dashboard-with-application-metrics"
  rows = [
    [
      {
        type      = "application"
        title     = "CertManager app metrics"
        cluster   = "sandbox"
        namespace = "cert-manager"
        container = "cert-manager"
        metrics = [
          "certmanager_certificate_expiration_timestamp_seconds",
        ]
        custom_dimension_metrics = [
          {
            MetricName = "certmanager_certificate_renewal_timestamp_seconds"
            status     = "failed"
          },
          {
            MetricName = "certmanager_certificate_ready_status"
            state      = "failed"
          }
        ]
      }
    ]
  ]
}
