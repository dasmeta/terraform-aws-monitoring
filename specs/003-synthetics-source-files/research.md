# Research: Source-File CloudWatch Synthetics Canaries

## Decision: use `archive_file` resource for ZIP generation

**Decision**: Use `hashicorp/archive` `archive_file` as a resource with a dynamic `source` block per input file and a fixed block for `config.json`.

**Rationale**: A resource creates the archive in the apply graph and its checksums provide the S3 update signal. HCP Terraform downloads the provider; no OS `zip` tool is needed.

**Alternatives considered**: Consumer-built ZIP keeps source code out of state but adds a packaging workflow; `local-exec` depends on the execution image; archive data-source package lifetime is weaker across separated plan/apply workers.

## Decision: look up existing resources by name

**Decision**: `aws_secretsmanager_secret` receives `secret_name`; `aws_sns_topic` receives `sns_topic_name`.

**Rationale**: Wrapper YAML can reference Terraform Cloud outputs holding names, without ARNs or secret values. Terraform reads secret metadata only; Python calls `GetSecretValue` at runtime.

## Decision: least-privilege secret/KMS runtime policy

**Decision**: Grant `secretsmanager:GetSecretValue` for exactly the looked-up secret ARN. When `kms_key_id` exists, resolve its ARN and add `kms:Decrypt` only for that key with `kms:ViaService` and SecretARN encryption-context conditions.

**Rationale**: Customer-managed keys need decrypt permission; AWS-managed `aws/secretsmanager` does not. Key policy remains an external account responsibility.

**Sources**: [AWS GetSecretValue API](https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html), [AWS Secrets Manager encryption guidance](https://docs.aws.amazon.com/secretsmanager/latest/userguide/security-encryption.html).

## Decision: strict Python runtime/package convention

**Decision**: Pin `syn-python-selenium-11.1`, handler `canary.handler`, required `python/canary.py`, and generated root `config.json`.

**Rationale**: A generic public module cannot safely validate a moving AWS runtime list. A fixed tested contract guarantees Python packaging.

**Sources**: [AWS Python packaging](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries_WritingCanary_Python.html), [AWS Python/Selenium runtimes](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Library_python_selenium.html).

The current AWS runtime documentation explicitly lists `syn-python-selenium-11.1`; the target-region integration test remains required because runtime availability is ultimately checked by the Synthetics API in the deployment region.

## Decision: guard filesystem validation and prove remote-worker packaging

**Decision**: Validate source paths lexically in `var.canaries`, then use an `archive_file` lifecycle precondition with a Terraform conditional expression to call `fileexists` only for a safe relative path. Do not use a simple `safe_path && fileexists(...)` expression. Run HCP Terraform saved-plan/apply and unchanged-source S3-object recreation checks before release.

**Rationale**: Terraform `~> 1.3` variable validation rules may reference only their own variable, so `path.root` and `fileexists` belong in a resource precondition. Lexical checks reject explicit traversal and absolute paths. Terraform cannot inspect a symlink target without an external tool, so symlinked source files are unsupported and the module must not claim it can enforce that their targets remain in the workspace. Archive output is a local file consumed by `aws_s3_object`, so a remote worker lifecycle test is required to demonstrate that the selected archive-resource approach works when the object is recreated on a new worker.

## Decision: document source-code state exposure

**Decision**: Accept source content may be recorded in Terraform plan/state and require restricted state access.

**Rationale**: The consumer explicitly approved this trade-off. It never permits source code in the public module repository.
