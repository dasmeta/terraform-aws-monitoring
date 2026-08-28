import json
from datetime import datetime

from http_utils import http_request
from logging_utils import get_logger
from secret_config import collect_secret_values, get_setting, load_config, redact_message

logger = get_logger(__name__)


def _build_request_xml(config):
    transmission_dt = get_setting(
        config,
        "BHN_TRANSMISSION_DATETIME",
        default=datetime.now().strftime("%y%m%d%H%M%S"),
    )
    product_category = get_setting(config, "BHN_PRODUCT_CATEGORY_CODE", default="01")
    spec_version = get_setting(config, "BHN_SPEC_VERSION", default="04")
    trace_number = get_setting(config, "BHN_SYSTEM_TRACE_AUDIT_NUMBER", default="010003")
    network_code = get_setting(config, "BHN_NETWORK_MANAGEMENT_CODE", default="301")

    return f"""<request>
  <header>
    <signature>BHNUMS</signature>
    <details>
      <productCategoryCode>{product_category}</productCategoryCode>
      <specVersion>{spec_version}</specVersion>
    </details>
  </header>
  <transaction>
    <transmissionDateTime>{transmission_dt}</transmissionDateTime>
    <systemTraceAuditNumber>{trace_number}</systemTraceAuditNumber>
    <networkManagementCode>{network_code}</networkManagementCode>
  </transaction>
</request>"""


def handler(event, context):
    config = load_config()
    secret_values = {}

    try:
        secret_values = collect_secret_values(config)
        endpoint = config["endpoint_url"]
        body = _build_request_xml(config)

        status, response_body = http_request(
            "POST",
            endpoint,
            headers={"Content-Type": "application/xml"},
            body=body,
        )

        if status != 200:
            raise RuntimeError(f"Unexpected HTTP status: {status}")

        if "<statusCode>00</statusCode>" not in response_body:
            raise RuntimeError("Expected statusCode 00 in response")
        if "<responseCode>00</responseCode>" not in response_body:
            raise RuntimeError("Expected responseCode 00 in response")

        logger.info("blackhawk_management check passed for %s", config["canary_name"])
        return {"statusCode": 200, "body": json.dumps({"status": "ok"})}
    except Exception as exc:
        message = redact_message(str(exc), secret_values)
        logger.error("blackhawk_management check failed: %s", message)
        raise RuntimeError(message) from exc
