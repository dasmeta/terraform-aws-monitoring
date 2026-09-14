# Feature Specification: Source-File CloudWatch Synthetics Canaries

**Feature**: 003-synthetics-source-files
**Status**: Specified

## User Scenarios & Testing

### User Story 1 - Build a canary from private source files (Priority: P1)

A consumer gives each canary its private Python source-file locations and
non-secret configuration. The module creates the deployment package and the
AWS canary without requiring a manually built ZIP.

**Acceptance Scenario**: A neutral fixture with `python/canary.py` and a helper
file produces a ZIP with those files and a root-level `config.json`. The fixed
`syn-python-selenium-11.1` Synthetics runtime and `canary.handler` handler
invoke `handler(event, context)` from that file, and the expected canary
resources are created.

**State-access note**: Building the ZIP from individual files can record the
private source-file contents in Terraform plan/state data. The consumer must
restrict state access to people who may read that code.

### User Story 2 - Reuse an existing secret by name (Priority: P1)

A consumer passes a secret name from a Terraform Cloud workspace output. The
module finds the existing AWS secret and grants only that canary permission to
read it.

**Acceptance Scenario**: A test supplies a neutral existing secret name. The
module creates no secret value and scopes the canary role to the looked-up
secret.

### User Story 3 - Use an existing SNS topic by name (Priority: P2)

A consumer supplies an SNS topic name instead of an ARN. The failure alarm is
created with the internally resolved topic.

**Acceptance Scenario**: A neutral test topic name produces a failure alarm
with the resolved topic as its action.

## Requirements

- Each canary must accept `source_files`, a map of ZIP destination path to
  local source-file path below the consumer Terraform root.
- Each canary must accept `secret_name` and non-secret `config` values.
- The module must add `secret_name` to generated canary configuration.
- The module must build one ZIP per canary from the supplied files and generated
  configuration using the `hashicorp/archive` resource; no local ZIP command is
  required, and a Terraform Cloud apply must not depend on a speculative plan
  worker retaining a ZIP file.
- A rebuilt ZIP must cause the canary package uploaded to AWS to update when a
  source file or generated configuration changes.
- The module must find an existing Secrets Manager secret by name, not create,
  change, or delete it.
- The canary role must receive `secretsmanager:GetSecretValue` only for the
  looked-up secret ARN. If that secret uses a customer-managed KMS key, the role
  must also receive a least-privilege `kms:Decrypt` permission for that key;
  the customer-managed key policy must allow the role.
- The module must accept an SNS topic name and look up its ARN internally.
- Wrapper inputs must not require secret values or ARNs.
- The public module tree must contain no client source files or client-specific
  names.
- Every ZIP must include root-level `config.json` and `python/canary.py`.
  `python/canary.py` must provide the fixed Synthetics entry point
  `handler(event, context)` for handler value `canary.handler` and runtime
  `syn-python-selenium-11.1`.
- The module must not expose a runtime-version input. A future runtime change
  requires an explicit module release with compatibility testing.

## Edge Cases

- A missing source file must stop planning with a clear error.
- Every ZIP destination must be a canonical `python/<name>` or
  `python/<directory>/<name>` path: no leading `./` or `/`, no empty segment,
  no `..`, and no normalization. This prevents aliases from replacing the
  generated root `config.json`.
- Every source path must be a safe relative path below the consumer Terraform
  root, must not contain `..` or start with `/`, and must refer to a file
  included in the Terraform Cloud configuration workspace. Source symlinks are
  unsupported because Terraform cannot verify that their targets stay in that
  workspace.
- Every canary must include `python/canary.py`.
- A missing secret or SNS topic name must stop before creating a canary.
- The `config` map must not override the module-generated `secret_name` field.
- The consumer is responsible for not supplying secret material in `config`;
  Terraform cannot identify a secret from an arbitrary string.

## Success Criteria

- A consumer can deploy a canary without creating a ZIP themselves or entering
  an ARN in wrapper YAML.
- The module modifies no pre-existing Secrets Manager secret.
- A neutral integration scenario confirms source files, secret-name lookup,
  alarm creation, and cleanup behavior.
- A source/configuration change produces a different deployment package hash
  and is included in the next canary update.
- Public documentation states that source symlinks are unsupported and that
  consumers must supply real workspace files.
- Two valid module instances in one Terraform root can package same-key
  canaries without ZIP output-path collisions.
- Tests cover rejection of unsafe source/destination paths and attempts to
  supply `config.json`, `./config.json`, or `config.secret_name`.
- Tests cover both an AWS-managed Secrets Manager key (no custom KMS statement)
  and a customer-managed key (one `kms:Decrypt` statement scoped to its key,
  Secrets Manager service, and the looked-up secret ARN).
- Tests confirm no caller-selectable runtime exists and that the generated
  canary uses the pinned Python runtime and handler contract.
- The integration test creates a canary using `syn-python-selenium-11.1` in the
  target AWS region, confirming the AWS-documented runtime is accepted there.
