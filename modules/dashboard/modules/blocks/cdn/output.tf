output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "CDN (CloudFront)", link_to_jump = "https://us-east-1.console.aws.amazon.com/cloudfront/v3/home?region=us-east-1#/distributions/${var.cdn_id}" }
    ],
    [
      { type : "cloudfront/requests", distribution : var.cdn_id },
      { type : "cloudfront/errors", distribution : var.cdn_id },
      { type : "cloudfront/error-rate", distribution : var.cdn_id },
      { type : "cloudfront/traffic-bytes", distribution : var.cdn_id },
    ],
  ]
}
