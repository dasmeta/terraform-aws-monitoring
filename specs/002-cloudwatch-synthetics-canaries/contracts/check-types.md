# Contract: Check Types

**Module**: `modules/cloudwatch-synthetics`  
**Runtime**: `syn-python-selenium-11.0` (default)

Each check type maps to a packaged Python script. All scripts:

1. Export handler function `handler(event, context)` in `python/canary.py`.
2. Read `ENDPOINT_URL` from environment (set by Terraform).
3. Resolve credentials via `secret_fields` mapping and Secrets Manager.
4. Call shared redaction helper on any exception before re-raising.
5. Return successfully only when assertions pass; any failure fails the Synthetics run.

---

## soap_wsdl

**Purpose**: Verify WSDL document is reachable and structurally valid.

| Input | Source |
|-------|--------|
| `endpoint_url` | Terraform env `ENDPOINT_URL` |
| Auth (optional) | Secret via `secret_fields.username`, `secret_fields.password` |

**Stub assertions** (pending PRTG parity validation):
- HTTP status 200
- Response body contains `wsdl:` OR `definitions` (case-insensitive)

**Default secret_fields**: `{}`

---

## soap_cardinfo

**Purpose**: POST SOAP request to CardInfo endpoint and validate response.

| Input | Source |
|-------|--------|
| `endpoint_url` | `ENDPOINT_URL` |
| Credentials | `secret_fields.username` → secret key |
| | `secret_fields.password` → secret key |
| SOAP action | `secret_fields.soap_action` → secret key OR `environment.SOAP_ACTION` |
| SOAP namespace | Required non-secret `environment.SOAP_NAMESPACE` |
| SOAP request identifiers | Optional `environment.SOAP_DEVICE_ID`, `environment.SOAP_OPERATOR_ID`, and `environment.REQUEST_ID_PREFIX` |

**Stub assertions**:
- HTTP status 200
- Response body does NOT contain `<soap:Fault` or `<faultcode>`

**Default secret_fields**:
```hcl
{
  username   = "username"
  password   = "password"
  soap_action = "soap_action"
}
```

---

## rest_cardinfo

**Purpose**: Call REST CardInfo endpoint and validate JSON response.

| Input | Source |
|-------|--------|
| `endpoint_url` | `ENDPOINT_URL` |
| Auth | `secret_fields.api_key` OR `secret_fields.bearer_token` |

**Stub assertions**:
- HTTP status 200–299
- Response parses as JSON
- Top-level key `status` OR `result` present (configurable via `environment.RESPONSE_STATUS_FIELD`)

**Default secret_fields**:
```hcl
{
  api_key      = "api_key"
  bearer_token = "token"
}
```

---

## blackhawk_management

**Purpose**: HTTPS health check against Blackhawk Network management API.

| Input | Source |
|-------|--------|
| `endpoint_url` | `ENDPOINT_URL` |
| OAuth/client creds | `secret_fields.client_id`, `secret_fields.client_secret` |

**Stub assertions**:
- HTTP status 200
- Response body length > 0

**Default secret_fields**:
```hcl
{
  client_id     = "client_id"
  client_secret = "client_secret"
}
```

---

## Environment variables (all check types)

Set by Terraform from module config (non-secret only):

| Variable | Description |
|----------|-------------|
| `ENDPOINT_URL` | Target URL |
| `SECRET_ARN` | Secrets Manager ARN |
| `SECRET_FIELDS` | JSON-encoded map of logical → secret key names |
| `CHECK_TYPE` | Current check type string |
| `CANARY_NAME` | AWS canary name (for logging) |

Additional per-canary keys from `environment` input merged at deploy time.

`soap_cardinfo` requires `SOAP_NAMESPACE`; the module does not provide a service-specific default.

---

## Failure modes (must fail canary run)

| Condition | Expected behavior |
|-----------|-------------------|
| Assertion mismatch | Raise exception → Success=0 |
| HTTP 4xx/5xx (when not expected) | Raise exception |
| DNS / TLS / connect error | Raise exception |
| Timeout | Synthetics timeout → Success=0 |
| Secret not found / access denied | Raise redacted exception |
| Invalid JSON in secret | Raise redacted exception |

---

## Validation status

> **Pending**: Final request bodies, headers, and assertion rules await application-team review of current PRTG Bash scripts. Stub contracts above unblock infrastructure implementation; update scripts in-place when parity spec is confirmed.
