"""Deliver each newly discovered Security Hub finding to each destination once."""

import hashlib
import json
import logging
import os
import time
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
LEASE_SECONDS = 45
HIGH_SEVERITIES = {"HIGH", "CRITICAL"}


def _timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)


def _finding_key(finding):
    identity = "|".join(
        (finding["AwsAccountId"], finding["ProductArn"], finding["Id"])
    )
    return hashlib.sha256(identity.encode("utf-8")).hexdigest()


def _conditional_failure(error):
    return error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException"


def _claim(table, key, destination, now):
    token = str(uuid.uuid4())
    names = {"#state": f"{destination}_state", "#lease": f"{destination}_lease", "#token": f"{destination}_token"}
    values = {
        ":pending": {"S": "PENDING"},
        ":retry": {"S": "RETRY"},
        ":now": {"N": str(now)},
        ":lease": {"N": str(now + LEASE_SECONDS)},
        ":token": {"S": token},
    }
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression="SET #state = :pending, #lease = :lease, #token = :token",
            ConditionExpression="attribute_not_exists(#state) OR #state = :retry OR (#state = :pending AND #lease < :now)",
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
        )
    except ClientError as error:
        if _conditional_failure(error):
            return None
        raise
    return token


def _finish(table, key, destination, token, succeeded):
    names = {"#state": f"{destination}_state", "#lease": f"{destination}_lease", "#token": f"{destination}_token"}
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": key}},
        UpdateExpression="SET #state = :state REMOVE #lease, #token",
        ConditionExpression="#state = :pending AND #token = :token",
        ExpressionAttributeNames=names,
        ExpressionAttributeValues={
            ":state": {"S": "SENT" if succeeded else "RETRY"},
            ":pending": {"S": "PENDING"},
            ":token": {"S": token},
        },
    )


def _publish_once(table, sns, key, destination, topic_arn, payload, now):
    token = _claim(table, key, destination, now)
    if token is None:
        return False
    try:
        sns.publish(
            TopicArn=topic_arn,
            Subject="Security Hub finding",
            Message=json.dumps(payload, separators=(",", ":")),
        )
    except Exception:
        _finish(table, key, destination, token, False)
        raise
    _finish(table, key, destination, token, True)
    return True


def route_event(event, table, sns, now=None):
    """Route one imported event; callers supply clients for isolated tests."""
    if event.get("source") != "aws.securityhub" or event.get("detail-type") != "Security Hub Findings - Imported":
        return {"slack": 0, "opsgenie": 0, "skipped": 0}
    cutoff = _timestamp(os.environ["FINDING_CUTOVER_AT"])
    now = int(time.time() if now is None else now)
    counts = {"slack": 0, "opsgenie": 0, "skipped": 0}
    for finding in event.get("detail", {}).get("findings", []):
        if finding.get("RecordState") != "ACTIVE" or finding.get("Workflow", {}).get("Status") not in {"NEW", "NOTIFIED"}:
            counts["skipped"] += 1
            continue
        if _timestamp(finding["CreatedAt"]) < cutoff:
            counts["skipped"] += 1
            continue
        key = _finding_key(finding)
        payload = {**event, "detail": {**event["detail"], "findings": [finding]}}
        slack_payload = {**payload, "_dasmeta_first_delivery": True}
        if _publish_once(table, sns, key, "slack", os.environ["SLACK_TOPIC_ARN"], slack_payload, now):
            counts["slack"] += 1
        if finding.get("Severity", {}).get("Label") in HIGH_SEVERITIES:
            if _publish_once(table, sns, key, "opsgenie", os.environ["HIGH_TOPIC_ARN"], payload, now):
                counts["opsgenie"] += 1
    LOG.info("Security Hub routing counts: %s", counts)
    return counts


def lambda_handler(event, context):
    return route_event(event, boto3.client("dynamodb"), boto3.client("sns"))
