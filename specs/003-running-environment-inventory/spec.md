# Running workload environment display

## Requirement

An optional, fresh Kubernetes image inventory may enrich grouped Inspector ECR alerts with the environments where an exact image is running. Match account, Region, repository, and digest. Display the running environments separately from the source AWS account environment. A complete inventory with no match displays `No running workload found`; missing or stale evidence displays `Unverified`. The display must not change incident aliases or paging decisions.

## Acceptance

- Exact image matches list all observed environments.
- Stale, incomplete, or unavailable inventory is Unverified.
- The input is optional and leaves existing consumers unchanged.
- Existing incidents receive a description update when the displayed environment changes.
- The snapshot JSON schema, lowercase environment rule, and exact cluster coverage are documented for publishers.
- A consumer using an SSE-KMS customer-managed key can grant the digest Lambda `kms:Decrypt` for that key without broad KMS access.
