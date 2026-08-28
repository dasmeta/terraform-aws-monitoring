import json
import os
import secrets
from datetime import datetime, timezone

from http_utils import http_request
from logging_utils import get_logger
from secret_config import collect_secret_values, get_setting, load_config, redact_message

logger = get_logger(__name__)


def _request_id(config):
    custom = get_setting(config, "REQUEST_ID")
    if custom:
        return custom
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    return f"KS_Monitoring_{stamp}_{os.getpid()}_{secrets.token_hex(4)}"


def _build_v0_v1_body(config, namespace):
    merchant_id = get_setting(config, "MONITORING_MERCHANT_ID", required=True)
    card_number = get_setting(config, "MONITORING_CARD_NUMBER", required=True)
    device_id = get_setting(config, "SOAP_DEVICE_ID", default="PRDFCAPI02")
    operator_id = get_setting(config, "SOAP_OPERATOR_ID", default="KS_Monitoring")
    currency = get_setting(config, "SOAP_CURRENCY", default="EUR")

    return f"""<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:gif="{namespace}">
  <soap:Body>
    <gif:CardInfo>
      <gif:Cardnumber>{card_number}</gif:Cardnumber>
      <gif:PointOfSale>
        <gif:MerchantID>{merchant_id}</gif:MerchantID>
        <gif:DeviceID>{device_id}</gif:DeviceID>
        <gif:OperatorID>{operator_id}</gif:OperatorID>
      </gif:PointOfSale>
      <gif:Currency>{currency}</gif:Currency>
    </gif:CardInfo>
  </soap:Body>
</soap:Envelope>"""


def _build_v2_v3_body(config, namespace, include_merchant_verification=False):
    merchant_id = get_setting(config, "MONITORING_MERCHANT_ID", required=True)
    card_number = get_setting(config, "MONITORING_CARD_NUMBER", required=True)
    verification_code = get_setting(config, "MONITORING_VERIFICATION_CODE", default="")
    device_id = get_setting(config, "SOAP_DEVICE_ID", default="PRDFCAPI02")
    operator_id = get_setting(config, "SOAP_OPERATOR_ID", default="KS_Monitoring")
    request_id = _request_id(config)

    merchant_verification_xml = ""
    if include_merchant_verification:
        merchant_verification = get_setting(config, "SOAP_MERCHANT_VERIFICATION_CODE", default="")
        if merchant_verification:
            merchant_verification_xml = (
                f"<gif:MerchantVerificationCode>{merchant_verification}</gif:MerchantVerificationCode>"
            )

    return f"""<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:gif="{namespace}">
  <soap:Header>
    <gif:Authentication>
      <gif:PointOfSale>
        <gif:MerchantID>{merchant_id}</gif:MerchantID>
        {merchant_verification_xml}
        <gif:DeviceID>{device_id}</gif:DeviceID>
        <gif:OperatorID>{operator_id}</gif:OperatorID>
      </gif:PointOfSale>
    </gif:Authentication>
  </soap:Header>
  <soap:Body>
    <gif:CardInfo>
      <gif:RequestID>{request_id}</gif:RequestID>
      <gif:Cardnumber>{card_number}</gif:Cardnumber>
      <gif:VerificationCode>{verification_code}</gif:VerificationCode>
    </gif:CardInfo>
  </soap:Body>
</soap:Envelope>"""


def _build_envelope(config):
    version = get_setting(config, "SOAP_VERSION", default="v3")

    if version == "v0":
        namespace = "http://ws.telbase.nl/wsdl/pointofsale/giftcard"
        body = _build_v0_v1_body(config, namespace)
    elif version == "v1":
        namespace = "http://ws.telbase.nl/wsdl/pointofsale/giftcard"
        body = _build_v0_v1_body(config, namespace)
    elif version == "v2":
        namespace = "http://pos.fashioncheque.nl/wsdl/v2/giftcard"
        body = _build_v2_v3_body(config, namespace, include_merchant_verification=False)
    elif version == "v3":
        namespace = "http://pos.fashioncheque.nl/wsdl/v3/giftcard"
        body = _build_v2_v3_body(config, namespace, include_merchant_verification=True)
    else:
        raise ValueError(f"Unsupported SOAP_VERSION: {version}")

    return namespace, body


def _validate_soap_response(response_body, card_number):
    lowered = response_body.lower()
    if "<soap:fault" in lowered or "<faultcode>" in lowered:
        raise RuntimeError("SOAP fault detected in response")
    if ">Success<" not in response_body and ">success<" not in lowered:
        raise RuntimeError("Expected Result=Success in SOAP response")
    if ">0<" not in response_body and "<Status>0</Status>" not in response_body:
        raise RuntimeError("Expected Status=0 in SOAP response")
    if card_number not in response_body:
        raise RuntimeError("Expected card number in SOAP response")


def handler(event, context):
    config = load_config()
    secret_values = {}

    try:
        secret_values = collect_secret_values(config)
        endpoint = config["endpoint_url"]
        namespace, envelope = _build_envelope(config)
        card_number = get_setting(config, "MONITORING_CARD_NUMBER", required=True)

        status, response_body = http_request(
            "POST",
            endpoint,
            headers={
                "Content-Type": f'application/soap+xml;charset=UTF-8;action="{namespace}/CardInfo"'
            },
            body=envelope,
        )

        if status != 200:
            raise RuntimeError(f"Unexpected HTTP status: {status}")

        _validate_soap_response(response_body, card_number)

        logger.info("soap_cardinfo check passed for %s", config["canary_name"])
        return {"statusCode": 200, "body": json.dumps({"status": "ok"})}
    except Exception as exc:
        message = redact_message(str(exc), secret_values)
        logger.error("soap_cardinfo check failed: %s", message)
        raise RuntimeError(message) from exc
