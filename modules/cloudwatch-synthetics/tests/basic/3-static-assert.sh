#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
locals_file="${module_dir}/locals.tf"

rg -Fq 'synthetics-${local.region}-${local.account_id}' "${locals_file}"
rg -Fq 'generated_artifact_bucket_name = "${substr(local.sanitized_name_prefix, 0, 63 - length(local.artifact_bucket_suffix) - 1)}-${local.artifact_bucket_suffix}"' "${locals_file}"
rg -Fq 'region     = data.aws_region.current.name' "${locals_file}"
