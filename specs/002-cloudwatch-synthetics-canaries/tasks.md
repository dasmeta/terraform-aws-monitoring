# Tasks: Generic CloudWatch Synthetics Module

- [X] T001 Define the generic ZIP-and-secret module interface.
- [X] T002 Implement versioned ZIP upload, canary, secure artifact storage, and
  `CloudWatchSynthetics/Failed` alarms.
- [X] T003 Add neutral fixture assertions and a public-boundary CI scan.
- [X] T004 Document the private consumer-artifact boundary.
- [X] T005 Add a failing static guard for region-aware bucket names and the
  provider-5-compatible current-region attribute.
- [X] T006 Include the region in generated artifact bucket names while
  retaining `data.aws_region.current.name` for AWS provider 5 compatibility.
- [ ] T007 Verify formatting, static guard, Terraform validation, and a clean
  public-history scan.
- [ ] T008 Run clean apply/destroy in an approved isolated AWS account.
