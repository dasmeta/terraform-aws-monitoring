# CloudWatch Synthetics Source-File Design

## Goal

Allow a consumer to provide private Python source-file locations rather than a
prebuilt ZIP. The module builds the ZIP, uses an existing Secrets Manager
secret by name, and creates the canary infrastructure.

## Options considered

1. **Terraform-built ZIP (chosen).** The `hashicorp/archive` provider builds a
   ZIP from the consumer's source files. This makes wrapper usage simple and
   works in Terraform Cloud, but the source-file contents can be recorded in
   Terraform plan/state data. State access must therefore be restricted to
   people permitted to read the private canary code.
2. **Consumer-built ZIP.** This keeps source code out of Terraform state but
   requires a separate local or CI packaging step. It was rejected because the
   consumer should only supply source-file locations.
3. **Shell-based packaging.** A `local-exec` ZIP command would add a machine
   dependency and is not reliable in Terraform Cloud. It was rejected.

## Consumer flow

```text
Private source files + wrapper YAML
  -> module creates ZIP with config.json
  -> module looks up existing secret by name
  -> canary reads the existing secret at runtime
```

The wrapper contains neither a secret value nor an ARN. The existing secret is
not created, updated, or deleted by this module.

## Interface

Each canary provides a `source_files` map. Its keys are destination paths in
the ZIP and its values are local source paths in Terraform's execution
workspace. Each canary also provides `secret_name` and a non-secret `config`
map. The module adds `secret_name` to the generated `config.json`.

The module accepts an SNS topic name rather than an SNS topic ARN. It looks up
the ARN internally for the alarm action.

The module will use the `archive_file` **resource** from the
`hashicorp/archive` provider. A resource, rather than the plan-time data
source, means Terraform creates the ZIP in the apply graph and does not depend
on a speculative-plan worker retaining a local file for a later apply. The ZIP
is written to a deterministic module-managed temporary path under the
Terraform root. Its filename uses a hash of the Terraform root, `name_prefix`,
and canary key; this gives each valid module instance its own namespace. Two
instances using the same `name_prefix` are invalid anyway because their AWS
resource names would collide. The package SHA-256 checksum is used to update
the object sent to AWS when a source file or generated configuration changes.
Terraform Cloud downloads the provider during `terraform init`; no local `zip`
binary is needed.

`source_files` is intentionally a map: ZIP destinations are unique by
definition. Every destination must use the canonical form
`python/<name>` or `python/<directory>/<name>`: no leading `./` or `/`, no
empty path segment, no `..`, and no path normalization. This prevents an alias
such as `./config.json` from shadowing the module-generated root
`config.json`. Every canary must provide the exact canonical destination
`python/canary.py`; helper modules can be placed under `python/`.
Every source path must be a safe relative path below the consumer's Terraform
root, must not contain `..` or start with `/`, and must identify an existing
regular file delivered with the consumer's Terraform Cloud configuration
workspace. Source symlinks are unsupported: Terraform can reject explicit
traversal/absolute paths but cannot prove that a symlink target stays inside the
workspace. The module therefore does not promise to enforce this boundary for a
consumer-provided symlink.

## ZIP runtime contract

Every generated ZIP has this fixed structure:

```text
python/canary.py       required consumer handler
python/...             optional consumer helper modules
config.json            module-generated configuration at ZIP root
```

`aws_synthetics_canary` keeps the fixed handler value `canary.handler` and a
module-pinned `syn-python-selenium-11.1` Python Synthetics runtime. Therefore,
`python/canary.py` must define `def handler(event, context)`. The module does
not define the canary's protocol or endpoint behavior. Its one generic runtime
contract is that consumer code may read the root-level `config.json`, which is
a JSON object containing `secret_name` plus the non-secret string fields from
`config`. `secret_name` is the only required configuration field and contains
the existing secret's name, never its value.

The consumer does not provide a runtime-version input. This avoids accepting a
non-Python, unsupported, or deprecated runtime incompatible with this package
layout. Changing the pinned runtime is an explicit future module release with
tests, documentation, and compatibility review.

`syn-python-selenium-11.1` is verified against AWS's current
[Python/Selenium runtime documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Library_python_selenium.html).
The integration test must create a canary with that exact runtime in the target
AWS region, so a regional availability failure is detected before release.

The `config` input is `map(string)`. It is for non-secret values only. The
module cannot reliably determine whether an arbitrary string is a secret, so
the consumer is responsible for keeping tokens, passwords, and credentials
out of it. The generated `config.json` merges this map with the module-owned
`secret_name`; `config.secret_name` is rejected so a consumer cannot override
the secret lookup target.

## Safety boundaries

- Private source files are never committed to this public module repository.
- `config` is only for non-secret values such as endpoints and environment.
- Existing Secrets Manager secret values never enter Terraform state through
  this module.
- The module derives required AWS ARNs internally from secret and topic names.
- Source-file contents used by the archive provider can enter Terraform
  plan/state data. The consumer must limit state access accordingly.

## Runtime IAM permissions

For each canary, the module looks up the existing secret by its name and grants
its execution role `secretsmanager:GetSecretValue` only for that resulting
secret ARN. For a customer-managed KMS key associated with that secret, it also
grants `kms:Decrypt` only for that key ARN, constrained to requests made
through `secretsmanager.<region>.amazonaws.com` and to that secret ARN through
the `kms:EncryptionContext:SecretARN` condition. The customer-managed key
policy must independently allow this role. A secret using AWS managed
`aws/secretsmanager` does not require the additional KMS statement.

The module never reads a secret value at Terraform time. It only passes the
secret name into `config.json`; the canary retrieves its value at runtime.

## Compatibility

This replaces `script_zip_path`, `secret_arn`, and `sns_topic_arn`. It is a
breaking interface change, acceptable before the first public module release.
Private consumer configurations must migrate to the new input names.

This deliberately replaces the earlier published-module rule that excluded the
archive provider. The exception is bounded to consumer-owned source packaging;
the module still contains no customer scripts, protocol templates, endpoints,
or secret values.
