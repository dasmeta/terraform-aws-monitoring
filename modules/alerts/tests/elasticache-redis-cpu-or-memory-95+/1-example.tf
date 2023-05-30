module "this" {
  source    = "../../"
  sns_topic = aws_sns_topic.tets_topic_for_alarm_actions.name

  alerts = [
    {
      name                = "test-redis Redis cluster test-redis-001 node cpu state changed. Check Current State in notification for details"
      description         = "Redis Cluster CPU monitoring"
      source              = "AWS/ElastiCache/CPUUtilization"
      comparison_operator = "gt"
      statistic           = "avg"
      threshold           = 95
      filters = {
        CacheClusterId = "test-redis-001"
      }
    },
    {
      name                = "test-redis Redis cluster test-redis-001 node memory state changed. Check Current State in notification for details"
      description         = "Redis Cluster Memory monitoring"
      source              = "AWS/ElastiCache/DatabaseMemoryUsagePercentage"
      comparison_operator = "gt"
      statistic           = "avg"
      threshold           = 95
      filters = {
        CacheClusterId = "test-redis-001"
      }
    }
  ]
}
