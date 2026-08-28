# Contract: Secrets Manager

**Module**: `modules/cloudwatch-synthetics`

## Overview

Each canary references exactly one Secrets Manager secret by ARN. Terraform passes the ARN and a key-mapping (`secret_fields`) to the canary environment. Python scripts fetch and parse the secret at runtime.

## Secret format

- **Type**: JSON string (Secrets Manager `SecretString`)
- **Structure**: Flat JSON object with string values (nested objects not required for v1)

Example (documentation / tests only):

```json
{
  "username": "example-user",
  "password": "example-pass",
  "token": "example-bearer-token",
  "client_id": "example-client",
  "client_secret": "example-secret",
  "soap_action": "http://example.com/CardInfo"
}
```

## secret_fields mapping

Maps **logical names** (used in Python) to **JSON keys** (in the secret):

```hcl
secret_fields = {
  username     = "username"
  password     = "pass"           # maps logical "password" to JSON key "pass"
  bearer_token = "token"
}
```

Scripts resolve: `logical_value = secret_json[secret_fields["logical_name"]]`

Missing keys produce a runtime error with the logical name only (never the secret value).

## IAM scope

Per-canary role:

```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "<canary.secret_arn>"
}
```

When `kms_key_arn` is set at module level:

```json
{
  "Effect": "Allow",
  "Action": "kms:Decrypt",
  "Resource": "<kms_key_arn>"
}
```

## Redaction contract

The shared `secrets.py` helper MUST redact before logging or including in exception messages:

- Any value retrieved from Secrets Manager
- Keys matching (case-insensitive): `password`, `pass`, `secret`, `token`, `api_key`, `apikey`, `client_secret`, `authorization`
- Patterns resembling `Bearer <token>`, Basic auth headers

Redaction replacement: `"***REDACTED***"`

## Terraform constraints

- `secret_arn` validated as ARN at plan time
- Secret **values** MUST NOT appear in:
  - Terraform variables (except test fixtures using dummy values in Secrets Manager, not in HCL)
  - Resource names or tags
  - Module outputs
  - State outputs that echo environment variables containing secrets (only non-secret env vars in Terraform)

## Test fixture contract

Tests create secrets via `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` with dummy values:

```hcl
secret_string = jsonencode({
  username = "example-user"
  password = "example-pass"
})
```

Assert logs do not contain `example-pass` after forced failure.

## Rotation

Secret rotation is consumer-managed. Canaries read latest version on each run via `GetSecretValue` without version stage pinning in v1.
