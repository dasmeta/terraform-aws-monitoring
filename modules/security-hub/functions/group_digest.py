"""Reconcile Security Hub and send bounded remediation-group notifications."""

import collections
import json
import logging
import os
import time
import urllib.error
import urllib.parse
from datetime import datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError

from finding_router import _record_grouped, _timestamp
from opsgenie_notifier import _request, _wait_for_request


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
MAX_RECONCILED_FINDINGS = 100000
MAX_LEDGER_ITEMS = 100000
MAX_LEGACY_MIGRATIONS_PER_RUN = 50
QUIET_CLOSE_SECONDS = 3600
HIGH_SEVERITIES = {"HIGH", "CRITICAL"}


def _decode(item):
    return {key: next(iter(value.values())) for key, value in item.items()}


def _get_item(table, key):
    response = table.get_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": key}},
        ConsistentRead=True,
    )
    return _decode(response.get("Item", {}))


def _set_fields(table, key, fields):
    names = {f"#n{index}": name for index, name in enumerate(fields)}
    values = {f":v{index}": {"S": value} for index, value in enumerate(fields.values())}
    expression = "SET " + ", ".join(f"#n{i} = :v{i}" for i in range(len(fields)))
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": key}},
        UpdateExpression=expression,
        ExpressionAttributeNames=names,
        ExpressionAttributeValues=values,
    )


def reconcile_findings(table, securityhub, now):
    """Backfill once, then overlap the last successful checkpoint by one hour."""
    checkpoint = _get_item(table, "group#checkpoint")
    cutover = _timestamp(os.environ["FINDING_CUTOVER_AT"])
    previous = checkpoint.get("reconciled_through")
    last_full = checkpoint.get("last_full_reconcile")
    full = not last_full or now - _timestamp(last_full).timestamp() >= 86400
    since = cutover if full else max(cutover, _timestamp(previous) - timedelta(hours=1))
    end = datetime.fromtimestamp(now, timezone.utc)
    filters = {
        "CreatedAt": [{"Start": cutover.isoformat(), "End": end.isoformat()}],
        "UpdatedAt": [{"Start": since.isoformat(), "End": end.isoformat()}],
    }
    token = None
    seen = 0
    changed = 0
    while True:
        request = {"Filters": filters, "MaxResults": 100}
        if token:
            request["NextToken"] = token
        page = securityhub.get_findings(**request)
        for finding in page.get("Findings", []):
            seen += 1
            if seen > MAX_RECONCILED_FINDINGS:
                raise RuntimeError("Security Hub reconciliation exceeded 100000 findings; widen or partition the worker before continuing")
            changed += int(_record_grouped(table, finding))
        token = page.get("NextToken")
        if not token:
            break
    LOG.info("Security Hub reconciliation: seen=%d changed=%d from=%s", seen, changed, since.isoformat())
    return seen, changed, full


def scan_findings(table):
    items = []
    token = None
    while True:
        request = {
            "TableName": os.environ["DELIVERY_TABLE_NAME"],
            "ProjectionExpression": "notification_kind, notification_payload, notification_pending, notification_updated_at, opsgenie_delivery_mode, opsgenie_state, opsgenie_resolution_state, legacy_group_migrated",
            "ConsistentRead": True,
        }
        if token:
            request["ExclusiveStartKey"] = token
        page = table.scan(**request)
        for item in page.get("Items", []):
            row = _decode(item)
            if row.get("notification_kind") != "finding":
                continue
            record = json.loads(row["notification_payload"])
            if _timestamp(record["created_at"]) < _timestamp(os.environ["FINDING_CUTOVER_AT"]):
                continue
            record["pending"] = row.get("notification_pending", "1") == "1"
            record["legacy_opsgenie"] = row.get("opsgenie_delivery_mode") == "API" and row.get("opsgenie_state") == "SENT" and row.get("opsgenie_resolution_state") != "SENT" and row.get("legacy_group_migrated") != "1"
            items.append(record)
            if len(items) > MAX_LEDGER_ITEMS:
                raise RuntimeError("Security Hub finding ledger exceeded 100000 items; partition the digest before continuing")
        token = page.get("LastEvaluatedKey")
        if not token:
            return items


def summarize_group(records):
    if not records:
        raise ValueError("Cannot summarize an empty finding group")
    new = [record for record in records if record.get("pending", True)]
    active = [record for record in records if record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"}]
    high = [record for record in active if record["severity"] in HIGH_SEVERITIES]
    priority = "P1" if any(record["severity"] == "CRITICAL" or record["exploit_available"] == "YES" for record in high) else "P2" if high else None
    titles = collections.Counter(record["title"] for record in active)
    return {
        "group": records[0]["group"],
        "new_count": len(new),
        "new_records": new,
        "new_severities": dict(collections.Counter(record["severity"] for record in new)),
        "active_count": len(active),
        "high_count": len(high),
        "active_severities": dict(collections.Counter(record["severity"] for record in active)),
        "affected_resources": len({record["resource"] for record in active if record["resource"]}),
        "vulnerability_ids": sorted({identifier for record in active for identifier in record["vulnerability_ids"]}),
        "top_titles": titles.most_common(5),
        "priority": priority,
        "cleared": not active,
        "latest_updated_at": max(record["updated_at"] for record in records),
    }


def _opsgenie_details(summary):
    group = summary["group"]
    return {
        "AWS account": group["account"],
        "Cluster": (group["cluster"] or "n/a")[:50],
        "Node pool": (group["nodepool"] or "n/a")[:50],
        "AMI": (group["image"] or "n/a")[:50],
        "Active findings": str(summary["active_count"]),
        "Affected resources": str(summary["affected_resources"]),
        "Distinct vulnerabilities": str(len(summary["vulnerability_ids"])),
    }


def _opsgenie_message(summary):
    group = summary["group"]
    scope = f"{group['cluster']}/{group['nodepool']}" if group["cluster"] else group["label"]
    image = f" | {group['image']}" if group["image"] else ""
    return f"{os.environ.get('OPSGENIE_ALERT_PREFIX', 'Security Hub')} | {summary['priority']} | {scope}{image} | {summary['affected_resources']} resources"[:130]


def _securityhub_url(group):
    return f"https://console.aws.amazon.com/securityhub/home?region={urllib.parse.quote(group['region'])}#/findings"


def _opsgenie_description(summary):
    group = summary["group"]
    top = ", ".join(summary["vulnerability_ids"][:10]) or ", ".join(title for title, _ in summary["top_titles"])
    return (
        f"Remediation group: {group['label']}\n"
        f"Active findings: {summary['active_count']} on {summary['affected_resources']} resources\n"
        f"Vulnerabilities: {top}\n"
        f"Security Hub: {_securityhub_url(group)}\n"
        "Investigate the shared remediation target; do not treat a terminated node as a vulnerability fix."
    )[:15000]


def _ops_action(method, path, payload):
    response = _request(method, path, payload)
    request_id = response.get("requestId")
    if not request_id:
        raise RuntimeError("Opsgenie group action returned no request ID")
    _wait_for_request(request_id)


def _clear_urgent_claim(table, marker):
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": marker}},
        UpdateExpression="REMOVE #state, #lease, #token",
        ExpressionAttributeNames={"#state": "urgent_state", "#lease": "urgent_lease", "#token": "urgent_token"},
    )


def sync_opsgenie(table, summary, state, now):
    """Create once, update silently, escalate, and close after a quiet hour."""
    group_key = summary["group"]["key"]
    marker = "group#" + group_key
    alias = "securityhub-group-" + group_key
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    priority = summary["priority"]
    if priority:
        if state.get("opsgenie_open") != "1":
            _ops_action("POST", "/v2/alerts", {
                "message": _opsgenie_message(summary),
                "alias": alias,
                "description": _opsgenie_description(summary),
                "priority": priority,
                "source": "AWS Security Hub",
                "tags": ["securityhub-grouped", summary["group"]["product"].lower().replace(" ", "-")],
                "details": _opsgenie_details(summary),
            })
            if state.get("urgent_state") == "SENT":
                # An immediate P1 action may already have created this alias.
                # Enrich it with the complete group on the first reconciliation.
                _ops_action("PUT", path + "/priority?identifierType=alias", {"priority": priority})
                _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
                _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
            _set_fields(table, marker, {"opsgenie_open": "1", "opsgenie_priority": priority})
        else:
            if priority != state.get("opsgenie_priority"):
                _ops_action("PUT", path + "/priority?identifierType=alias", {"priority": priority})
                _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
                _set_fields(table, marker, {"opsgenie_priority": priority})
                if priority == "P2":
                    _clear_urgent_claim(table, marker)
            if summary["new_count"] or str(summary["active_count"]) != state.get("opsgenie_active_count"):
                _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
        _set_fields(table, marker, {"opsgenie_active_count": str(summary["active_count"])})
        return
    if state.get("opsgenie_open") == "1" and now - _timestamp(summary["latest_updated_at"]).timestamp() >= QUIET_CLOSE_SECONDS:
        _ops_action("POST", path + "/close?identifierType=alias", {
            "user": "Security Hub grouped digest", "source": "AWS Security Hub",
            "note": "No active HIGH/CRITICAL findings remain in this remediation group after the quiet period",
        })
        _set_fields(table, marker, {"opsgenie_open": "0", "opsgenie_priority": "", "opsgenie_active_count": "0"})
        _clear_urgent_claim(table, marker)


def migrate_legacy_alerts(table, records, summary, limit=MAX_LEGACY_MIGRATIONS_PER_RUN):
    """Close old per-finding alerts only after their replacement group exists."""
    if summary["priority"] and _get_item(table, "group#" + summary["group"]["key"]).get("opsgenie_open") != "1":
        return 0
    moved = 0
    for record in records:
        if moved >= limit:
            break
        if not record.get("legacy_opsgenie"):
            continue
        alias = "securityhub-" + record["finding_key"]
        path = "/v2/alerts/" + urllib.parse.quote(alias, safe="") + "/close?identifierType=alias"
        try:
            _ops_action("POST", path, {
                "user": "Security Hub grouped digest", "source": "AWS Security Hub",
                "note": "Replaced by remediation-group alert; individual finding remains in Security Hub",
            })
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
        _set_fields(table, record["finding_key"], {"legacy_group_migrated": "1"})
        moved += 1
    return moved


def _slack_payload(summary, closing):
    group = summary["group"]
    return {
        "_dasmeta_group_digest": {
            "label": group["label"], "account": group["account"], "region": group["region"],
            "product": group["product"], "cluster": group["cluster"],
            "nodepool": group["nodepool"], "image": group["image"],
            "new_count": summary["new_count"], "new_severities": summary["new_severities"],
            "active_count": summary["active_count"], "active_severities": summary["active_severities"],
            "affected_resources": summary["affected_resources"],
            "vulnerability_count": len(summary["vulnerability_ids"]),
            "top_titles": summary["top_titles"],
            "sample_new_ids": [record["finding_id"] for record in summary["new_records"][:10]],
            "finding_url": _securityhub_url(group), "closing": closing,
            "groups_changed": summary.get("groups_changed", [])[:15],
            "groups_changed_total": len(summary.get("groups_changed", [])),
            "groups_cleared": summary.get("groups_cleared", [])[:10],
            "groups_cleared_total": len(summary.get("groups_cleared", [])),
            "baseline": summary.get("baseline", False),
        },
        "region": group["region"],
    }


def _acknowledge_new(table, records):
    for record in records:
        try:
            table.update_item(
                TableName=os.environ["DELIVERY_TABLE_NAME"],
                Key={"finding_key": {"S": record["finding_key"]}},
                UpdateExpression="SET #pending = :done",
                ConditionExpression="#updated = :updated",
                ExpressionAttributeNames={"#pending": "notification_pending", "#updated": "notification_updated_at"},
                ExpressionAttributeValues={":done": {"S": "0"}, ":updated": {"S": record["updated_at"]}},
            )
        except ClientError as error:
            if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
            # A newer import arrived during this digest; keep it pending.


def _publish_slack(sns, summary, closing=False):
    sns.publish(
        TopicArn=os.environ["SLACK_TOPIC_ARN"],
        Subject="Security Hub finding digest",
        Message=json.dumps(_slack_payload(summary, closing), separators=(",", ":")),
    )


def send_slack_batch(table, sns, groups, now, initial=False):
    """Bound Slack noise to one message per run, even for fallback groups."""
    changed = []
    cleared = []
    close_keys = set()
    affected = []
    states = {}
    for key, records in groups.items():
        summary = summarize_group(records)
        state = _get_item(table, "group#" + key)
        states[key] = state
        closing = state.get("slack_open") == "1" and summary["cleared"] and now - _timestamp(summary["latest_updated_at"]).timestamp() >= QUIET_CLOSE_SECONDS
        if closing:
            cleared.append(summary["group"]["label"])
            close_keys.add(key)
        if summary["new_count"] or closing:
            changed.append({"label": summary["group"]["label"], "new": summary["new_count"], "active": summary["active_count"]})
            affected.extend(records)
    if not affected:
        if initial:
            for key, records in groups.items():
                if states[key].get("slack_open") != "1" and any(record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"} for record in records):
                    _set_fields(table, "group#" + key, {"slack_open": "1"})
        return False
    summary = summarize_group(affected)
    first = summary["group"]
    summary["group"] = {
        **first,
        "label": f"Security Hub baseline across {len(groups)} remediation groups" if initial else "Security Hub scheduled digest",
        "account": first["account"] if len({record["account"] for record in affected}) == 1 else "multiple",
        "cluster": "", "nodepool": "", "image": "", "product": "Security Hub",
    }
    summary["groups_changed"] = sorted(changed, key=lambda item: (-item["new"], item["label"]))
    summary["groups_cleared"] = cleared
    summary["baseline"] = initial
    _publish_slack(sns, summary)
    _acknowledge_new(table, summary["new_records"])
    for key, records in groups.items():
        state = states[key]
        if any(record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"} for record in records):
            desired = "1"
        elif key in close_keys and state.get("slack_open") == "1":
            desired = "0"
        else:
            continue
        if state.get("slack_open") != desired:
            _set_fields(table, "group#" + key, {"slack_open": desired})
    return True


def run(table, securityhub, sns, now=None):
    now = int(time.time() if now is None else now)
    initial = not _get_item(table, "group#checkpoint").get("reconciled_through")
    seen, changed, full = reconcile_findings(table, securityhub, now)
    groups = collections.defaultdict(list)
    for record in scan_findings(table):
        groups[record["group"]["key"]].append(record)
    sent = 0
    migrated = 0
    failures = []
    for key, records in groups.items():
        summary = summarize_group(records)
        state = _get_item(table, "group#" + key)
        try:
            sync_opsgenie(table, summary, state, now)
        except Exception as error:
            LOG.exception("Opsgenie group delivery failed for %s", key)
            failures.append(error)
    sent += int(send_slack_batch(table, sns, groups, now, initial=initial))
    remaining = MAX_LEGACY_MIGRATIONS_PER_RUN
    for key, records in groups.items():
        if remaining <= 0:
            break
        try:
            moved = migrate_legacy_alerts(table, records, summarize_group(records), remaining)
            migrated += moved
            remaining -= moved
        except Exception as error:
            LOG.exception("Opsgenie legacy migration failed for %s", key)
            failures.append(error)
    if failures:
        raise RuntimeError(f"{len(failures)} Opsgenie group actions failed; Slack digests were processed") from failures[0]
    checkpoint = {"reconciled_through": datetime.fromtimestamp(now, timezone.utc).isoformat()}
    if full:
        checkpoint["last_full_reconcile"] = checkpoint["reconciled_through"]
    _set_fields(table, "group#checkpoint", checkpoint)
    result = {"reconciled": seen, "changed": changed, "groups": len(groups), "slack_digests": sent, "legacy_alerts_migrated": migrated}
    LOG.info("Security Hub group digest: %s", result)
    return result


def lambda_handler(event, context):
    return run(boto3.client("dynamodb"), boto3.client("securityhub"), boto3.client("sns"))
