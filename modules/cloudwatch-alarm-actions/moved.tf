# State migration for fallback-topic module
#
# Changed the module to use `count` instead of conditional `create` parameter:
# - Old: module.fallback-topic (no count, create parameter was conditional)
# - New: module.fallback-topic[0] (with count, module is conditionally created)
#
# Also changed the condition from OR to AND logic:
# - Old: create if (fallback_subscriptions > 0) OR (teams/slack/servicenow webhooks > 0)
# - New: create if (fallback_subscriptions > 0) AND (teams/slack/servicenow webhooks > 0)
#
moved {
  from = module.fallback-topic
  to   = module.fallback-topic[0]
}
