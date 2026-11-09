# Validation

From modules/cloudwatch-alarm-actions, initialize providers and modules, then run terraform test -filter=tests/teams_package_consistency.tftest.hcl. The first run must start without builds/lambda-*.zip. Rerun with archives present. All cloud operations use mock_provider aws; archive operations remain real.

After a reviewed PR merges, verify the published release tag, update the downstream source YAML version, regenerate, and review a fresh state-backed HCP plan. This procedure does not authorize a production apply.
