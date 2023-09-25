module "dashboard-with-container-metrics" {
  source = "../../"
  name   = "dashboard-with-cloudfront-metrics"
  rows = [
    [
      {
        type : "cloudfront/combined",
        distribution : "test-distribution"
      },
      {
        type : "cloudfront/error-rate",
        distribution : "test-distribution"
      },
      {
        type : "cloudfront/errors",
        distribution : "test-distribution"
      },
      {
        type : "cloudfront/requests",
        distribution : "test-distribution"
      },
      {
        type : "cloudfront/traffic-bytes",
        distribution : "test-distribution"
      }
    ]
  ]
}
