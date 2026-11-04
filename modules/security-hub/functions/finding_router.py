"""Deliver each newly discovered Security Hub finding to each destination once."""

import hashlib
import json
import logging
import os
import re
import time
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError
from finding_policy import (environment, exploitable, is_guardduty, is_inspector_ecr,
                            paging_priority, priority_with_reason, project, public_exposure,
                            realtime, risk_context)


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
LEASE_SECONDS = 45
HIGH_SEVERITIES = {"HIGH", "CRITICAL"}


def _timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)


def _timestamp_micros(value):
    instant = _timestamp(value) - datetime(1970, 1, 1, tzinfo=timezone.utc)
    return (instant.days * 86400 + instant.seconds) * 1000000 + instant.microseconds


def _finding_key(finding):
    identity = "|".join(
        (finding["AwsAccountId"], finding["ProductArn"], finding["Id"])
    )
    return hashlib.sha256(identity.encode("utf-8")).hexdigest()


def _group_identity(finding):
    """Only combine findings that share a concrete remediation target."""
    resources = sorted(finding.get("Resources") or [{}], key=lambda item: item.get("Id", ""))
    resource = resources[0]
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
    region = resource_id.split(":")[3] if resource_id.startswith("arn:") else finding.get("Region") or os.environ.get("AWS_REGION", "unknown")
    account = finding["AwsAccountId"]
    control = (finding.get("Compliance") or {}).get("SecurityControlId") or (finding.get("ProductFields") or {}).get("ControlId")
    ecr_details = resource.get("Details", {}).get("AwsEcrContainerImage", {})
    ecr_image_id = re.fullmatch(
        r"arn:[^:]+:ecr:[^:]+:[0-9]{12}:repository/(.+)/sha256:([0-9a-fA-F]{64})",
        resource_id,
    ) if resource.get("Type") == "AwsEcrContainerImage" and product == "Inspector" else None
    ecr_repository = ecr_details.get("RepositoryName") or (ecr_image_id.group(1) if ecr_image_id else resource_id)
    ecr_repositories = {
        item.get("Details", {}).get("AwsEcrContainerImage", {}).get("RepositoryName") or
        item.get("Id", "").split(":repository/", 1)[-1].rsplit("/sha256:", 1)[0]
        for item in resources if item.get("Type") == "AwsEcrContainerImage"
    }
    action = finding.get("Action") or {}
    network = action.get("NetworkConnectionAction") or {}
    probe = (action.get("PortProbeAction") or {}).get("PortProbeDetails") or []
    probe_detail = probe[0] if probe else {}
    source_ip = (network.get("RemoteIpDetails") or {}).get("IpAddressV4") or (probe_detail.get("RemoteIpDetails") or {}).get("IpAddressV4") or ""
    target_port = (network.get("LocalPortDetails") or {}).get("Port") or (probe_detail.get("LocalPortDetails") or {}).get("Port")
    finding_type = (finding.get("Types") or [finding.get("Title", "GuardDuty finding")])[0]
    vulnerability = ""
    package = ""
    if resource.get("Type") == "AwsEc2Instance" and image and pool and cluster and product == "Inspector":
        parts = (account, region, product, cluster, pool, image)
        label = f"{product} | {cluster}/{pool} | {image}"
    elif resource.get("Type") == "AwsEc2Instance" and image and pool and cluster and product == "Security Hub" and control:
        parts = (account, region, product, control, cluster, pool, image)
        label = f"{control} | {cluster}/{pool} | {image}"
    elif product == "Inspector" and resource.get("Type") == "AwsEc2Instance" and resource_id:
        parts = (account, region, product, "ec2", resource_id, image or "")
        label = f"Inspector | {resource_id.rsplit('/', 1)[-1]} | {image or 'instance'}"
    elif product == "Inspector" and resource.get("Type") == "AwsEcrContainerImage" and len(ecr_repositories) > 1:
        parts = (account, region, product, "multiple-ecr-repositories", _finding_key(finding))
        label = "Inspector | multiple container repositories"
        ecr_repository = ""
    elif product == "Inspector" and resource.get("Type") == "AwsEcrContainerImage" and ecr_repository:
        vulnerabilities = finding.get("Vulnerabilities") or []
        identifiers = sorted({v.get("Id", "") for v in vulnerabilities if v.get("Id")})
        packages = sorted({p.get("Name", "") for v in vulnerabilities
                           for p in v.get("VulnerablePackages") or [] if p.get("Name")})
        vulnerability = ",".join(identifiers) or _finding_key(finding)
        package = ",".join(packages) or "unknown package"
        parts = (account, region, environment(finding), project(finding), product, "ecr",
                 ecr_repository, vulnerability, package)
        label = f"Inspector | {ecr_repository} | {vulnerability if identifiers else 'unknown vulnerability'} / {package}"
    elif product == "Inspector" and resource.get("Type") == "AwsLambdaFunction" and resource_id:
        parts = (account, region, product, "lambda", resource_id)
        label = f"Inspector | {resource_id.split(':function:', 1)[-1]}"
    elif is_guardduty(finding):
        parts = (account, region, product, finding_type,
                 ",".join(item.get("Id", "") for item in resources), source_ip, str(target_port or ""))
        label = f"GuardDuty | {finding_type} | {resource_id.rsplit('/', 1)[-1] or 'resource'}"
    elif control and resource_id:
        parts = (account, region, product, control, cluster or resource_id, pool or "")
        label = f"{control} | {cluster + '/' + pool if cluster and pool else resource_id.rsplit('/', 1)[-1]}"
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
        "finding_type": finding_type if is_guardduty(finding) else "",
        "source_ip": source_ip if is_guardduty(finding) else "",
        "target_port": target_port if is_guardduty(finding) else None,
        "environment": environment(finding),
        "project": project(finding),
        "repository": ecr_repository if product == "Inspector" and resource.get("Type") == "AwsEcrContainerImage" else "",
        "vulnerability": vulnerability,
        "package": package,
        "deployment_status": "unknown" if product == "Inspector" and resource.get("Type") == "AwsEcrContainerImage" else "",
    }


def _compact_finding(finding):
    group = _group_identity(finding)
    page_group = _paging_identity(finding, group)
    resource = sorted(finding.get("Resources") or [{}], key=lambda item: item.get("Id", ""))[0]
    vulnerabilities = finding.get("Vulnerabilities") or []
    return {
        "finding_key": _finding_key(finding),
        "finding_id": finding["Id"],
        "product_arn": finding["ProductArn"],
        "account": finding["AwsAccountId"],
        "group": group,
        "page_group": page_group,
        "resource": resource.get("Id", ""),
        "resource_ids": sorted({item.get("Id", "") for item in finding.get("Resources") or [] if item.get("Id")}),
        "title": finding.get("Title", "Security finding")[:250],
        "vulnerability_ids": sorted({v.get("Id", "") for v in vulnerabilities if v.get("Id")}),
        "exploit_available": "YES" if exploitable(finding) else "NO",
        "fix_available": "YES" if any(v.get("FixAvailable") == "YES" for v in vulnerabilities)
                         else "NO" if vulnerabilities and all(v.get("FixAvailable") == "NO" for v in vulnerabilities)
                         else "UNKNOWN",
        "page_priority": paging_priority(finding),
        "priority_reason": priority_with_reason(finding)[1],
        "risk_context": risk_context(finding),
        "public_exposure": public_exposure(finding),
        "severity": finding.get("Severity", {}).get("Label", "UNKNOWN"),
        "compliance_status": (finding.get("Compliance") or {}).get("Status", ""),
        "record_state": finding.get("RecordState", "UNKNOWN"),
        "workflow": finding.get("Workflow", {}).get("Status", "UNKNOWN"),
        "created_at": finding["CreatedAt"],
        "updated_at": finding.get("UpdatedAt", finding["CreatedAt"]),
        "first_seen_at": finding["CreatedAt"],
        "last_seen_at": finding.get("LastObservedAt") or finding.get("UpdatedAt", finding["CreatedAt"]),
        "change_kind": "new",
    }


def _paging_identity(finding, group):
    """Keep remediation keys granular while grouping one application's incident."""
    if not is_inspector_ecr(finding):
        return group
    return _page_group_from_remediation(group)


def _page_group_from_remediation(group, resource=""):
    if group.get("product") != "Inspector":
        return group
    if not group.get("repository") and ":repository/" in resource and "/sha256:" in resource:
        group = {**group, "repository": resource.split(":repository/", 1)[1].rsplit("/sha256:", 1)[0]}
    if not group.get("repository"):
        return group
    project_name = group.get("project") or os.environ.get("SECURITY_PROJECT") or "Unknown"
    environment_name = group.get("environment") or os.environ.get("SECURITY_ENVIRONMENT") or "Unknown"
    parts = (group["account"], group["region"], project_name,
             environment_name, group["repository"], "container-vulnerability")
    return {**group, "project": project_name, "environment": environment_name,
            "key": hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest(),
            "label": f"Container vulnerabilities | {group['repository']}",
            "vulnerability": "", "package": "", "incident_category": "container-vulnerability"}


def _record_grouped(table, finding):
    """Keep the latest snapshot; a duplicate event does not create a new digest item."""
    record = _compact_finding(finding)
    key = record["finding_key"]
    current = _get_item(table, key)
    previous = json.loads(current["notification_payload"]) if current.get("notification_payload") else None
    fallback_key = hashlib.sha256("|".join((
        record["account"], record["group"]["region"], record["group"]["product"], key,
    )).encode("utf-8")).hexdigest()
    old_group = previous["group"] if previous else {}
    migrate_group = bool(previous and old_group["key"] != record["group"]["key"] and
                         (old_group["key"] == fallback_key or
                          (old_group.get("product") == "Inspector" and
                           old_group.get("label", "").startswith(f"Inspector | {record['group'].get('repository')} | sha256:") and
                           record["group"].get("repository"))))
    old_page_key = (previous.get("page_group") or old_group).get("key") if previous else None
    migrate_page = bool(previous and old_page_key != record["page_group"]["key"])
    policy_change = bool(previous and (previous.get("page_priority") != record["page_priority"] or
                         previous.get("priority_reason") != record["priority_reason"]))
    incoming_epoch = _timestamp_micros(record["updated_at"])
    previous_updated = current.get("notification_updated_at")
    previous_epoch = _timestamp_micros(previous_updated) if previous_updated else None
    if previous_epoch is not None and (previous_epoch > incoming_epoch or
                                       previous_epoch == incoming_epoch and not (migrate_group or migrate_page or policy_change)):
        return False
    if current.get("notification_payload"):
        # Archive events may omit EC2 tags or image details. Keep the first
        # remediation identity unless it was a finding-specific fallback.
        if migrate_group:
            record["previous_group_key"] = old_group["key"]
            record["migration_brief_pending"] = True
        else:
            # Preserve the established remediation key while adding newly
            # available display context to older ledger rows.
            record["group"] = {**record["group"], **previous["group"]}
            if previous.get("previous_group_key"):
                record["previous_group_key"] = previous["previous_group_key"]
        if migrate_page:
            record["previous_page_group_key"] = old_page_key
            record["migration_brief_pending"] = True
        elif previous.get("previous_page_group_key"):
            record["previous_page_group_key"] = previous["previous_page_group_key"]
        record["first_seen_at"] = previous.get("first_seen_at", previous["created_at"])
        was_active = previous["record_state"] == "ACTIVE" and previous["workflow"] in {"NEW", "NOTIFIED"}
        is_active = record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"}
        severity_rank = {"INFORMATIONAL": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}
        escalated = (severity_rank.get(record["severity"], -1) > severity_rank.get(previous["severity"], -1)
                     or record["exploit_available"] == "YES" and previous["exploit_available"] != "YES")
        record["change_kind"] = ("reopened" if is_active and not was_active else
                                 "resolved" if was_active and not is_active else
                                 "escalated" if is_active and (escalated or record["page_priority"] == "P1" and previous.get("page_priority") != "P1") else "updated")
    pending = "1" if migrate_group or migrate_page or policy_change else current.get("notification_pending", "1")
    if current.get("notification_state") not in (None, "ACTIVE") and record["record_state"] == "ACTIVE":
        pending = "1"
    if record["change_kind"] in {"new", "escalated", "reopened", "resolved"}:
        pending = "1"
    inactive = record["record_state"] != "ACTIVE" or record["workflow"] == "RESOLVED"
    retention_days = int(os.environ.get("FINDING_RETENTION_DAYS", "365"))
    update_expression = "SET #kind = :kind, #group = :group, #payload = :payload, #updated = :updated, #epoch = :epoch, #state = :state, #pending = :pending"
    update_expression += ", #expiry = :expiry" if inactive else " REMOVE #expiry"
    names = {
        "#kind": "notification_kind", "#group": "notification_group_key",
        "#payload": "notification_payload", "#updated": "notification_updated_at",
        "#epoch": "notification_updated_epoch",
        "#state": "notification_state", "#pending": "notification_pending", "#expiry": "expires_at",
    }
    values = {
        ":kind": {"S": "finding"}, ":group": {"S": record["group"]["key"]},
        ":payload": {"S": json.dumps(record, separators=(",", ":"))},
        ":updated": {"S": record["updated_at"]},
        ":epoch": {"N": str(incoming_epoch)},
        ":observed_updated": {"S": previous_updated or ""},
        ":old_group": {"S": old_group.get("key", fallback_key)},
        ":state": {"S": record["record_state"]}, ":pending": {"S": pending},
    }
    if inactive:
        values[":expiry"] = {"N": str(int(time.time()) + retention_days * 86400)}
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression=update_expression,
            ConditionExpression=("attribute_not_exists(#updated) OR #epoch < :epoch OR "
                                 "(attribute_not_exists(#epoch) AND #updated = :observed_updated) OR "
                                 "(#epoch = :epoch AND #group = :old_group)"),
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
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
    if key.startswith("alert#"):
        names["#expiry"] = "expires_at"
        values[":expiry"] = {"N": str(now + int(os.environ.get("FINDING_RETENTION_DAYS", "365")) * 86400)}
        update += ", #expiry = :expiry"
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
            if not finding.get("CreatedAt"):
                raise ValueError("Security Hub finding is missing CreatedAt; retry delivery")
            if _timestamp(finding["CreatedAt"]) < cutoff:
                counts["skipped"] += 1
                continue
            recorded = _record_grouped(table, finding)
            counts["recorded"] += int(recorded)
            page_priority = paging_priority(finding)
            send_realtime = realtime(finding)
            if send_realtime or page_priority:
                item = _get_item(table, _finding_key(finding))
                if item.get("notification_updated_at") != finding.get("UpdatedAt", finding["CreatedAt"]) or item.get("notification_state") != "ACTIVE":
                    continue
                record = json.loads(item["notification_payload"])
                group = record.get("page_group", record["group"])
                marker = "group#" + group["key"]
                group_state = _get_item(table, marker)
                p1 = page_priority == "P1"
                # Claim by incident priority, so a new P1 can promote an open
                # application P2 without creating another CVE-level alert.
                page_destination = "critical" if p1 else "urgent"
                slack_destination = "critical_slack" if p1 else "urgent_slack"
                if not p1:
                    if group_state.get("critical_state") == "SENT":
                        page_priority = None
                    if group_state.get("critical_slack_state") == "SENT":
                        send_realtime = False
                    elif page_priority and group_state.get("urgent_slack_state") == "SENT" and group_state.get("urgent_state") != "SENT":
                        slack_destination = "escalation_slack"
                payload = {**event, "detail": {**event["detail"], "findings": [finding]},
                           "_dasmeta_group_urgent": True, "_dasmeta_group": group,
                           "_dasmeta_page_priority": page_priority,
                           "_dasmeta_priority_reason": record.get("priority_reason", "")}
                if page_priority and _publish_once(table, sns, marker, page_destination, os.environ["HIGH_TOPIC_ARN"], payload, now):
                    counts["urgent"] += 1
                if send_realtime and _publish_once(table, sns, marker, slack_destination, os.environ["SLACK_TOPIC_ARN"], payload, now):
                    counts["urgent_slack"] += 1
                    table.update_item(
                        TableName=os.environ["DELIVERY_TABLE_NAME"],
                        Key={"finding_key": {"S": marker}},
                        UpdateExpression="SET #open = :open",
                        ExpressionAttributeNames={"#open": "slack_open"},
                        ExpressionAttributeValues={":open": {"S": "1"}},
                    )
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
