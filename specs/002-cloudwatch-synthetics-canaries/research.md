# Research: CloudWatch Synthetics Canaries Module

**Feature**: `002-cloudwatch-synthetics-canaries`  
**Date**: 2026-07-21

Resolves items deferred from [spec.md](./spec.md) and technical unknowns from planning.

---

## 1. Default retention and deletion protection

**Decision**: Module-managed resources use the following defaults:

| Resource | Default | Configurable |
|----------|---------|--------------|
| CloudWatch log group (per canary) | 14 days | `log_retention_days` (module-level) |
| S3 artifact bucket lifecycle | Expire objects after 30 days | `artifact_expiration_days` |
| S3 bucket versioning | Enabled | Fixed (required for script update detection) |
| S3 deletion protection | Disabled | Fixed (enables clean test destroy) |
| S3 force destroy | `false` in module default; `true` only in test fixtures | Test setup override |

**Rationale**: Aligns with repo patterns (`cloudwatch-alarm-actions` uses 7-day Lambda logs; canaries produce more artifact volume, so 14/30 days is a reasonable balance). Deletion protection off matches other monitoring modules that must tear down in CI.

**Alternatives considered**:
- 7-day retention everywhere — rejected; canary troubleshooting often needs slightly longer log history.
- Deletion protection on — rejected; blocks non-prod lifecycle tests and contradicts module test conventions.

---

## 2. S3 artifact storage strategy

**Decision**: Module creates one shared bucket when `create_artifact_bucket = true` (default). Consumers may set `create_artifact_bucket = false` and supply `artifact_bucket_name` + `artifact_bucket_arn` after completing documented preflight attestation (bucket exists, block public access, versioning, TLS policy, encryption).

Per-canary artifact path: `s3://<bucket>/canaries/<canary_key>/`

Script bundles stored at: `s3://<bucket>/scripts/<check_type>/<hash>.zip`

**Rationale**: AWS Synthetics requires artifact S3 location per canary. Shared bucket reduces sprawl; per-canary prefixes isolate artifacts. S3-hosted scripts avoid 225KB `zip_file` inline limit and support dependency bundling.

**Alternatives considered**:
- Inline `zip_file` only — rejected for maintainability once common helpers and dependencies are bundled.
- Per-canary buckets — rejected; excessive IAM and cost for expected scale.

---

## 3. IAM permissions model

**Decision**: One IAM role per canary (not shared) with:

- Trust: `lambda.amazonaws.com` + `synthetics.amazonaws.com`
- `secretsmanager:GetSecretValue` on canary's `secret_arn` only
- `kms:Decrypt` on `kms_key_arn` when set
- S3: `GetObject`, `PutObject`, `ListBucket` on artifact bucket and prefix
- Logs: `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` on canary log group ARN
- `cloudwatch:PutMetricData` on `*`

**Rationale**: Least privilege per spec FR-003/US3; matches AWS Synthetics execution role guidance.

**Alternatives considered**:
- Single shared role — rejected; would require broadening Secrets Manager scope across all canary secrets.

---

## 4. Runtime and handler conventions

**Decision**:
- Default runtime: `syn-python-selenium-11.0`
- Allowlist validation via regex: `^syn-python-selenium-[0-9]+(\.[0-9]+)?$`
- Handler: `canary.handler`
- Script path in zip: `python/canary.py` (AWS requirement for selenium 1.1+)

**Rationale**: Spec FR-006; AWS documentation requires `python/` folder layout for selenium runtimes.

**Alternatives considered**:
- Node.js puppeteer runtime — rejected; spec mandates Python check migration from Bash.

---

## 5. Alarm metric and thresholds

**Decision**: Use `CloudWatchSynthetics` / `Success` with dimension `CanaryName`:

```hcl
comparison_operator = "LessThanThreshold"
threshold           = 1
evaluation_periods  = 1
datapoints_to_alarm = 1
period              = 60  # align with minimum schedule granularity
treat_missing_data  = "breaching"
statistic           = "Minimum"
```

**Rationale**: Matches spec US4 defaults. Missing data as breaching detects canary stopped/deleted scenarios.

**Alternatives considered**:
- `Failed` metric with `GreaterThanThreshold` — equivalent but less intuitive for "success" semantics; kept Success for readability.

---

## 6. Check-specific request/response schemas (pending app validation)

**Decision**: Ship **stub implementations** with documented expected behavior and configurable assertion inputs via `environment` and `secret_fields`. Final PRTG parity assertions updated in a follow-up once application team validates current Bash scripts.

| check_type | Purpose (stub) | Required secret_fields (defaults) |
|------------|----------------|-----------------------------------|
| `soap_wsdl` | HTTP GET WSDL URL; assert HTTP 200 and body contains `wsdl:` or `definitions` | `{}` (optional auth via secret) |
| `soap_cardinfo` | SOAP POST to endpoint; assert HTTP 200 and no `Fault` in body | `username`, `password`, `soap_action` |
| `rest_cardinfo` | REST GET/POST to endpoint; assert HTTP 2xx and JSON field `status` present | `api_key` or `bearer_token` |
| `blackhawk_management` | HTTPS GET management endpoint; assert HTTP 200 | `client_id`, `client_secret` |

**Rationale**: Unblocks module infrastructure delivery (IAM, S3, alarms, tests) without blocking on legacy script review. `secret_fields` mapping allows endpoint-specific key names without code changes.

**Alternatives considered**:
- Wait for app team before any script code — rejected; delays entire DMVP-10322 infrastructure track.

---

## 7. Test harness and non-production account

**Decision**:
- Follow existing `modules/*/tests/` layout: `0-setup.tf`, `1-example.tf`, `2-assert.tf`, `README.md`
- Use CI secrets from `.github/workflows/terraform-test.yaml` (`AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) — same approved non-prod account as other modules
- Tests create dedicated Secrets Manager secrets with dummy JSON (`example-user` / `example-pass` placeholders)
- Use neutral hostnames: `https://example.com`, `https://httpbin.org/status/200` for reachability; dedicated failure host `https://httpbin.org/status/500` for alarm tests
- Schedule in tests: `rate(5 minutes)` except alarm test which may use `rate(1 minute)` with explicit `terraform test` wait/assert retry

**Rationale**: Consistent with repo CI; avoids production credentials; satisfies SC-003/SC-005.

**Alternatives considered**:
- LocalStack — rejected; Synthetics not supported.
- Mock-only unit tests without AWS — rejected; spec requires lifecycle and alarm validation in non-prod.

---

## 8. VPC opt-in behavior

**Decision**: `vpc_config` optional object `{ subnet_ids, security_group_ids }`. When omitted, no `vpc_config` block on canary. When set, both fields required (validation error if either empty).

Document in README:
- Egress TCP 443 to endpoint, Secrets Manager, S3, and CloudWatch Logs
- Recommend interface VPC endpoints or NAT for private subnets

**Rationale**: Spec US3 scenario 4; common Synthetics VPC pitfall.

---

## 9. Naming conventions

**Decision**: Resource names derived from `name_prefix` + sanitized map key:

- Canary: `${name_prefix}-${key}` truncated to 21 chars (AWS limit), lowercase alphanumeric + hyphens
- IAM role: `${name_prefix}-${key}-synthetics-role` (truncate to 64)
- Alarm: `${name_prefix}-${key}-canary-failed`
- Never embed `endpoint_url`, secret values, or customer identifiers in names

**Rationale**: Spec US1 scenario 3; AWS Synthetics name length limit.

---

## 10. External design document

**Decision**: Source design doc (`infra-governance/docs/superpowers/specs/2026-07-20-cloudwatch-synthetics-module-design.md`) was not available in workspace. Plan derived from feature spec, AWS Synthetics/Terraform registry docs, and existing `terraform-aws-monitoring` module patterns.

**Rationale**: Proceed with spec as authoritative; reconcile with design doc when available during implementation review.
