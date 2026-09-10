# Data Model: CloudWatch Synthetics Canaries Module

**Feature**: `002-cloudwatch-synthetics-canaries`

## Entities

### Canary (logical)

A monitored endpoint configuration keyed by stable map name.

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `key` | string (map key) | yes | — | Stable logical identifier; drives resource naming |
| `check_type` | enum | yes | — | `soap_wsdl`, `soap_cardinfo`, `rest_cardinfo`, `blackhawk_management` |
| `endpoint_url` | string (URL) | yes | — | Target URL; must not appear in resource names |
| `secret_arn` | string (ARN) | yes | — | Secrets Manager secret for runtime credential fetch |
| `schedule` | string | no | `rate(1 minute)` | EventBridge rate or cron expression |
| `timeout_seconds` | number | no | `60` | 3–840 inclusive |
| `retries` | number | no | `0` | Synthetics run retries (0–2) |
| `runtime_version` | string | no | `syn-python-selenium-11.0` | Must match allowlist |
| `secret_fields` | map(string) | no | `{}` | Maps logical names → JSON keys in secret |
| `environment` | map(string) | no | `{}` | Non-secret env vars passed to script; `soap_cardinfo` requires `SOAP_NAMESPACE` |
| `vpc_config` | object | no | null | `{ subnet_ids, security_group_ids }` |
| `alarm_config` | object | no | module defaults | Per-canary alarm overrides |
| `tags` | map(string) | no | `{}` | Merged with module `default_tags` |

**Relationships**:
- 1 Canary → 1 IAM Role
- 1 Canary → 1 CloudWatch Log Group
- 1 Canary → 1 Synthetics Canary resource
- 1 Canary → 1 CloudWatch Alarm
- N Canaries → 1 Artifact Bucket (shared, module-managed)

---

### ModuleConfig (module-level)

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `name_prefix` | string | yes | — | Prefix for all resource names |
| `canaries` | map(Canary) | yes | — | At least one entry when module used |
| `sns_topic_arn` | string (ARN) | yes | — | Consumer-owned alarm destination |
| `create_artifact_bucket` | bool | no | `true` | Create shared S3 bucket |
| `artifact_bucket_name` | string | no | null | Required when `create_artifact_bucket = false` |
| `kms_key_arn` | string (ARN) | no | null | CMK for S3 SSE-KMS and Secrets decrypt |
| `log_retention_days` | number | no | `14` | CloudWatch log retention |
| `artifact_expiration_days` | number | no | `30` | S3 lifecycle expiration |
| `default_tags` | map(string) | no | `{}` | Applied to all taggable resources |
| `default_alarm_config` | object | no | see below | Inherited by canaries |

---

### AlarmConfig

| Field | Type | Default |
|-------|------|---------|
| `enabled` | bool | `true` |
| `threshold` | number | `1` |
| `evaluation_periods` | number | `1` |
| `datapoints_to_alarm` | number | `1` |
| `period` | number | `60` |
| `treat_missing_data` | string | `breaching` |
| `comparison_operator` | string | `LessThanThreshold` |

Metric fixed: `CloudWatchSynthetics` / `Success` / dimension `CanaryName`.

---

### SecretContract

Runtime JSON object in Secrets Manager. Keys are arbitrary; mapped via `secret_fields`.

| Logical field | Typical JSON keys | Used by |
|---------------|-------------------|---------|
| `username` | `username`, `user` | soap_cardinfo |
| `password` | `password`, `pass` | soap_cardinfo, blackhawk_management |
| `api_key` | `api_key`, `apiKey` | rest_cardinfo |
| `bearer_token` | `token`, `bearer_token` | rest_cardinfo |
| `client_id` | `client_id`, `clientId` | blackhawk_management |
| `client_secret` | `client_secret`, `clientSecret` | blackhawk_management |
| `soap_action` | `soap_action`, `action` | soap_cardinfo |

**Validation**: Terraform validates ARN format only; secret JSON shape validated at runtime by script with clear error (redacted).

---

### ArtifactStore

| Field | Type | Notes |
|-------|------|-------|
| `bucket_name` | string | Module-created or consumer-supplied |
| `encryption_mode` | enum | `SSE_S3` or `SSE_KMS` |
| `kms_key_arn` | string | Required when SSE_KMS |
| `public_access_blocked` | bool | Always true |
| `versioning_enabled` | bool | Always true (module-managed) |

---

### CheckType

| Value | Script path | Handler |
|-------|-------------|---------|
| `soap_wsdl` | `src/soap_wsdl/python/canary.py` | `canary.handler` |
| `soap_cardinfo` | `src/soap_cardinfo/python/canary.py` | `canary.handler` |
| `rest_cardinfo` | `src/rest_cardinfo/python/canary.py` | `canary.handler` |
| `blackhawk_management` | `src/blackhawk_management/python/canary.py` | `canary.handler` |

---

## State transitions

### Canary execution

```text
Scheduled → Running → Success (metric=1) → Alarm OK
                   └→ Failure (metric=0) → Alarm ALARM → SNS notify
                   └→ Timeout/Error       → Alarm ALARM → SNS notify
Missing runs       → treat_missing_data=breaching → Alarm ALARM
```

### Terraform lifecycle

```text
Plan → validate inputs
Apply → create bucket (if enabled) → upload script zips → create IAM → create canary → create alarm → start canary
Destroy → stop canary → delete resources (bucket objects via force_destroy in tests only)
```

---

## Validation rules (plan time)

| Rule | Error condition |
|------|-----------------|
| V-001 | `check_type` not in allowed set |
| V-002 | `schedule` does not match `^(rate\(\d+ (minute\|minutes\|hour\|hours\|day\|days)\)\|cron\(.+\))$` |
| V-003 | `timeout_seconds` ∉ [3, 840] |
| V-004 | `secret_arn` / `sns_topic_arn` / `kms_key_arn` fail ARN regex |
| V-005 | `vpc_config` partial (one of subnet_ids or security_group_ids empty) |
| V-006 | `create_artifact_bucket = false` and `artifact_bucket_name` null |
| V-007 | `runtime_version` not matching allowlist |
| V-008 | `canaries` map empty |
| V-009 | Map key contains characters invalid for AWS naming after sanitization yields empty string |
| V-010 | `soap_cardinfo` canary omits `environment.SOAP_NAMESPACE` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `canary_arns` | Map of canary key → Synthetics canary ARN |
| `canary_names` | Map of canary key → AWS canary name |
| `alarm_arns` | Map of canary key → CloudWatch alarm ARN |
| `artifact_bucket_arn` | Shared artifact bucket ARN (null if external bucket without ARN supplied) |
| `execution_role_arns` | Map of canary key → IAM role ARN |
