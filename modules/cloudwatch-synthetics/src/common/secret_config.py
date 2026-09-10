import json
import os
import re

import boto3

REDACTED = "***REDACTED***"
BEARER_PATTERN = re.compile(r"Bearer\s+\S+", re.IGNORECASE)
BASIC_PATTERN = re.compile(r"Basic\s+\S+", re.IGNORECASE)


def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    with open(config_path, encoding="utf-8") as handle:
        return json.load(handle)


def load_secret_payload(secret_arn):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response["SecretString"])


def get_setting(config, name, default=None, required=False):
    """
    Read a setting like the old .env files:
    1. config['environment'] from Terraform (non-secret, e.g. SOAP_VERSION)
    2. AWS Secrets Manager JSON using the same key name (e.g. MONITORING_MERCHANT_ID)
    3. secret_fields alias mapping
    4. default
    """
    environment = config.get("environment") or {}
    if name in environment and environment[name] not in (None, ""):
        return environment[name]

    secret_arn = config.get("secret_arn")
    secret_values = {}
    if secret_arn:
        payload = load_secret_payload(secret_arn)
        field_map = config.get("secret_fields") or {}

        if name in payload:
            return payload[name]

        for logical_name, secret_key in field_map.items():
            if logical_name == name and secret_key in payload:
                return payload[secret_key]
            if secret_key == name and secret_key in payload:
                return payload[secret_key]

        secret_values = {key: payload[key] for key in payload if isinstance(payload[key], str)}

    if default is not None:
        return default

    if required:
        raise ValueError(f"Missing required setting: {name}")

    return None


def collect_secret_values(config):
    secret_arn = config.get("secret_arn")
    if not secret_arn:
        return {}

    payload = load_secret_payload(secret_arn)
    return {key: str(value) for key, value in payload.items() if value is not None}


def redact_message(message, secret_values=None):
    redacted = str(message)
    values = secret_values or {}

    for value in values.values():
        if value:
            redacted = redacted.replace(str(value), REDACTED)

    redacted = BEARER_PATTERN.sub(f"Bearer {REDACTED}", redacted)
    redacted = BASIC_PATTERN.sub(f"Basic {REDACTED}", redacted)
    return redacted
