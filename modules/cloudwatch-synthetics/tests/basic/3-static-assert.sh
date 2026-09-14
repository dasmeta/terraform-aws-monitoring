#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
locals_file="${module_dir}/locals.tf"
variables_file="${module_dir}/variables.tf"
canary_file="${module_dir}/canary.tf"
package_file="${module_dir}/package.tf"
lookups_file="${module_dir}/lookups.tf"
iam_file="${module_dir}/iam.tf"

rg -Fq 'synthetics-${local.region}-${local.account_id}' "${locals_file}"
rg -Fq 'generated_artifact_bucket_name = "${substr(local.sanitized_name_prefix, 0, 63 - length(local.artifact_bucket_suffix) - 1)}-${local.artifact_bucket_suffix}"' "${locals_file}"
rg -Fq 'region     = data.aws_region.current.name' "${locals_file}"
rg -Fq 'sns_topic_name' "${variables_file}"
rg -Fq 'source_files' "${variables_file}"
rg -Fq 'secret_name' "${variables_file}"
rg -Fq 'resource "archive_file" "canary_bundle"' "${package_file}"
rg -Fq 'runtime_version      = local.synthetics_runtime_version' "${canary_file}"
rg -Fq 'handler              = local.synthetics_handler' "${canary_file}"
rg -Fq 'filename = "config.json"' "${package_file}"
rg -Fq 'data "aws_secretsmanager_secret" "canary"' "${lookups_file}"
rg -Fq 'data "aws_kms_key" "secret_encryption"' "${lookups_file}"
rg -Fq 'data "aws_sns_topic" "alerts"' "${lookups_file}"
rg -Fq 'kms:EncryptionContext:SecretARN' "${iam_file}"
rg -Fq 'kms:ViaService' "${iam_file}"
rg -Fq 'key_manager == "CUSTOMER"' "${iam_file}"
rg -Fq 'fileexists("${path.root}/${source.value}") ? file("${path.root}/${source.value}") : ""' "${package_file}"

if rg -n 'script_zip_path|secret_arn|sns_topic_arn|runtime_version = optional' "${module_dir}" --glob '*.tf'; then
  echo "Deprecated ZIP, ARN, or caller runtime inputs must not remain in the module."
  exit 1
fi
