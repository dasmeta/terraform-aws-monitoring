# Public Module Contract

## Terraform interface

```hcl
module "service_canaries" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-synthetics"
  version = "<published-version>"

  name_prefix    = "example-production"
  sns_topic_name = "example-synthetics-alerts"

  canaries = {
    api_check = {
      secret_name = "monitoring/example/api-check"
      source_files = {
        "python/canary.py"     = "canaries/api_check/canary.py"
        "python/http_utils.py" = "canaries/common/http_utils.py"
      }
      config = {
        environment = "production"
        endpoint    = "https://service.example.com/health"
      }
    }
  }
}
```

Source paths are relative to root configuration, not module directory. Do not use source symlinks: Terraform can reject explicit `..` and absolute paths but cannot prove a symlink target remains inside the workspace. `python/canary.py` defines `handler(event, context)`. Generated root `config.json` contains `config` plus `secret_name`.

## DasMeta wrapper interface

```yaml
source: dasmeta/monitoring/aws//modules/cloudwatch-synthetics
version: <published-version>
variables:
  name_prefix: example-production
  sns_topic_name: example-synthetics-alerts
  canaries:
    api_check:
      secret_name: ${0-accounts/production/monitoring-secrets.api_check_secret_name}
      source_files:
        python/canary.py: canaries/api_check/canary.py
        python/http_utils.py: canaries/common/http_utils.py
      config:
        environment: production
        endpoint: https://service.example.com/health
```

The referenced Terraform Cloud output contains a secret **name**, never an ARN or secret value.
