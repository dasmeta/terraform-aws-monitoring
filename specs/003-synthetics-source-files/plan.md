# Implementation Plan: Source-File CloudWatch Synthetics Canaries

**Branch**: `003-synthetics-source-files` | **Date**: 2026-09-14 | **Spec**: [spec.md](./spec.md)
**Input**: Approved feature specification for `modules/cloudwatch-synthetics`.

## Summary

Replace consumer-provided ZIP and ARN inputs with a grouped canary object that accepts private, Terraform-root-relative Python source files, an existing secret name, and non-secret configuration. The module builds a deterministic ZIP using the `hashicorp/archive` resource, looks up AWS resource ARNs internally, and keeps secret retrieval exclusively in the canary runtime.

## Technical Context

**Language/Version**: Terraform `~> 1.3`; consumer Python handler compatible with `syn-python-selenium-11.1` (Python 3.12).
**Primary Dependencies**: `hashicorp/aws >= 5.0, < 7.0`; `hashicorp/archive ~> 2.4`.
**Storage**: Existing AWS Secrets Manager secret; module-managed or consumer-owned S3 artifact bucket; Terraform state contains generated-package inputs.
**Testing**: `terraform fmt -check -recursive`, `terraform validate`, repository static boundary script, and non-production apply/destroy test.
**Target Platform**: Local Terraform and HCP Terraform execution; AWS CloudWatch Synthetics Python/Selenium canaries.
**Project Type**: Reusable Terraform submodule.
**Constraints**: No customer code, endpoint, vendor protocol, credentials, or ARNs in public examples; no local `zip` command; source paths must be lexically relative below `path.root`; source symlinks are unsupported and consumers must ensure paths resolve inside their workspace; state access must be restricted.
**Scale/Scope**: One ZIP, S3 object, IAM role, and canary per `canaries` map item.

## Constitution Check

| Gate | Result | Evidence |
|---|---|---|
| Submodule-first | Pass | Scope is only `modules/cloudwatch-synthetics`; root wiring is unchanged. |
| Speckit before module edits | Pass before implementation | Active package is `specs/003-synthetics-source-files`; this file is the plan. `tasks.md` is required before source edits. |
| Safe consumer interface | Pass with approved breaking change | Related fields remain grouped in `canaries`; plan-time validation and no ARN/secret value inputs are specified. |
| Tests and docs together | Pass | Plan includes README, neutral fixture, static checks, and lifecycle validation. |
| Shared governance | Pass | Repository constitution and `AGENTS.md` are the local references; no cross-repository files change. |

**Breaking change approved**: Replace `script_zip_path`, `secret_arn`, `sns_topic_arn`, and caller-selectable `runtime_version` before the first public release. Replace the earlier no-archive-provider rule only for consumer-owned source packaging.

## Research Decisions

See [research.md](./research.md). All implementation unknowns are resolved:

- use `archive_file` **resource**, not data source, so the package is built in the apply graph;
- use AWS data sources for secret/SNS/KMS lookup, never secret-value data;
- pin `syn-python-selenium-11.1` and `canary.handler`;
- validate canonical `python/...` ZIP paths and Terraform-root-relative source paths;
- update S3 content by archive checksum.

## Project Structure

```text
modules/cloudwatch-synthetics/
├── package.tf                         # archive resource and generated config.json
├── lookups.tf                         # secret, custom KMS key, and SNS data sources
├── artifact.tf                        # upload the archive-produced ZIP
├── iam.tf                             # runtime secret/KMS permissions
├── canary.tf                          # fixed Python runtime and handler
├── variables.tf                       # public input contract and validations
├── locals.tf                          # package output paths and derived values
├── versions.tf                        # archive provider declaration
├── README.md                          # generic direct-module and wrapper usage
└── tests/basic/
    ├── fixtures/python/canary.py      # neutral executable fixture
    ├── 0-setup.tf                     # neutral SNS/secret/KMS setup
    ├── 1-example.tf                   # source-file module call(s)
    ├── 2-assert.tf                    # resource and package assertions
    └── 3-static-assert.sh             # public-boundary and contract checks

specs/003-synthetics-source-files/
├── research.md
├── data-model.md
├── contracts/module-input.md
├── quickstart.md
├── plan.md
└── tasks.md                           # created by /speckit.tasks
```

**Structure Decision**: Add narrowly focused `package.tf` and `lookups.tf`. This avoids turning `artifact.tf` or `iam.tf` into mixed packaging, lookup, and permission files.

## File-by-File Implementation Plan

### Task 1: Establish provider and public input contract

**Files:**
- Modify: `modules/cloudwatch-synthetics/versions.tf`
- Modify: `modules/cloudwatch-synthetics/variables.tf`
- Modify: `modules/cloudwatch-synthetics/locals.tf`
- Modify: `AGENTS.md`

- [ ] Add `hashicorp/archive` at `~> 2.4` to `required_providers`; retain existing Terraform/AWS constraints.
- [ ] Replace `sns_topic_arn` with required `sns_topic_name`; validate a non-empty name, not an ARN.
- [ ] Replace `script_zip_path`, `secret_arn`, and `runtime_version` with `source_files = map(string)`, `secret_name = string`, and `config = optional(map(string), {})`; preserve existing optional schedule, timeout, tags, VPC, and alarm fields.
- [ ] In input-variable validations, reject empty source maps/secret names, unsafe source paths (`/`, `..`, empty segments), non-canonical `python/...` destinations, missing `python/canary.py`, and `config.secret_name`. These validations reference only `var.canaries` to remain compatible with Terraform `~> 1.3`. Document that source symlinks are unsupported: Terraform 1.3 cannot prove a symlink resolves inside the workspace.
- [ ] In the `archive_file` resource lifecycle, add a guarded `precondition` for source-file existence. For each path, use a lexical-safe predicate as the conditional condition and call `fileexists("${path.root}/${path}")` only in the true branch; do not use `safe_path && fileexists(...)`. Add regression cases for `../`, absolute, empty-segment, and missing source paths.
- [ ] Add locals for fixed runtime/handler, normalized configuration, and per-instance archive output filename derived from `path.root`, `name_prefix`, and canary key. Keep output under `.terraform`, not module source.
- [ ] Amend `AGENTS.md` only to record the bounded archive-provider exception and state-exposure boundary; preserve the ban on customer code.
- [ ] Run `terraform fmt -check -recursive modules/cloudwatch-synthetics`, `terraform -chdir=modules/cloudwatch-synthetics init -backend=false`, and `validate`.

### Task 2: Build and upload deterministic packages

**Files:**
- Create: `modules/cloudwatch-synthetics/package.tf`
- Modify: `modules/cloudwatch-synthetics/artifact.tf`
- Modify: `modules/cloudwatch-synthetics/outputs.tf`

- [ ] Create one `archive_file` resource per canary. Use dynamic `source` blocks to read `${path.root}/${source_path}` and place it at each map-key destination.
- [ ] Add root `config.json` via `jsonencode(merge(config, { secret_name = secret_name }))`; never read a secret value.
- [ ] Set consistent file mode and use archive checksum as the S3 package-change signal.
- [ ] Change `aws_s3_object.canary_bundle` to use the archive output path/checksum, preserving private/versioned bucket behavior and S3 key scheme.
- [ ] Keep object key/version outputs but update their descriptions from consumer ZIP to module-built source package.
- [ ] First add static checks that fail without the archive resource, generated config, checksum, and non-shell packaging; then implement and make them pass.

### Task 3: Look up named AWS resources and scope runtime IAM

**Files:**
- Create: `modules/cloudwatch-synthetics/lookups.tf`
- Modify: `modules/cloudwatch-synthetics/iam.tf`
- Modify: `modules/cloudwatch-synthetics/alarms.tf`
- Modify: `modules/cloudwatch-synthetics/variables.tf`

- [ ] Add `aws_secretsmanager_secret` per canary using `secret_name`, and one `aws_sns_topic` using `sns_topic_name`. Missing names must fail before canary creation.
- [ ] For secrets with non-null `kms_key_id`, resolve the customer key ARN with `aws_kms_key`; no custom KMS entry exists for AWS-managed secrets.
- [ ] Grant `secretsmanager:GetSecretValue` only to looked-up ARN. Add conditional `kms:Decrypt` only for a customer key, with `kms:ViaService` and `kms:EncryptionContext:SecretARN` conditions.
- [ ] Retain `kms_key_arn` only for artifact encryption; correct its description.
- [ ] Use looked-up SNS ARN in `alarm_actions`.
- [ ] Add assertions for AWS-managed secret (no custom KMS policy statement) and custom key (exact key and conditions).

### Task 4: Lock executable canary contract

**Files:**
- Modify: `modules/cloudwatch-synthetics/canary.tf`
- Modify: `modules/cloudwatch-synthetics/tests/basic/1-example.tf`
- Modify: `modules/cloudwatch-synthetics/tests/basic/2-assert.tf`

- [ ] Remove caller runtime input and set `runtime_version = "syn-python-selenium-11.1"` and `handler = "canary.handler"`.
- [ ] Preserve existing timeout, memory, tracing, VPC, scheduling, tags, and dependency behavior.
- [ ] Configure two neutral module instances with distinct prefixes. Each packages same-key source fixture, proving no output-path collision in one Terraform root.
- [ ] In non-production lifecycle testing, create this exact runtime and inspect canary/role policy with AWS CLI before destroy.
- [ ] Run an HCP Terraform saved-plan/apply using a fresh apply worker. Then force recreation of the uploaded S3 object without changing any source files and apply again. The run must prove the archive is available whenever `aws_s3_object` needs its `source`. If either run fails, stop and redesign packaging before release.

### Task 5: Update neutral tests and public-boundary checks

**Files:**
- Create: `modules/cloudwatch-synthetics/tests/basic/fixtures/python/canary.py`
- Delete: `modules/cloudwatch-synthetics/tests/fixtures/python/canary.py`
- Modify: `modules/cloudwatch-synthetics/tests/basic/0-setup.tf`
- Modify: `modules/cloudwatch-synthetics/tests/basic/1-example.tf`
- Modify: `modules/cloudwatch-synthetics/tests/basic/2-assert.tf`
- Modify: `modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh`
- Modify: `modules/cloudwatch-synthetics/tests/basic/README.md`
- Modify: `modules/cloudwatch-synthetics/tests/README.md`

- [ ] Remove the test-owned prebuilt archive and archive-provider requirement.
- [ ] Keep fixture code public, minimal, endpoint-free, and limited to `handler(event, context)`.
- [ ] Create one default-key secret and one customer-key secret with neutral values only.
- [ ] Assert package uploads, alarms, named lookup inputs, fixed runtime/handler, and two module instances.
- [ ] Extend static checks for generic public boundary, new input names, absence of former ZIP/ARN inputs, and path/config validation.
- [ ] Run static checks once before and once after implementation; expected final result is exit code 0.

### Task 6: Rewrite user documentation and wrapper example

**Files:**
- Modify: `modules/cloudwatch-synthetics/README.md`
- Modify: `modules/cloudwatch-synthetics/main.tf`
- Modify: `specs/003-synthetics-source-files/quickstart.md`

- [ ] Replace prebuilt ZIP/ARN language with source-file, secret-name, and SNS-topic-name interface.
- [ ] Explain fixed ZIP layout, `config.json`, path restriction, and source-code state exposure with no real endpoint/account/client identifiers.
- [ ] Include direct Terraform and DasMeta wrapper YAML. The wrapper receives a Terraform Cloud output resolving to a secret **name**, not ARN/value.
- [ ] Explain: Terraform looks up the secret name and grants runtime permission; Python retrieves secret value during execution.
- [ ] Update module comment from consumer ZIP to consumer source files.

### Task 7: Verify complete change

- [ ] Run `terraform fmt -check -recursive modules/cloudwatch-synthetics`.
- [ ] Run `terraform -chdir=modules/cloudwatch-synthetics init -backend=false` and `validate`.
- [ ] Run `bash modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh`.
- [ ] In dedicated non-production AWS account, run fixture lifecycle: `init`, `plan`, `apply`, AWS canary/IAM inspection, and `destroy`. Never use production.
- [ ] In HCP Terraform, run the saved-plan/apply and unchanged-source S3 recreation checks from Task 4 on a clean remote worker; record run URLs/IDs as release evidence.
- [ ] Search public module tree for banned client-specific identifiers; expected result: no matches.
- [ ] Regenerate README tables with repository tooling, verify unrelated files were not modified, and commit only feature files.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Archive provider exception | Terraform must create a ZIP from multiple consumer files in local and HCP Terraform execution. | Prebuilt ZIP requires a separate manual/CI packaging step, which approved interface removes. |
