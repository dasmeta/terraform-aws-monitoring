# Tasks: Group Inspector ECR Image Alerts

- [x] Add a regression test showing two CVEs on one ECR image share a group and deduplicate urgent delivery.
- [x] Add tests showing distinct digests, repositories, accounts, and Regions remain separate; malformed image IDs fall back to per-finding keys.
- [x] Implement Inspector ECR image grouping without changing EC2 or other resource grouping.
- [x] Document the grouping rule and handling of previously opened alerts.
- [x] Run focused Python tests, syntax checks, and targeted Terraform validation.
- [ ] Publish the module change for review; release, consumer upgrade, and production re-enable require the normal delivery gates.
