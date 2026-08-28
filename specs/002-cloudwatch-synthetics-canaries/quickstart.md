# Quickstart: CloudWatch Synthetics Canaries Module

**Module path**: `dasmeta/monitoring/aws//modules/cloudwatch-synthetics`  
**Feature branch**: `002-cloudwatch-synthetics-canaries`

## Prerequisites

- Terraform ~> 1.3
- AWS provider ~> 5.0
- An SNS topic ARN for alarm notifications (consumer-owned)
- Secrets Manager secrets pre-created with JSON credential objects
- Approved non-production AWS account for testing

## Minimal example

```hcl
module "legacy_gateway_canaries" {
  source = "dasmeta/monitoring/aws//modules/cloudwatch-synthetics"
  # version = "x.y.z"  # after release

  name_prefix   = "example"
  sns_topic_arn = "arn:aws:sns:eu-central-1:123456789012:cloudwatch-alerts"

  canaries = {
    soap-wsdl-check = {
      check_type   = "soap_wsdl"
      endpoint_url = "https://example.com/service?wsdl"
      secret_arn   = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:example/wsdl"
    }

    rest-cardinfo-check = {
      check_type   = "rest_cardinfo"
      endpoint_url = "https://example.com/api/cardinfo"
      secret_arn   = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:example/rest"
      secret_fields = {
        bearer_token = "token"
      }
      schedule = "rate(5 minutes)"
    }
  }

  default_tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
```

## Secrets Manager setup

Create a secret with JSON content (example only — use real keys per endpoint):

```json
{
  "username": "example-user",
  "password": "example-pass",
  "token": "example-bearer-token"
}
```

Map keys to script inputs:

```hcl
secret_fields = {
  username = "username"
  password = "password"
  bearer_token = "token"
}
```

Scripts call `GetSecretValue` at runtime; Terraform never receives secret values.

## Alarm wiring

The module creates one CloudWatch alarm per canary on the `Success` metric. Wire an existing SNS topic:

```hcl
sns_topic_arn = module.alarm_actions.topic_arn
# or
sns_topic_arn = "arn:aws:sns:region:account:cloudwatch-alerts"
```

Default alarm fires when a canary run fails or data is missing.

## VPC-enabled canaries

For private endpoints:

```hcl
canaries = {
  internal-soap = {
    check_type   = "soap_cardinfo"
    endpoint_url = "https://internal.example.local/soap"
    secret_arn   = "arn:aws:secretsmanager:..."
    vpc_config = {
      subnet_ids         = ["subnet-abc123"]
      security_group_ids = ["sg-abc123"]
    }
  }
}
```

Ensure egress TCP 443 to the endpoint, Secrets Manager, S3, and CloudWatch Logs (via NAT or VPC endpoints).

## Using an existing artifact bucket

```hcl
create_artifact_bucket = false
artifact_bucket_name = "example-synthetics-artifacts"
```

Preflight requirements:
- Bucket exists in the same region as the provider
- Block public access enabled
- Versioning enabled
- TLS-only bucket policy recommended
- Encryption configured (SSE-S3 or SSE-KMS)

## Local development and tests

```bash
# From repo root
cd modules/cloudwatch-synthetics/tests/basic
terraform init
terraform test

# Formatting
terraform fmt -recursive modules/cloudwatch-synthetics/
```

CI runs the module via `.github/workflows/terraform-test.yaml` using repository AWS secrets.

## Check types

| check_type | Use case |
|------------|----------|
| `soap_wsdl` | WSDL availability check |
| `soap_cardinfo` | SOAP CardInfo endpoint health |
| `rest_cardinfo` | REST CardInfo endpoint health |
| `blackhawk_management` | Blackhawk Network management API health |

See [contracts/check-types.md](./contracts/check-types.md) for script behavior and assertion details.

## Next steps

1. Run `/speckit.tasks` to generate implementation tasks
2. Implement module under `modules/cloudwatch-synthetics/`
3. Validate in approved non-prod account before merge
