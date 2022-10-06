# module "dashboard-with-container-metrics" {
#   source = "../../"
#   name   = "dashboard-with-container-metrics"

#   defaults = {
#     period : 300
#   }

#   rows = [
#     [
#       {
#         type : "balancer/2xx",
#         balancer : "balancer-1"
#       },
#       {
#         type : "balancer/4xx",
#         balancer : "balancer-1"
#       },
#       {
#         type : "balancer/5xx",
#         balancer : "balancer-1"
#       }
#     ]
#   ]
# }
