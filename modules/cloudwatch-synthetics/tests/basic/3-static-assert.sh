#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

grep -Eq 'resource "archive_file" "canary_bundle"' "${module_dir}/package.tf"
if grep -Eq '^[[:space:]]*data "archive_file"' "${module_dir}"/*.tf; then
  echo "archive_file must be a resource, not a data source."
  exit 1
fi

grep -Eq 'secret_name[[:space:]]*=[[:space:]]*optional\(string\)' "${module_dir}/variables.tf"
grep -Eq 'memory_in_mb % 64 == 0' "${module_dir}/variables.tf"
grep -Eq 'for_each[[:space:]]*=[[:space:]]*local\.canaries_with_secrets' "${module_dir}/lookups.tf"
grep -Eq 'source_hash[[:space:]]*=[[:space:]]*archive_file\.canary_bundle\[each\.key\]\.output_base64sha256' "${module_dir}/artifact.tf"
grep -Eq 'sha1\("\$\{var\.name_prefix\}:\$\{key\}"\)' "${module_dir}/locals.tf"
grep -Eq 'prefix[[:space:]]*=[[:space:]]*"canaries/"' "${module_dir}/s3.tf"
grep -Eq 'kms:GenerateDataKey\*' "${module_dir}/iam.tf"
grep -Eq 'ec2:CreateNetworkInterface' "${module_dir}/iam.tf"
grep -Eq 's3:ListAllMyBuckets' "${module_dir}/iam.tf"
grep -Eq 'python/helper.py' "${module_dir}/tests/basic/1-example.tf"

if grep -q 'xray:PutTraceSegments' "${module_dir}/iam.tf"; then
  echo "Unused xray:PutTraceSegments must not remain while active_tracing is hardcoded false."
  exit 1
fi

if grep -nE 'script_zip_path|secret_arn|sns_topic_arn|runtime_version = optional' --include='*.tf' -R "${module_dir}"; then
  echo "Deprecated ZIP, ARN, or caller runtime inputs must not remain in the module."
  exit 1
fi
