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


def _group_identity(finding):
    """Only combine findings that share a concrete remediation target."""
    resource = (finding.get("Resources") or [{}])[0]
    tags = resource.get("Tags") or {}
    details = resource.get("Details", {}).get("AwsEc2Instance", {})
    image = details.get("ImageId")
    pool = tags.get("karpenter.sh/nodepool")
    cluster = tags.get("eks:cluster-name") or next(
        (key.removeprefix("kubernetes.io/cluster/") for key in tags
         if key.startswith("kubernetes.io/cluster/")), None
    )
    product = finding.get("ProductName", "Security Hub")
    resource_id = resource.get("Id", "")
    region = resource_id.split(":")[3] if resource_id.startswith("arn:") else os.environ.get("AWS_REGION", "unknown")
    account = finding["AwsAccountId"]
    control = (finding.get("Compliance") or {}).get("SecurityControlId") or (finding.get("ProductFields") or {}).get("ControlId")
    if resource.get("Type") == "AwsEc2Instance" and image and pool and cluster and product == "Inspector":
        parts = (account, region, product, cluster, pool, image)
        label = f"{product} | {cluster}/{pool} | {image}"
    elif resource.get("Type") == "AwsEc2Instance" and image and pool and cluster and product == "Security Hub" and control:
        parts = (account, region, product, control, cluster, pool, image)
        label = f"{control} | {cluster}/{pool} | {image}"
    elif product == "Inspector" and resource.get("Type") == "AwsEc2Instance" and resource_id:
        parts = (account, region, product, "ec2", resource_id, image or "")
        label = f"Inspector | {resource_id.rsplit('/', 1)[-1]} | {image or 'instance'}"
    elif product == "Inspector" and resource.get("Type") == "AwsEcrContainerImage" and (
        digest := resource.get("Details", {}).get("AwsEcrContainerImage", {}).get("ImageDigest")
    ):
        repository = resource["Details"]["AwsEcrContainerImage"].get("RepositoryName") or resource_id
        parts = (account, region, product, "ecr", repository, digest)
        label = f"Inspector | {repository} | {digest[:19]}"
    elif product == "Inspector" and resource.get("Type") == "AwsLambdaFunction" and resource_id:
        parts = (account, region, product, "lambda", resource_id)
        label = f"Inspector | {resource_id.split(':function:', 1)[-1]}"
    else:
        parts = (account, region, product, _finding_key(finding))
        label = f"{product} | {finding.get('Title', 'Security finding')[:80]}"
    return {
        "key": hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest(),
        "label": label,
        "account": account,
        "region": region,
        "product": product,
        "cluster": cluster or "",
        "nodepool": pool or "",
        "image": image or "",
    }


def _compact_finding(finding):
    group = _group_identity(finding)
    resource = (finding.get("Resources") or [{}])[0]
    vulnerabilities = finding.get("Vulnerabilities") or []
    return {
        "finding_key": _finding_key(finding),
        "finding_id": finding["Id"],
        "product_arn": finding["ProductArn"],
        "account": finding["AwsAccountId"],
        "group": group,
        "resource": resource.get("Id", ""),
        "title": finding.get("Title", "Security finding")[:250],
        "vulnerability_ids": sorted({v.get("Id", "") for v in vulnerabilities if v.get("Id")}),
        "exploit_available": "YES" if any(v.get("ExploitAvailable") == "YES" for v in vulnerabilities) else "NO",
        "severity": finding.get("Severity", {}).get("Label", "UNKNOWN"),
        "compliance_status": (finding.get("Compliance") or {}).get("Status", ""),
        "record_state": finding.get("RecordState", "UNKNOWN"),
        "workflow": finding.get("Workflow", {}).get("Status", "UNKNOWN"),
        "created_at": finding["CreatedAt"],
        "updated_at": finding.get("UpdatedAt", finding["CreatedAt"]),
    }


def _record_grouped(table, finding):
    """Keep the latest snapshot; a duplicate event does not create a new digest item."""
    record = _compact_finding(finding)
    key = record["finding_key"]
    current = _get_item(table, key)
    if current.get("notification_updated_at", "") >= record["updated_at"]:
        return False
    if current.get("notification_payload"):
        # Archive events may omit EC2 tags or image details. Keep the first
        # remediation identity so the original group can be closed correctly.
        previous = json.loads(current["notification_payload"])
        record["group"] = previous["group"]
    pending = current.get("notification_pending", "1")
    if current.get("notification_state") not in (None, "ACTIVE") and record["record_state"] == "ACTIVE":
        pending = "1"
    if current.get("notification_payload"):
        severity_rank = {"INFORMATIONAL": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}
        if severity_rank.get(record["severity"], -1) > severity_rank.get(previous["severity"], -1) or (record["exploit_available"] == "YES" and previous["exploit_available"] != "YES"):
            pending = "1"
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression="SET #kind = :kind, #group = :group, #payload = :payload, #updated = :updated, #state = :state, #pending = :pending",
            ConditionExpression="attribute_not_exists(#updated) OR #updated < :updated",
            ExpressionAttributeNames={
                "#kind": "notification_kind", "#group": "notification_group_key",
                "#payload": "notification_payload", "#updated": "notification_updated_at",
                "#state": "notification_state", "#pending": "notification_pending",
            },
            ExpressionAttributeValues={
                ":kind": {"S": "finding"}, ":group": {"S": record["group"]["key"]},
                ":payload": {"S": json.dumps(record, separators=(",", ":"))},
                ":updated": {"S": record["updated_at"]},
                ":state": {"S": record["record_state"]}, ":pending": {"S": pending},
            },
        )
    except ClientError as error:
        if _conditional_failure(error):
            return False
        raise
    return True


def _conditional_failure(error):
    return error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException"


def _claim(table, key, destination, now, mode=None, lifecycle=None):
    token = str(uuid.uuid4())
    names = {"#state": f"{destination}_state", "#lease": f"{destination}_lease", "#token": f"{destination}_token"}
    values = {
        ":pending": {"S": "PENDING"},
        ":retry": {"S": "RETRY"},
        ":now": {"N": str(now)},
        ":lease": {"N": str(now + LEASE_SECONDS)},
        ":token": {"S": token},
    }
    update = "SET #state = :pending, #lease = :lease, #token = :token"
    if mode:
        names["#mode"] = "opsgenie_delivery_mode"
        values[":mode"] = {"S": mode}
        update += ", #mode = :mode"
    condition = "attribute_not_exists(#state) OR #state = :retry OR (#state = :pending AND #lease < :now)"
    if lifecycle:
        names["#life"] = "lifecycle"
        values[":life"] = {"S": lifecycle}
        condition = "(" + condition + ") AND " + (
            "(attribute_not_exists(#life) OR #life = :life)" if lifecycle == "OPEN" else "#life = :life"
        )
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression=update,
            ConditionExpression=condition,
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


def _publish_once(table, sns, key, destination, topic_arn, payload, now, mode=None, lifecycle=None):
    token = _claim(table, key, destination, now, mode, lifecycle)
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


def _get_item(table, key):
    response = table.get_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": key}},
        ConsistentRead=True,
    )
    return {name: next(iter(value.values())) for name, value in response.get("Item", {}).items()}


def _mark_closed(table, key, updated_at):
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression="SET #life = :closed, #resolved = :updated",
            ConditionExpression="(attribute_not_exists(#life) OR #life = :open) AND #slack = :sent AND (attribute_not_exists(#started) OR #started < :updated)",
            ExpressionAttributeNames={"#life": "lifecycle", "#resolved": "resolved_at", "#slack": "slack_state", "#started": "episode_started_at"},
            ExpressionAttributeValues={":closed": {"S": "CLOSED"}, ":open": {"S": "OPEN"}, ":sent": {"S": "SENT"}, ":updated": {"S": updated_at}},
        )
    except ClientError as error:
        if not _conditional_failure(error):
            raise


def _resolution_complete(item):
    return item.get("slack_resolution_state") == "SENT" and (
        item.get("opsgenie_delivery_mode") != "API"
        or item.get("opsgenie_state") != "SENT"
        or item.get("opsgenie_resolution_state") == "SENT"
    )


def _reopen(table, key, updated_at, resolved_at):
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression="SET #life = :open, #started = :updated REMOVE #slack, #ops, #slack_res, #ops_res, #mode",
            ConditionExpression="#life = :closed AND #resolved = :resolved AND #resolved < :updated",
            ExpressionAttributeNames={
                "#life": "lifecycle", "#started": "episode_started_at", "#resolved": "resolved_at",
                "#slack": "slack_state", "#ops": "opsgenie_state", "#slack_res": "slack_resolution_state",
                "#ops_res": "opsgenie_resolution_state", "#mode": "opsgenie_delivery_mode",
            },
            ExpressionAttributeValues={":open": {"S": "OPEN"}, ":closed": {"S": "CLOSED"}, ":updated": {"S": updated_at}, ":resolved": {"S": resolved_at}},
        )
        return True
    except ClientError as error:
        if _conditional_failure(error):
            return False
        raise


def _route_resolution(event, finding, table, sns, key, now, counts):
    item = _get_item(table, key)
    if item.get("slack_state") in {"PENDING", "RETRY"} or item.get("opsgenie_state") in {"PENDING", "RETRY"}:
        raise RuntimeError("Finding creation delivery is pending before resolution")
    if item.get("slack_state") != "SENT":
        counts["skipped"] += 1
        return
    updated_at = finding.get("UpdatedAt", finding["CreatedAt"])
    if item.get("episode_started_at", "") >= updated_at:
        counts["skipped"] += 1
        return
    if item.get("lifecycle") != "CLOSED":
        _mark_closed(table, key, updated_at)
        item = _get_item(table, key)
    if item.get("lifecycle") != "CLOSED" or item.get("resolved_at", "") > updated_at:
        counts["skipped"] += 1
        return
    payload = {**event, "detail": {**event["detail"], "findings": [finding]}}
    status = "ARCHIVED" if finding.get("RecordState") == "ARCHIVED" else "RESOLVED"
    if _publish_once(table, sns, key, "slack_resolution", os.environ["SLACK_TOPIC_ARN"], {**payload, "_dasmeta_resolution_delivery": status}, now, lifecycle="CLOSED"):
        counts["resolved_slack"] += 1
    if item.get("opsgenie_delivery_mode") == "API" and item.get("opsgenie_state") == "SENT":
        if _publish_once(table, sns, key, "opsgenie_resolution", os.environ["HIGH_TOPIC_ARN"], {**payload, "_dasmeta_opsgenie_action": "close"}, now, lifecycle="CLOSED"):
            counts["closed_opsgenie"] += 1


def route_event(event, table, sns, now=None):
    """Route one imported event; callers supply clients for isolated tests."""
    if event.get("source") != "aws.securityhub" or event.get("detail-type") != "Security Hub Findings - Imported":
        return {"slack": 0, "opsgenie": 0, "skipped": 0}
    cutoff = _timestamp(os.environ["FINDING_CUTOVER_AT"])
    now = int(time.time() if now is None else now)
    if os.environ.get("GROUPED_DELIVERY_MODE") == "true":
        counts = {"recorded": 0, "urgent": 0, "urgent_slack": 0, "skipped": 0}
        for finding in event.get("detail", {}).get("findings", []):
            if _timestamp(finding["CreatedAt"]) < cutoff:
                counts["skipped"] += 1
                continue
            counts["recorded"] += int(_record_grouped(table, finding))
            severity = finding.get("Severity", {}).get("Label")
            urgent = severity == "CRITICAL" or (severity == "HIGH" and any(
                vulnerability.get("ExploitAvailable") == "YES" for vulnerability in finding.get("Vulnerabilities") or []
            ))
            if (urgent and (finding.get("Compliance") or {}).get("Status") != "PASSED"
                    and finding.get("RecordState") == "ACTIVE"
                    and finding.get("Workflow", {}).get("Status") in {"NEW", "NOTIFIED"}):
                item = _get_item(table, _finding_key(finding))
                if item.get("notification_updated_at") != finding.get("UpdatedAt", finding["CreatedAt"]) or item.get("notification_state") != "ACTIVE":
                    continue
                group = json.loads(item["notification_payload"])["group"]
                group_key = "group#" + group["key"]
                payload = {**event, "detail": {**event["detail"], "findings": [finding]}, "_dasmeta_group_urgent": True, "_dasmeta_group": group}
                if _publish_once(table, sns, group_key, "urgent", os.environ["HIGH_TOPIC_ARN"], payload, now):
                    counts["urgent"] += 1
                if _publish_once(table, sns, group_key, "urgent_slack", os.environ["SLACK_TOPIC_ARN"], payload, now):
                    counts["urgent_slack"] += 1
                    table.update_item(
                        TableName=os.environ["DELIVERY_TABLE_NAME"],
                        Key={"finding_key": {"S": group_key}},
                        UpdateExpression="SET #open = :open",
                        ExpressionAttributeNames={"#open": "slack_open"},
                        ExpressionAttributeValues={":open": {"S": "1"}},
                    )
                    try:
                        table.update_item(
                            TableName=os.environ["DELIVERY_TABLE_NAME"],
                            Key={"finding_key": {"S": _finding_key(finding)}},
                            UpdateExpression="SET #pending = :done",
                            ConditionExpression="#updated = :updated",
                            ExpressionAttributeNames={"#pending": "notification_pending", "#updated": "notification_updated_at"},
                            ExpressionAttributeValues={":done": {"S": "0"}, ":updated": {"S": item["notification_updated_at"]}},
                        )
                    except ClientError as error:
                        if not _conditional_failure(error):
                            raise
        LOG.info("Security Hub grouped intake counts: %s", counts)
        return counts
    api_mode = os.environ.get("OPSGENIE_API_MODE") == "true"
    counts = {"slack": 0, "opsgenie": 0, "skipped": 0}
    if api_mode:
        counts.update(resolved_slack=0, closed_opsgenie=0, reopened=0)
    for finding in event.get("detail", {}).get("findings", []):
        if _timestamp(finding["CreatedAt"]) < cutoff:
            counts["skipped"] += 1
            continue
        key = _finding_key(finding)
        if api_mode and (finding.get("RecordState") == "ARCHIVED" or finding.get("Workflow", {}).get("Status") == "RESOLVED"):
            _route_resolution(event, finding, table, sns, key, now, counts)
            continue
        if finding.get("RecordState") != "ACTIVE" or finding.get("Workflow", {}).get("Status") not in {"NEW", "NOTIFIED"}:
            counts["skipped"] += 1
            continue
        if api_mode:
            item = _get_item(table, key)
            updated_at = finding.get("UpdatedAt", finding["CreatedAt"])
            if item.get("lifecycle") == "CLOSED":
                if updated_at <= item.get("resolved_at", ""):
                    counts["skipped"] += 1
                    continue
                if not _resolution_complete(item):
                    raise RuntimeError("Resolution delivery is pending before finding reopen")
                if _reopen(table, key, updated_at, item["resolved_at"]):
                    counts["reopened"] += 1
            elif item.get("episode_started_at", "") > updated_at:
                counts["skipped"] += 1
                continue
        payload = {**event, "detail": {**event["detail"], "findings": [finding]}}
        slack_payload = {**payload, "_dasmeta_first_delivery": True}
        if _publish_once(table, sns, key, "slack", os.environ["SLACK_TOPIC_ARN"], slack_payload, now, lifecycle="OPEN" if api_mode else None):
            counts["slack"] += 1
        if finding.get("Severity", {}).get("Label") in HIGH_SEVERITIES:
            if _publish_once(table, sns, key, "opsgenie", os.environ["HIGH_TOPIC_ARN"], payload, now, "API" if api_mode else None, "OPEN" if api_mode else None):
                counts["opsgenie"] += 1
    LOG.info("Security Hub routing counts: %s", counts)
    return counts


def lambda_handler(event, context):
    return route_event(event, boto3.client("dynamodb"), boto3.client("sns"))
