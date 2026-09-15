"""Minimal public fixture for Terraform infrastructure tests."""

from helper import marker


def handler(event, context):
    """Synthetics entry point used by the neutral fixture ZIP."""
    return {"statusCode": 200, "marker": marker()}
