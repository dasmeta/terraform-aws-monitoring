# module "cloudfront_combined" {
#   source = "./modules/widgets/cloudfront/combined"

#   count = length(local.cloudfront_combined)

#   # coordinates
#   coordinates = local.cloudfront_combined[count.index].coordinates

#   # stats
#   period = local.cloudfront_combined[count.index].period

#   # container
#   distribution = local.cloudfront_combined[count.index].distribution
# }

# module "cloudfront_error_rate" {
#   source = "./modules/widgets/cloudfront/error-rate"

#   count = length(local.cloudfront_error_rate)

#   # coordinates
#   coordinates = local.cloudfront_error_rate[count.index].coordinates

#   # stats
#   period = local.cloudfront_error_rate[count.index].period

#   # container
#   distribution = local.cloudfront_error_rate[count.index].distribution
# }

# module "cloudfront_errors" {
#   source = "./modules/widgets/cloudfront/errors"

#   count = length(local.cloudfront_errors)

#   # coordinates
#   coordinates = local.cloudfront_errors[count.index].coordinates

#   # stats
#   period = local.cloudfront_errors[count.index].period

#   # container
#   distribution = local.cloudfront_errors[count.index].distribution
# }

# module "cloudfront_requests" {
#   source = "./modules/widgets/cloudfront/requests"

#   count = length(local.cloudfront_requests)

#   # coordinates
#   coordinates = local.cloudfront_requests[count.index].coordinates

#   # stats
#   period = local.cloudfront_requests[count.index].period

#   # container
#   distribution = local.cloudfront_requests[count.index].distribution
# }

# module "cloudfront_traffic_bytes" {
#   source = "./modules/widgets/cloudfront/traffic-bytes"

#   count = length(local.cloudfront_traffic_bytes)

#   # coordinates
#   coordinates = local.cloudfront_traffic_bytes[count.index].coordinates

#   # stats
#   period = local.cloudfront_traffic_bytes[count.index].period

#   # container
#   distribution = local.cloudfront_traffic_bytes[count.index].distribution
# }
