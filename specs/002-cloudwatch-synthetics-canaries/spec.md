# Feature Specification: Generic CloudWatch Synthetics Module

**Feature**: 002-cloudwatch-synthetics-canaries
**Status**: Implementing

## Decision

The public module provisions AWS infrastructure only. Consumers provide private
ZIP files containing their canary behavior. The published module contains no
endpoint, vendor protocol, request template, secret value, or client name.

## Requirements

- Accept a `canaries` map with a ZIP path and one Secrets Manager ARN per entry.
- Upload each ZIP as a versioned S3 object and create a canary with the fixed
  handler `canary.handler`.
- Create encrypted private artifact storage by default and a failure alarm using
  `CloudWatchSynthetics/Failed`.
- Make generated artifact bucket names unique across AWS regions for a single
  account and name prefix.
- Keep real consumer code in a private repository or ignored local workspace.

## Acceptance

1. The neutral fixture creates two generic canaries, versioned ZIP objects, and
   failure alarms.
2. The generated default S3 artifact bucket name includes the active AWS region.
3. The public module tree has no client or vendor-specific content.
