variable "name" {
  type        = string
  description = "Name"
}

variable "action_target_name" {
  type        = string
  default     = "SendNotification"
  description = "Name of the Security Hub action target. This name is used in EventBridge event patterns to filter manual trigger events."
}

# CloudWatch Alarm Actions configuration for Security Hub findings notifications
# This module manages SNS topics and subscriptions for sending Security Hub findings to various channels
variable "alarm_actions" {
  type = object({
    enabled                          = optional(bool, false)      # Enable/disable alarm actions module for Security Hub findings notifications
    topic_name                       = optional(string, "")       # SNS topic name for Security Hub findings. If empty, defaults to "${var.name}-security-hub-findings"
    create_topic                     = optional(bool, true)       # Whether to create a new SNS topic or use an existing one (specified by topic_name)
    topic_assign_security_hub_policy = optional(bool, true)       # Whether to assign the default security hub policy to the SNS topic
    email_addresses                  = optional(list(string), []) # List of email addresses to receive Security Hub findings notifications
    fallback_email_addresses         = optional(list(string), []) # List of fallback email addresses to receive notifications when primary channels fail
    phone_numbers                    = optional(list(string), []) # List of international formatted phone numbers (e.g., "+1234567890") to receive SMS notifications
    fallback_phone_numbers           = optional(list(string), []) # List of fallback phone numbers for SMS notifications when primary channels fail
    web_endpoints                    = optional(list(string), []) # List of webhook endpoints (e.g., Opsgenie, PagerDuty) to receive HTTP POST notifications
    fallback_web_endpoints           = optional(list(string), []) # List of fallback webhook endpoints when primary channels fail
    lambda_arns                      = optional(list(string), []) # List of Lambda function ARNs to invoke when Security Hub findings are received. Note: Lambda functions must be in the same region as the SNS topic
    fallback_lambda_arns             = optional(list(string), []) # List of fallback Lambda function ARNs when primary channels fail
    slack_webhooks = optional(list(object({
      hook_url     = string           # Slack webhook URL
      channel      = string           # Slack channel name (e.g., "#security-alerts")
      username     = string           # Bot username for Slack messages
      instance_key = optional(string) # Stable, non-secret Terraform identity for the Slack destination
    })), [])                          # List of Slack webhook configurations for sending notifications to Slack channels
    servicenow_webhooks = optional(list(object({
      domain = string                           # ServiceNow instance domain (e.g., "yourcompany.service-now.com")
      path   = string                           # API endpoint path
      user   = string                           # ServiceNow username
      pass   = string                           # ServiceNow password or API token
    })), [])                                    # List of ServiceNow webhook configurations for creating incidents in ServiceNow
    teams_webhooks = optional(list(string), []) # List of Microsoft Teams webhook URLs for sending notifications to Teams channels
    jira_config = optional(list(object({
      url            = string         # Jira instance URL (e.g., "https://yourcompany.atlassian.net")
      key            = string         # Jira project key
      user_username  = string         # Jira username
      user_api_token = string         # Jira API token
    })), [])                          # List of Jira configurations for creating tickets for Security Hub findings
    delivery_policy = optional(any, { # SNS topic delivery policy for retry and throttling configuration. Controls how SNS retries message delivery to endpoints
      "http" : {
        "defaultHealthyRetryPolicy" : {
          "minDelayTarget" : 20,
          "maxDelayTarget" : 20,
          "numRetries" : 3,
          "numMaxDelayRetries" : 0,
          "numNoDelayRetries" : 0,
          "numMinDelayRetries" : 0,
          "backoffFunction" : "linear"
        },
        "disableSubscriptionOverrides" : false,
        "defaultThrottlePolicy" : {
          "maxReceivesPerSecond" : 1
        }
      }
    })
    policy                   = optional(any, null)      # SNS topic policy (IAM policy document) for controlling access to the topic. If null, uses default policy allowing EventBridge to publish
    log_group_retention_days = optional(number, 7)      # Number of days to retain CloudWatch Logs for Lambda functions (default: 7 days)
    enable_dead_letter_queue = optional(bool, true)     # Whether to enable dead letter queue (SQS) for failed Lambda invocations
    recreate_missing_package = optional(bool, true)     # Whether to recreate missing Lambda deployment packages if they are missing locally
    log_level                = optional(string, "INFO") # Log level for Lambda functions ("DEBUG", "INFO", "WARNING", "ERROR")
    lambda_failed_alert = optional(any, {               # CloudWatch alarm configuration for monitoring Lambda function failures. Triggers when Lambda functions fail to process notifications
      period    = 60                                    # Evaluation period in seconds
      threshold = 1                                     # Number of failures to trigger alarm
      equation  = "gte"                                 # Comparison operator (greater than or equal)
      statistic = "sum"                                 # Statistic type (sum, average, etc.)
    })
  })
  default     = {}
  description = "CloudWatch Alarm Actions configuration for Security Hub findings notifications. When enabled, creates SNS topic and subscriptions for various notification channels (email, SMS, Slack, Teams, ServiceNow, Jira, etc.)."
}

variable "finding_delivery" {
  description = "Opt-in finding routing. Use either an AmazonSecurityHub endpoint or an Opsgenie Alert API key for lifecycle delivery. Grouped notifications require the API key. Cutover defaults to first apply time. Optional Teams webhooks can follow the Slack topic, Opsgenie topic, or both."
  type = object({
    enabled                    = optional(bool, false)                        # Enable durable Security Hub finding delivery.
    cutover_at                 = optional(string)                             # UTC creation timestamp before which findings are ignored.
    notification_mode          = optional(string, "per_finding")              # Use per_finding or grouped Slack and Opsgenie notifications.
    opsgenie_endpoint          = optional(string)                             # Legacy AmazonSecurityHub webhook endpoint.
    opsgenie_api_key           = optional(string)                             # Opsgenie Alert API key for lifecycle or grouped delivery.
    opsgenie_api_url           = optional(string, "https://api.opsgenie.com") # Opsgenie regional API base URL.
    opsgenie_web_url           = optional(string)                             # Optional Opsgenie web base URL for direct incident links; null derives the regional default.
    opsgenie_alert_prefix      = optional(string, "Security Hub")             # Prefix of Opsgenie alert messages.
    teams_delivery             = optional(string, "none")                     # Teams topic selection: none, slack, opsgenie, or both.
    teams_webhooks             = optional(list(string), [])                   # Teams webhook URLs used by the selected topic or topics.
    environment_label          = optional(string, "")                         # Environment shown in grouped alerts; empty uses a resource tag when present.
    account_environment_labels = optional(map(string), {})                    # Override the displayed environment by finding AWS account ID in delegated-administrator setups.
    project_label              = optional(string, "")                         # Project boundary for Inspector container-image remediation groups; empty uses a resource tag.
    account_label              = optional(string, "")                         # Friendly account label shown in grouped alerts; empty uses the AWS account ID.
    deployment_inventory = optional(object({
      bucket            = string           # S3 bucket containing the running-pod image snapshot.
      key               = string           # Object key of the atomically published snapshot.
      kms_key_arn       = optional(string) # Customer-managed KMS key ARN for an SSE-KMS encrypted snapshot; grants the digest Lambda decrypt access.
      max_age_seconds   = number           # Maximum age before the display environment becomes unverified.
      required_clusters = list(string)     # Clusters that must appear in a complete snapshot.
    }))
    quiet_period_minutes   = optional(number, 60)  # Time without actionable findings before a group is reported quiet.
    finding_retention_days = optional(number, 365) # Days to keep resolved finding snapshots for deduplication and reopen tracking.
    daily_digest = optional(object({
      enabled    = optional(bool, true) # Publish the daily grouped Slack summary.
      hour_utc   = optional(number, 8)  # Earliest UTC hour for the daily summary; reconciliation still runs every 15 minutes.
      max_groups = optional(number, 5)  # Maximum actionable groups shown in the main Slack message.
    }), {})
    realtime = optional(object({
      enabled                       = optional(bool, true)     # Send immediate actionable Slack notifications.
      guardduty_min_severity        = optional(string, "HIGH") # Minimum GuardDuty severity for immediate Slack delivery.
      high_requires_exploit         = optional(bool, true)     # Require known exploit availability for immediate Inspector HIGH alerts.
      high_requires_public_exposure = optional(bool, true)     # Require verified exposure for immediate HIGH Slack alerts.
    }), {})
    paging = optional(object({
      critical                           = optional(bool, true)                           # Enable CRITICAL escalation; ECR uses the separate unknown-context priority.
      high_exploitable                   = optional(bool, true)                           # Enable HIGH paging when exploit and exposure criteria are verified.
      guardduty_types                    = optional(list(string), [])                     # GuardDuty finding-type prefixes promoted to P1; other HIGH/CRITICAL types default to P2.
      guardduty_investigation_types      = optional(list(string), [])                     # GuardDuty finding-type prefixes explicitly classified as P2 investigations.
      guardduty_port_probe_p1            = optional(bool, false)                          # Explicitly permit P1 for configured port-probing findings.
      environments                       = optional(list(string), [])                     # Allowed environment labels; empty permits all.
      production_environments            = optional(list(string), ["Production", "prod"]) # Labels eligible for evidence-backed ECR P1.
      ecr_critical_unknown_priority      = optional(string, "P2")                         # P2, P1, or DIGEST when ECR deployment or exposure is unverified.
      inspector_critical_p2_environments = optional(list(string), [])                     # Environment labels whose CRITICAL non-container Inspector findings use P2 instead of P1.
      ecr_deployment_lookup_enabled      = optional(bool, false)                          # Opt in when this account can read matching Inspector ECS/EKS image-use findings; failures stay unknown.
      ecr_emergency_vulnerability_ids    = optional(list(string), [])                     # Security-owner verified emergency CVE/GHSA IDs eligible for P1.
      require_public_exposure            = optional(bool, true)                           # Require explicit public exposure evidence for HIGH paging; GuardDuty uses finding-type policy.
    }), {})
  })
  default = {}

  validation {
    condition = var.finding_delivery.deployment_inventory == null ? true : (
      var.finding_delivery.notification_mode == "grouped" &&
      length(trimspace(var.finding_delivery.deployment_inventory.bucket)) > 0 &&
      length(trimspace(var.finding_delivery.deployment_inventory.key)) > 0 &&
      (var.finding_delivery.deployment_inventory.kms_key_arn == null || can(regex("^arn:(aws|aws-us-gov|aws-cn):kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.finding_delivery.deployment_inventory.kms_key_arn))) &&
      var.finding_delivery.deployment_inventory.max_age_seconds >= 60 &&
      var.finding_delivery.deployment_inventory.max_age_seconds <= 3600 &&
      length(var.finding_delivery.deployment_inventory.required_clusters) > 0 &&
      length(distinct(var.finding_delivery.deployment_inventory.required_clusters)) == length(var.finding_delivery.deployment_inventory.required_clusters)
    )
    error_message = "deployment_inventory requires grouped mode, bucket, key, an optional KMS key ARN, age between 60 and 3600 seconds, and distinct required clusters."
  }

  validation {
    condition = alltrue([
      for account, label in var.finding_delivery.account_environment_labels :
      can(regex("^[0-9]{12}$", account)) && length(trimspace(label)) > 0
    ])
    error_message = "Account environment labels require 12-digit AWS account IDs and nonempty values."
  }

  validation {
    condition = !var.finding_delivery.enabled || (
      (var.finding_delivery.cutover_at == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.finding_delivery.cutover_at))) &&
      contains(["per_finding", "grouped"], var.finding_delivery.notification_mode) &&
      (var.finding_delivery.notification_mode != "grouped" || var.finding_delivery.opsgenie_api_key != null) &&
      ((var.finding_delivery.opsgenie_endpoint != null) != (var.finding_delivery.opsgenie_api_key != null)) &&
      (var.finding_delivery.opsgenie_endpoint == null || can(regex("^https://api([.]eu)?[.]opsgenie[.]com/v1/json/integrations/webhooks/amazonsecurityhub[?]apiKey=.+$", var.finding_delivery.opsgenie_endpoint))) &&
      (var.finding_delivery.opsgenie_api_key == null || try(length(trimspace(var.finding_delivery.opsgenie_api_key)) > 0, false)) &&
      contains(["https://api.opsgenie.com", "https://api.eu.opsgenie.com"], var.finding_delivery.opsgenie_api_url) &&
      (var.finding_delivery.opsgenie_web_url == null || can(regex("^https://[A-Za-z0-9.-]+[.]opsgenie[.]com/?$", var.finding_delivery.opsgenie_web_url))) &&
      try(length(trimspace(var.finding_delivery.opsgenie_alert_prefix)) > 0, false)
    )
    error_message = "Enabled finding_delivery requires per_finding or grouped mode, an API key for grouped mode, exactly one Opsgenie endpoint or API key, a supported API URL, a nonempty alert prefix, and a valid UTC cutover_at when provided."
  }

  validation {
    condition = contains(["none", "slack", "opsgenie", "both"], var.finding_delivery.teams_delivery) && (
      var.finding_delivery.teams_delivery == "none" ? length(var.finding_delivery.teams_webhooks) == 0 :
      var.finding_delivery.enabled && length(var.finding_delivery.teams_webhooks) > 0
    )
    error_message = "Teams delivery requires none with no webhooks, or slack, opsgenie, or both with enabled finding delivery and at least one Teams webhook."
  }

  validation {
    condition = (
      var.finding_delivery.quiet_period_minutes >= 1 && var.finding_delivery.quiet_period_minutes <= 1440 &&
      floor(var.finding_delivery.quiet_period_minutes) == var.finding_delivery.quiet_period_minutes &&
      var.finding_delivery.finding_retention_days >= 30 && var.finding_delivery.finding_retention_days <= 3650 &&
      floor(var.finding_delivery.finding_retention_days) == var.finding_delivery.finding_retention_days &&
      var.finding_delivery.daily_digest.hour_utc >= 0 && var.finding_delivery.daily_digest.hour_utc <= 23 &&
      floor(var.finding_delivery.daily_digest.hour_utc) == var.finding_delivery.daily_digest.hour_utc &&
      var.finding_delivery.daily_digest.max_groups >= 3 && var.finding_delivery.daily_digest.max_groups <= 5 &&
      floor(var.finding_delivery.daily_digest.max_groups) == var.finding_delivery.daily_digest.max_groups &&
      contains(["LOW", "MEDIUM", "HIGH", "CRITICAL"], var.finding_delivery.realtime.guardduty_min_severity) &&
      alltrue([for prefix in var.finding_delivery.paging.guardduty_types : trimspace(prefix) != ""]) &&
      alltrue([for prefix in var.finding_delivery.paging.guardduty_investigation_types : trimspace(prefix) != ""]) &&
      length(var.finding_delivery.paging.production_environments) > 0 &&
      alltrue([for label in var.finding_delivery.paging.production_environments : trimspace(label) != ""]) &&
      contains(["P1", "P2", "DIGEST"], var.finding_delivery.paging.ecr_critical_unknown_priority) &&
      alltrue([for label in var.finding_delivery.paging.inspector_critical_p2_environments : trimspace(label) != ""]) &&
      alltrue([for identifier in var.finding_delivery.paging.ecr_emergency_vulnerability_ids : trimspace(identifier) != ""])
    )
    error_message = "Grouped delivery requires 1-1440 quiet minutes, UTC digest hour 0-23, 3-5 displayed groups, a valid GuardDuty severity, and nonempty paging type prefixes."
  }
}

variable "link_mode" {
  type        = string
  default     = "ALL_REGIONS"
  description = "Linking mode for Security Hub finding aggregator. Valid values: ALL_REGIONS, SPECIFIED_REGIONS. When set to ALL_REGIONS, Security Hub aggregates findings from all regions. When set to SPECIFIED_REGIONS, only aggregates from regions listed in specified_regions."
}

variable "specified_regions" {
  type        = list(string)
  default     = []
  description = "List of regions to aggregate findings from when link_mode is SPECIFIED_REGIONS. Required when link_mode = SPECIFIED_REGIONS. If empty and link_mode is ALL_REGIONS, findings from all regions are aggregated."
}

variable "enable_security_hub" {
  type        = bool
  default     = true
  description = "Whether to enable/activate security hub and its finding aggregator for aws account, this is useful in case the security hub is already enabled (for example when we test, or account have it enable by default)"
}

variable "enable_default_standards" {
  type        = bool
  default     = false
  description = "Whether Security Hub should automatically enable its default FSBP and CIS v1.2.0 standards when the account is first enabled. Standards are managed explicitly by enabled_standards, so this defaults to false."
}

variable "control_finding_generator" {
  type        = string
  default     = null
  description = "Optional finding generator mode. Set to SECURITY_CONTROL to consolidate findings across standards or STANDARD_CONTROL to emit a finding per standard. Defaults to the provider/AWS value and leaves existing hubs unchanged."

  validation {
    condition     = var.control_finding_generator == null ? true : contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.control_finding_generator)
    error_message = "control_finding_generator must be SECURITY_CONTROL or STANDARD_CONTROL."
  }
}

variable "enable_security_hub_finding_aggregator" {
  type        = bool
  default     = true
  description = "Whether to enable/create security hub and its finding aggregator for aws account, this is useful in case there is already created security hub finding aggregator"
}

variable "standards_subscription_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout for Security Hub standards subscription creation. Default is 10 minutes. Security Hub standards can take several minutes to initialize, especially when AWS Config is being set up. Increase this value if you experience timeout errors."
}

variable "securityhub_members" {
  description = "Security Hub Member Accounts (Email and Account Id)"
  type        = map(any)
  default     = {}
}

variable "enabled_standards" {
  type        = set(string)
  default     = ["aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/5.0.0"]
  description = <<-EOT
    Set of Security Hub standards to enable. Changing the default from CIS v1.2.0 to v5.0.0 is a breaking change. For existing deployments, first explicitly include both versions, wait for v5.0.0 to become READY and produce findings, then remove v1.2.0. Available standards:
    - "aws-foundational-security-best-practices/v/1.0.0" (default)
    - "cis-aws-foundations-benchmark/v/5.0.0" (default)
    - "cis-aws-foundations-benchmark/v/1.2.0" (legacy)
    - "aws-resource-tagging-standard/v/1.0.0"
    - "cis-aws-foundations-benchmark/v/1.4.0"
    - "cis-aws-foundations-benchmark/v/3.0.0"
    - "nist-800-171-rev2/v/1.0.0"
    - "nist-800-53-rev5/v/1.0.0"
    - "pci-dss/v/3.2.1"
    - "pci-dss/v/4.0.1"

    Default: ["aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/5.0.0"]

    Migration override for the first apply to existing deployments:
    enabled_standards = [
      "aws-foundational-security-best-practices/v/1.0.0",
      "cis-aws-foundations-benchmark/v/1.2.0",
      "cis-aws-foundations-benchmark/v/5.0.0"
    ]

    Example to enable all standards:
    enabled_standards = [
      "aws-foundational-security-best-practices/v/1.0.0",
      "cis-aws-foundations-benchmark/v/5.0.0",
      "aws-resource-tagging-standard/v/1.0.0",
      "cis-aws-foundations-benchmark/v/1.4.0",
      "cis-aws-foundations-benchmark/v/3.0.0",
      "cis-aws-foundations-benchmark/v/5.0.0",
      "nist-800-171-rev2/v/1.0.0",
      "nist-800-53-rev5/v/1.0.0",
      "pci-dss/v/3.2.1",
      "pci-dss/v/4.0.1"
    ]
  EOT
}

# AWS Config configuration (REQUIRED for Security Hub to work properly)
# Note: Config can be enabled independently of Security Hub, but is REQUIRED for Security Hub standards to evaluate resources
variable "config" {
  type = object({
    enabled                    = optional(bool, true)                 # Enable/disable AWS Config. REQUIRED for Security Hub standards to work properly. Can be enabled independently of Security Hub.
    create_service_linked_role = optional(bool, true)                 # Whether to create the AWS Config service-linked role. Set to false if the role already exists in your account. If set to true and the role already exists, Terraform will fail with EntityAlreadyExists - in that case, set this to false and import the existing role
    record_all_resources       = optional(bool, true)                 # Record all supported resource types in AWS Config. If false, use included_resource_types to specify which resources to record
    include_global_resources   = optional(bool, true)                 # Include global resources (IAM, etc.) in AWS Config recording
    s3_bucket_name             = optional(string, "")                 # S3 bucket name for AWS Config. If empty, a bucket will be created automatically
    s3_bucket_force_destroy    = optional(bool, false)                # Force destroy S3 bucket for Config when deleting the module
    delivery_frequency         = optional(string, "TwentyFour_Hours") # Frequency for Config snapshot delivery. Valid values: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours
    included_resource_types    = optional(list(string), [])           # List of resource types to include when record_all_resources is false. If empty and record_all_resources is false, all resources are excluded
    excluded_resource_types    = optional(list(string), [])           # List of resource types to exclude when record_all_resources is true
    rules = optional(map(object({                                     # Map of Config rules to create. Key is the rule name. If empty, no rules will be created
      description = optional(string)                                  # Rule description
      source = optional(object({                                      # Rule source configuration
        owner             = string                                    # Source owner (AWS or CUSTOM_LAMBDA)
        source_identifier = string                                    # Source identifier (e.g., "S3_BUCKET_PUBLIC_READ_PROHIBITED" for AWS managed rules)
        source_detail = optional(list(object({                        # Additional source details for event-based rules
          event_source                = optional(string)              # Event source (e.g., "aws.config")
          maximum_execution_frequency = optional(string)              # Maximum execution frequency
          message_type                = optional(string)              # Message type
        })))
      }))
      scope = optional(object({                            # Rule scope - defines which resources the rule evaluates
        compliance_resource_types = optional(list(string)) # Resource types to evaluate
        compliance_resource_id    = optional(string)       # Specific resource ID to evaluate
        tag_key                   = optional(string)       # Tag key for tag-based scoping
        tag_value                 = optional(string)       # Tag value for tag-based scoping
      }))
      input_parameters = optional(string)      # JSON string of input parameters for the rule
      tags             = optional(map(string)) # Tags to apply to the rule
    })), {})
  })
  default     = {}
  description = "AWS Config configuration. REQUIRED for Security Hub standards to evaluate resources. Without Config, Security Hub won't detect misconfigurations properly. Config can be enabled independently of Security Hub."
}

# AWS Inspector configuration (RECOMMENDED for EC2/EKS vulnerability scanning)
# Note: Inspector can be enabled independently of Security Hub, but findings are automatically sent to Security Hub when both are enabled
variable "inspector" {
  type = object({
    enabled        = optional(bool, true)                                            # Enable/disable AWS Inspector v2. RECOMMENDED for EC2/EKS vulnerability scanning. Can be enabled independently of Security Hub.
    resource_types = optional(list(string), ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]) # Resource types to enable Inspector for. Valid values: EC2, ECR, LAMBDA, LAMBDA_CODE, CODE_REPOSITORY. LAMBDA scans Lambda function configuration (runtime, permissions). LAMBDA_CODE scans Lambda function code (dependencies, vulnerabilities). Both are recommended for comprehensive Lambda scanning
    filters = optional(map(object({                                                  # Map of findings filters to create. Key is the filter name. If empty, no filters will be created
      description   = optional(string)                                               # Filter description
      filter_action = string                                                         # Filter action. Valid values: ARCHIVE (suppress findings), NOOP (no action)
      filter_criteria = optional(object({                                            # Filter criteria for matching findings
        aws_account_id = optional(object({                                           # Filter by AWS account ID
          comparison = string                                                        # Comparison operator (EQUALS, PREFIX, NOT_EQUALS)
          value      = string                                                        # Account ID value
        }))
        component_id = optional(object({ # Filter by component ID
          comparison = string
          value      = string
        }))
        component_type = optional(object({ # Filter by component type
          comparison = string
          value      = string
        }))
        ec2_instance_image_id = optional(object({ # Filter by EC2 instance AMI ID
          comparison = string
          value      = string
        }))
        ec2_instance_subnet_id = optional(object({ # Filter by EC2 instance subnet ID
          comparison = string
          value      = string
        }))
        ec2_instance_vpc_id = optional(object({ # Filter by EC2 instance VPC ID
          comparison = string
          value      = string
        }))
        ecr_image_pushed_at = optional(object({ # Filter by ECR image push date/time
          end_inclusive   = optional(string)    # End date (ISO 8601 format)
          start_inclusive = optional(string)    # Start date (ISO 8601 format)
        }))
        ecr_image_tags = optional(object({ # Filter by ECR image tags
          comparison = string
          value      = string
        }))
        ecr_image_hash = optional(object({ # Filter by ECR image hash
          comparison = string
          value      = string
        }))
        finding_arn = optional(object({ # Filter by finding ARN
          comparison = string
          value      = string
        }))
        finding_status = optional(object({ # Filter by finding status (ACTIVE, SUPPRESSED, CLOSED)
          comparison = string
          value      = string
        }))
        finding_type = optional(object({ # Filter by finding type
          comparison = string
          value      = string
        }))
        first_observed_at = optional(object({ # Filter by first observation date/time
          end_inclusive   = optional(string)  # End date (ISO 8601 format)
          start_inclusive = optional(string)  # Start date (ISO 8601 format)
        }))
        inspector_score = optional(object({  # Filter by Inspector score range
          lower_inclusive = optional(number) # Minimum score (0-10)
          upper_inclusive = optional(number) # Maximum score (0-10)
        }))
        last_observed_at = optional(object({ # Filter by last observation date/time
          end_inclusive   = optional(string) # End date (ISO 8601 format)
          start_inclusive = optional(string) # Start date (ISO 8601 format)
        }))
        network_protocol = optional(object({ # Filter by network protocol
          comparison = string
          value      = string
        }))
        port_range = optional(object({       # Filter by port range
          begin_inclusive = optional(number) # Start port number
          end_inclusive   = optional(number) # End port number
        }))
        related_vulnerabilities = optional(object({ # Filter by related vulnerability IDs
          comparison = string
          value      = string
        }))
        resource_id = optional(object({ # Filter by resource ID
          comparison = string
          value      = string
        }))
        resource_tags = optional(object({ # Filter by resource tags
          comparison = string             # Comparison operator
          key        = string             # Tag key
          value      = optional(string)   # Tag value (optional)
        }))
        resource_type = optional(object({ # Filter by resource type (EC2, ECR, LAMBDA)
          comparison = string
          value      = string
        }))
        severity = optional(object({ # Filter by severity (CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNTRIAGED)
          comparison = string
          value      = string
        }))
        title = optional(object({ # Filter by finding title
          comparison = string
          value      = string
        }))
        updated_at = optional(object({       # Filter by last update date/time
          end_inclusive   = optional(string) # End date (ISO 8601 format)
          start_inclusive = optional(string) # Start date (ISO 8601 format)
        }))
        vendor_severity = optional(object({ # Filter by vendor severity
          comparison = string
          value      = string
        }))
        vulnerability_id = optional(object({ # Filter by vulnerability ID (CVE ID, etc.)
          comparison = string
          value      = string
        }))
        vulnerability_source = optional(object({ # Filter by vulnerability source
          comparison = string
          value      = string
        }))
      }))
    })), {})
  })
  default     = {}
  description = "AWS Inspector v2 configuration. RECOMMENDED for EC2/EKS vulnerability scanning. Inspector findings are automatically sent to Security Hub when both are enabled. Inspector can be enabled independently of Security Hub."
}

# AWS GuardDuty configuration (OPTIONAL - threat detection)
# Note: GuardDuty can be enabled independently of Security Hub, but findings are automatically sent to Security Hub when both are enabled
variable "guardduty" {
  type = object({
    enabled                      = optional(bool, false)               # Enable/disable AWS GuardDuty. OPTIONAL threat detection service. Can be enabled independently of Security Hub.
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES") # Frequency of notifications sent for finding occurrences. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS
    enable_s3_protection         = optional(bool, true)                # Enable S3 protection in GuardDuty (detects threats to S3 buckets)
    enable_kubernetes_protection = optional(bool, true)                # Enable Kubernetes audit log protection in GuardDuty
    enable_malware_protection    = optional(bool, true)                # Enable malware protection for EC2 instances in GuardDuty
    filters = optional(map(object({                                    # Map of findings filters to create. Key is the filter name. If empty, no filters will be created
      description = optional(string)                                   # Filter description
      action      = string                                             # Filter action. Valid values: ARCHIVE (suppress findings), NOOP (no action)
      rank        = optional(number)                                   # Filter rank (determines filter evaluation order)
      finding_criteria = optional(object({                             # Filter criteria for matching findings
        criterion = optional(map(object({                              # Map of criterion fields. Key is the finding field name (e.g., "severity", "type")
          equals                = optional(list(string))               # Match if field equals any value in list
          not_equals            = optional(list(string))               # Match if field does not equal any value in list
          greater_than          = optional(number)                     # Match if field is greater than value
          greater_than_or_equal = optional(number)                     # Match if field is greater than or equal to value
          less_than             = optional(number)                     # Match if field is less than value
          less_than_or_equal    = optional(number)                     # Match if field is less than or equal to value
        })))
      }))
      tags = optional(map(string)) # Tags to apply to the filter
    })), {})
  })
  default     = {}
  description = "AWS GuardDuty configuration. OPTIONAL threat detection service. GuardDuty findings are automatically sent to Security Hub when both are enabled. GuardDuty can be enabled independently of Security Hub."
}

# Amazon Macie configuration (OPTIONAL - data security)
# Note: Macie can be enabled independently of Security Hub, but findings are automatically sent to Security Hub when both are enabled
variable "macie" {
  type = object({
    enabled                      = optional(bool, false)               # Enable/disable Amazon Macie v2. OPTIONAL data security and privacy service. Can be enabled independently of Security Hub.
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES") # Frequency of policy findings updates. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS
    status                       = optional(string, "ENABLED")         # Macie account status. Valid values: ENABLED, PAUSED
    findings_filters = optional(map(object({                           # Map of findings filters to create. Key is the filter name (which becomes the field name in criterion). If empty, no filters will be created
      description = optional(string)                                   # Filter description
      action      = string                                             # Filter action. Valid values: ARCHIVE (suppress findings), NOOP (no action)
      position    = optional(number)                                   # Filter position (determines filter evaluation order)
      finding_criteria = optional(object({                             # Filter criteria for matching findings
        criterion = optional(map(object({                              # Map of criterion fields. Key is the finding field name (e.g., "severity", "type")
          eq  = optional(list(string))                                 # Match if field equals any value in list
          gt  = optional(number)                                       # Match if field is greater than value
          gte = optional(number)                                       # Match if field is greater than or equal to value
          lt  = optional(number)                                       # Match if field is less than value
          lte = optional(number)                                       # Match if field is less than or equal to value
          neq = optional(list(string))                                 # Match if field does not equal any value in list
        })))
      }))
      tags = optional(map(string)) # Tags to apply to the filter
    })), {})
  })
  default     = {}
  description = "Amazon Macie v2 configuration. OPTIONAL data security and privacy service. Macie discovers and protects sensitive data in S3. Findings are automatically sent to Security Hub when both are enabled. Macie can be enabled independently of Security Hub."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
