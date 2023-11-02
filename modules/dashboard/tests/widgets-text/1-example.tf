module "this" {
  source = "../../"
  name   = "dashboard-with-text-widget"
  rows = [
    [
      { type : "text/title", text : "Container" }
    ],
    [
      { type : "text/title-with-link", text : "DNS Zone", link_to_jump = "https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=us-east-1#ListRecordSets/Z08123124QEWFDQWE12421" }
    ],
    [
      { type : "text/title-with-link", text : "CDN (CloudFront)", link_to_jump = "https://us-east-1.console.aws.amazon.com/cloudfront/v3/home?region=us-east-1#/distributions/E234SAF234231SFAF" }
    ],
    [
      { type : "text/title-with-link", text : "RDS (prod-db-1)", link_to_jump = "https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#database:id=prod-db-1;is-cluster=false;tab=connectivity" }
    ],
  ]
}
