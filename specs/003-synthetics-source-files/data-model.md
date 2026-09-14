# Data Model: Source-File CloudWatch Synthetics Canaries

## `canaries`

| Field | Type | Required | Rules |
|---|---|---:|---|
| `source_files` | `map(string)` | yes | Key is canonical `python/...`; value is lexically validated then checked by guarded archive precondition below `path.root`; symlink sources are unsupported because Terraform cannot prove their target remains in workspace; includes `python/canary.py`. |
| `secret_name` | `string` | yes | Existing same-account secret name, never its value or ARN. |
| `config` | `map(string)` | no | Non-secret fields only; cannot contain `secret_name`. |
| `schedule`, `timeout_seconds`, `tags`, `vpc_config`, `alarm_config` | existing optional fields | no | Existing validation/defaults retained. |

## Derived package

One per canary, containing all source mappings and generated root `config.json`. Archive checksum updates matching versioned S3 object.

## Looked-up AWS entities

| Entity | Lookup input | Used for |
|---|---|---|
| Secrets Manager secret | `secret_name` | IAM resource ARN and runtime `GetSecretValue`. |
| Customer KMS key | secret `kms_key_id`, when present | Conditional scoped decrypt policy. |
| SNS topic | `sns_topic_name` | Failure alarm action ARN. |

## State boundaries

- Terraform never reads `SecretString` or `SecretBinary`.
- Archive source contents can appear in plan/state; state readers must be authorized for the code.
- Consumers must keep secret material out of `config`.
