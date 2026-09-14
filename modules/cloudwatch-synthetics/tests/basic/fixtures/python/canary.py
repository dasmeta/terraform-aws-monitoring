"""Minimal public fixture for Terraform infrastructure tests."""


def handler(event, context):
    """Synthetics entry point used by the neutral fixture ZIP."""
    return {"statusCode": 200}
