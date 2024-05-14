# this is going to create redis dashboard
locals {
  redis = "redis-cache"
}

module "dashboard_redis" {
  source = "../../"

  name = "dashboard-with-redis-metrics-test"
  rows = [
    [
      { type : "text/title", text : "Redis (redis-cache))" }
    ],
    [
      { type : "redis/cpu", redis_name : local.redis },
      { type : "redis/memory", redis_name : local.redis },
      { type : "redis/capacity", redis_name : local.redis },
      { type : "redis/cache-hit", redis_name : local.redis },
    ],
    [
      { type : "redis/current-connections", redis_name : local.redis },
      { type : "redis/new-connections", redis_name : local.redis },
      { type : "redis/network", redis_name : local.redis },
      { type : "redis/latency", redis_name : local.redis },
    ]
  ]
}
