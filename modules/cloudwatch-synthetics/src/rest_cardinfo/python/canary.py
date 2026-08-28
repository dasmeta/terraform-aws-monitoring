import base64
import hashlib
import hmac
import json
import secrets
from datetime import datetime, timezone
from urllib.parse import quote

from http_utils import http_request
from logging_utils import get_logger
from secret_config import collect_secret_values, get_setting, load_config, redact_message

logger = get_logger(__name__)


def _urlencode_form(value):
    encoded = []
    for char in value:
        if char.isalnum() or char in ".~_-":
            encoded.append(char)
        elif char == " ":
            encoded.append("+")
        else:
            encoded.append(quote(char, safe=""))
    return "".join(encoded).lower()


def _build_authorization(api_key, api_secret, request_url, request_body):
    nonce = secrets.token_hex(16)
    epoch_seconds = str(int(datetime.now(timezone.utc).timestamp()))

    body_md5_b64 = base64.b64encode(hashlib.md5(request_body.encode("utf-8")).digest()).decode("ascii")
    encoded_request_url = _urlencode_form(request_url)
    raw_signature = f"{api_key}post{encoded_request_url}{epoch_seconds}{nonce}{body_md5_b64}"

    secret_bytes = base64.b64decode(api_secret)
    signature = base64.b64encode(
        hmac.new(secret_bytes, raw_signature.encode("utf-8"), hashlib.sha256).digest()
    ).decode("ascii")

    return f"Bearer {api_key}:{signature}:{nonce}:{epoch_seconds}"


def handler(event, context):
    config = load_config()
    secret_values = {}

    try:
        secret_values = collect_secret_values(config)

        api_key = get_setting(config, "REST_API_KEY", required=True)
        api_secret = get_setting(config, "REST_API_SECRET", required=True)
        card_number = get_setting(config, "MONITORING_CARD_NUMBER", required=True)
        merchant_id = get_setting(config, "MONITORING_MERCHANT_ID", required=True)
        verification_code = get_setting(config, "MONITORING_VERIFICATION_CODE", default="")

        request_url = config["endpoint_url"]
        device_id = get_setting(config, "REST_DEVICE_ID", default="KS_Monitoring")
        operator_id = get_setting(config, "REST_OPERATOR_ID", default="REST_API")

        request_id = get_setting(config, "REQUEST_ID") or (
            datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S") + "_" + secrets.token_hex(8)
        )

        request_body = json.dumps(
            {
                "card": {
                    "number": card_number,
                    "verificationCode": verification_code,
                },
                "pointOfSale": {
                    "merchantId": merchant_id,
                    "merchantVerificationCode": " ",
                    "deviceId": device_id,
                    "operatorId": operator_id,
                },
                "requestId": request_id,
            },
            separators=(",", ":"),
        )

        authorization = _build_authorization(api_key, api_secret, request_url, request_body)

        status, response_body = http_request(
            "POST",
            request_url,
            headers={
                "Accept": "application/json, text/json",
                "Content-Type": "application/json",
                "X-Instant-Redeem": "false",
                "Authorization": authorization,
            },
            body=request_body,
        )

        if status != 200:
            raise RuntimeError(f"Unexpected HTTP status: {status}")

        payload = json.loads(response_body)
        response_card_number = payload.get("card", {}).get("number")
        if response_card_number != card_number:
            raise RuntimeError("Response card.number does not match requested card number")

        logger.info("rest_cardinfo check passed for %s", config["canary_name"])
        return {"statusCode": 200, "body": json.dumps({"status": "ok"})}
    except Exception as exc:
        message = redact_message(str(exc), secret_values)
        logger.error("rest_cardinfo check failed: %s", message)
        raise RuntimeError(message) from exc
