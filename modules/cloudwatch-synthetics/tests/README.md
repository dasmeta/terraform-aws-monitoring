# CloudWatch Synthetics module tests

| Scenario | Directory | Coverage |
|----------|-----------|----------|
| Basic two-canary apply | [basic/](./basic/) | Map-based provisioning, IAM, alarms |
| All check types | [check-types/](./check-types/) | `soap_wsdl`, `soap_cardinfo`, `rest_cardinfo`, `blackhawk_management` |
| Alarm on failure | [alarm-on-failure/](./alarm-on-failure/) | HTTP 500 endpoint, alarm wiring |
| Secret redaction | [secret-redaction/](./secret-redaction/) | Forced failure canary with redaction helpers |

Run from any scenario directory:

```bash
terraform init
terraform test
```

All tests use neutral `example.com` hostnames and dummy Secrets Manager values.
