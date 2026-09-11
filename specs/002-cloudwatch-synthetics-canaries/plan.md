# Implementation Plan: Generic CloudWatch Synthetics Module

## Architecture

Consumer private ZIP → versioned S3 object → Synthetics canary → failure alarm.

Terraform is `~> 1.3`; the AWS provider range is `>= 5.0, < 7.0`. The public
module has no archive provider and no consumer test code.

## Implementation decisions

- `canaries[*].script_zip_path` is resolved in Terraform's execution workspace.
- The public module only requires the ZIP entry point `canary.handler`.
- Default artifact buckets are private, encrypted, versioned, and use both the
  AWS account ID and active region in their generated names. The prefix is
  dynamically shortened to keep the complete name within S3's 63-character
  limit.
- The module uses `aws_region.current.name` because the newer `.region`
  attribute is unavailable in supported AWS provider 5.x. Migrating it needs a
  future provider minimum-version increase.
- `memory_in_mb` and `active_tracing` remain stable defaults in this release;
  exposing them is deferred because it widens the public interface.

## Verification

- Run the static neutral guard for region-aware naming.
- Run Terraform formatting and validation for the module and fixture.
- Run live apply/destroy only in an approved isolated account.
