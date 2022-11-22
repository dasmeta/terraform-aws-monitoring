locals {
  subscriptions = concat( # email
    [for endpoint in var.email_addresses : {
      endpoint              = endpoint,
      protocol              = "email",
      dead_letter_queue_arn = try(module.dead_letter_queue[0].queue_arn, null)
    }],
    [for endpoint in var.phone_numbers : { # sms
      endpoint              = endpoint,
      protocol              = "sms",
      dead_letter_queue_arn = try(module.dead_letter_queue[0].queue_arn, null)
    }],
    [for endpoint in var.web_endpoints : { # https webhook endpoints
      endpoint              = endpoint,
      protocol              = "https",
      dead_letter_queue_arn = try(module.dead_letter_queue[0].queue_arn, null)
    }]
  )
}
