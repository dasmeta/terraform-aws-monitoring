# Plan

## Design

The wrapper currently pins `terraform-aws-modules/notify-slack/aws` 6.7.0. Its formatter indexes `finding["Compliance"]` in three places. The upstream `lambda_source_path` input accepts a local Python source file. Keep the pinned wrapper and add a patched copy of its Python function under `modules/cloudwatch-alarm-actions/functions/`, then pass its module-relative path through `lambda_source_path`.

Use `finding.get("Compliance", {})` for the three reads. Keep the rest of the formatter unchanged. Add focused Python tests for missing compliance on both product branches and for the existing workflow update path. Run Python tests, Terraform init/validate, and an SPM plan against production state after pinning the reviewed commit.

## Safety and compatibility

No public input or output changes. Terraform resource addresses stay the same; Lambda code hash changes and the existing Lambda function may update in place. Production application remains a separate approval gate. The local source copy is Apache-2.0 licensed upstream code and should retain provenance and license notice.

## Evidence

- Production logs: `KeyError: 'Compliance'` in `format_aws_security_hub` after 2026-10-30 10:33 UTC.
- Production metrics 10:35–10:38 UTC: five Lambda invocations and five errors; two messages sent to the Lambda DLQ after apply.
- Upstream v7.5.2 still directly indexes `finding["Compliance"]`; a version bump alone does not resolve the failure.
