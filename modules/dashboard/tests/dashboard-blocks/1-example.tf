module "this" {
  source = "../.."

  name = "test-dashboard"

  rows = [
    # {
    #   "blocks" : [
    #     { "description" : "fcghjkguftgctzguhi", "logo" : "logo/source.png", "name" : "Pushmetrics", "type" : "product" },
    #     { "balancer" : "esiminch", "type" : "sla" }
    #   ],
    #   "type" : "row"
    # },
    # { "name" : "pushmetrics.io", "type" : "block/dns" },
    # { "name" : "esiminch", "type" : "block/cdn" },
    # { "name" : "esiminch", "type" : "block/alb" },
    # { "name" : "superset", "type" : "block/service" },
    # { "name" : "superset", "type" : "block/service" },
    # { "name" : "superset", "type" : "block/service" },
    [{ "name" : "rds1", "type" : "block/rds" }],
    [{ "name" : "superset1", "type" : "service" }],
    [{ "name" : "sqs1", "type" : "block/sqs" }],
    [{ "name" : "superset2", "type" : "service" }],
    [{ "name" : "rds2", "type" : "block/rds" }],
    [{ "name" : "sqs1", "type" : "block/sqs" }],
    [{ "name" : "superset3", "type" : "service" }],
    [{ "name" : "sqs1", "type" : "block/sqs" }],
    # { "name" : "rds-name", "type" : "block/footer" }
  ]
}


# module "this" {
#   source = "../.."

#   name = "test-dashboard"

#   rows = [
#     {
#       "blocks" : [
#         { "description" : "fcghjkguftgctzguhi", "logo" : "logo/source.png", "name" : "Pushmetrics", "type" : "product" },
#         { "balancer" : "esiminch", "type" : "sla" }
#       ],
#       "type" : "row"
#     },
#     { "name" : "pushmetrics.io", "type" : "block/dns" },
#     { "name" : "esiminch", "type" : "block/cdn" },
#     { "name" : "esiminch", "type" : "block/alb" },
#     { "name" : "superset", "type" : "block/service" },
#     { "name" : "superset", "type" : "block/service" },
#     { "name" : "superset", "type" : "block/service" },
#     { "name" : "superset", "type" : "block/service" },
#     { "name" : "rds-name", "type" : "block/rds" },
#     { "name" : "rds-name", "type" : "block/footer" }
#   ]
# }
