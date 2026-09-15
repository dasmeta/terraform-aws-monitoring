#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
repo_dir="$(cd "${module_dir}/../.." && pwd)"
locals_file="${module_dir}/locals.tf"
variables_file="${module_dir}/variables.tf"
canary_file="${module_dir}/canary.tf"
package_file="${module_dir}/package.tf"
lookups_file="${module_dir}/lookups.tf"
iam_file="${module_dir}/iam.tf"
artifact_file="${module_dir}/artifact.tf"
s3_file="${module_dir}/s3.tf"
versions_file="${module_dir}/versions.tf"
example_file="${module_dir}/tests/basic/1-example.tf"
workflow_file="${repo_dir}/.github/workflows/terraform-test.yaml"

grep -Eq 'synthetics-\$\{local\.region\}-\$\{local\.account_id\}' "${locals_file}"
grep -Eq 'data\.aws_region\.current\.name' "${locals_file}"
grep -Eq 'sns_topic_name' "${variables_file}"
grep -Eq 'source_files' "${variables_file}"
grep -Eq 'secret_name[[:space:]]*=[[:space:]]*optional\(string\)' "${variables_file}"
grep -Eq 'memory_in_mb % 64 == 0' "${variables_file}"
grep -Eq 'resource "archive_file" "canary_bundle"' "${package_file}"
grep -Eq 'runtime_version[[:space:]]*=[[:space:]]*local\.synthetics_runtime_version' "${canary_file}"
grep -Eq 'handler[[:space:]]*=[[:space:]]*local\.synthetics_handler' "${canary_file}"
grep -Eq 'filename[[:space:]]*=[[:space:]]*"config.json"' "${package_file}"
grep -Eq 'for_each[[:space:]]*=[[:space:]]*local\.canaries_with_secrets' "${lookups_file}"
grep -Eq 'data "aws_sns_topic" "alerts"' "${lookups_file}"
grep -Eq 'kms:EncryptionContext:SecretARN' "${iam_file}"
grep -Eq 'kms:ViaService' "${iam_file}"
grep -Eq 'key_manager == "CUSTOMER"' "${iam_file}"
grep -Eq 's3:ListAllMyBuckets' "${iam_file}"
grep -Eq 'kms:GenerateDataKey\*' "${iam_file}"
grep -Eq 'ec2:CreateNetworkInterface' "${iam_file}"
grep -Eq 's3:GetObject".*"s3:PutObject' "${iam_file}"
grep -Eq 'source_hash[[:space:]]*=[[:space:]]*archive_file\.canary_bundle\[each\.key\]\.output_base64sha256' "${artifact_file}"
grep -Eq 'sha1\("\$\{var\.name_prefix\}:\$\{key\}"\)' "${locals_file}"
grep -Eq 'prefix[[:space:]]*=[[:space:]]*"canaries/"' "${s3_file}"
grep -Eq 'version[[:space:]]*=[[:space:]]*"~> 2\.7"' "${versions_file}"
grep -Eq 'fileexists\("\$\{path\.root\}/\$\{source\.value\}"\) \? file\("\$\{path\.root\}/\$\{source\.value\}"\) : ""' "${package_file}"
grep -Eq 'python/helper.py' "${example_file}"
grep -Eq 'Verify CloudWatch Synthetics public boundary' "${workflow_file}"

if grep -q 'xray:PutTraceSegments' "${iam_file}"; then
  echo "Unused xray:PutTraceSegments must not remain while active_tracing is hardcoded false."
  exit 1
fi

if [[ -e "${repo_dir}/AGENTS.md" ]]; then
  echo "AGENTS.md must not remain; it is Speckit-generated."
  exit 1
fi

if grep -nE 'script_zip_path|secret_arn|sns_topic_arn|runtime_version = optional' --include='*.tf' -R "${module_dir}"; then
  echo "Deprecated ZIP, ARN, or caller runtime inputs must not remain in the module."
  exit 1
fi
