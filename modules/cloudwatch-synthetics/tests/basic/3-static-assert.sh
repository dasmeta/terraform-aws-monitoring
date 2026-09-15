#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
locals_file="${module_dir}/locals.tf"
variables_file="${module_dir}/variables.tf"
canary_file="${module_dir}/canary.tf"
package_file="${module_dir}/package.tf"
lookups_file="${module_dir}/lookups.tf"
iam_file="${module_dir}/iam.tf"

grep -Fq 'synthetics-${local.region}-${local.account_id}' "${locals_file}"
grep -Fq 'generated_artifact_bucket_name = "${substr(local.sanitized_name_prefix, 0, 63 - length(local.artifact_bucket_suffix) - 1)}-${local.artifact_bucket_suffix}"' "${locals_file}"
grep -Fq 'region     = data.aws_region.current.name' "${locals_file}"
grep -Fq 'sns_topic_name' "${variables_file}"
grep -Fq 'source_files' "${variables_file}"
grep -Fq 'secret_name' "${variables_file}"
grep -Fq 'resource "archive_file" "canary_bundle"' "${package_file}"
grep -Fq 'runtime_version      = local.synthetics_runtime_version' "${canary_file}"
grep -Fq 'handler              = local.synthetics_handler' "${canary_file}"
grep -Fq 'filename = "config.json"' "${package_file}"
grep -Fq 'data "aws_secretsmanager_secret" "canary"' "${lookups_file}"
grep -Fq 'data "aws_kms_key" "secret_encryption"' "${lookups_file}"
grep -Fq 'data "aws_sns_topic" "alerts"' "${lookups_file}"
grep -Fq 'kms:EncryptionContext:SecretARN' "${iam_file}"
grep -Fq 'kms:ViaService' "${iam_file}"
grep -Fq 'key_manager == "CUSTOMER"' "${iam_file}"
grep -Fq 'fileexists("${path.root}/${source.value}") ? file("${path.root}/${source.value}") : ""' "${package_file}"

deprecated_matches="$(find "${module_dir}" -type f -name '*.tf' -exec grep -nE 'script_zip_path|secret_arn|sns_topic_arn|runtime_version = optional' {} + || true)"
if [[ -n "${deprecated_matches}" ]]; then
  printf '%s\n' "${deprecated_matches}"
  echo "Deprecated ZIP, ARN, or caller runtime inputs must not remain in the module."
  exit 1
fi
