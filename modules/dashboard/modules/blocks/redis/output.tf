output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "Redis (${var.name})", link_to_jump = "https://${var.region}.console.aws.amazon.com/elasticache/home?region=${var.region}#/redis/${var.name}" }
    ],
    [
      { type : "redis/cpu", redis_name : var.name },
      { type : "redis/memory", redis_name : var.name },
      { type : "redis/capacity", redis_name : var.name },
      { type : "redis/cache-hit", redis_name : var.name },
    ],
    [
      { type : "redis/current-connections", redis_name : var.name },
      { type : "redis/new-connections", redis_name : var.name },
      { type : "redis/network", redis_name : var.name },
      { type : "redis/latency", redis_name : var.name },
    ]
  ]
}
