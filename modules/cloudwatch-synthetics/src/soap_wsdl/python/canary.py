import json

from http_utils import http_request
from logging_utils import get_logger
from secret_config import collect_secret_values, load_config, redact_message

logger = get_logger(__name__)


def handler(event, context):
    config = load_config()
    secret_values = {}

    try:
        secret_values = collect_secret_values(config)
        url = config["endpoint_url"]

        status, body = http_request("GET", url)

        if status != 200:
            raise RuntimeError(f"Unexpected HTTP status: {status}")

        lowered = body.lower()
        if "wsdl:" not in lowered and "definitions" not in lowered:
            raise RuntimeError("Response does not appear to contain a WSDL document")

        logger.info("soap_wsdl check passed for %s", config["canary_name"])
        return {"statusCode": 200, "body": json.dumps({"status": "ok"})}
    except Exception as exc:
        message = redact_message(str(exc), secret_values)
        logger.error("soap_wsdl check failed: %s", message)
        raise RuntimeError(message) from exc
