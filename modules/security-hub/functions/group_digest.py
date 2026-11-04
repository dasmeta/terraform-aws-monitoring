"""Reconcile Security Hub and send bounded remediation-group notifications."""

import collections
import hashlib
import json
import logging
import os
import time
import urllib.error
import urllib.parse
from datetime import datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError

from finding_router import _page_group_from_remediation, _record_grouped, _timestamp
from group_alert_format import description_header, group_action, group_message, securityhub_url
from opsgenie_notifier import _request, _wait_for_request


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
MAX_RECONCILED_FINDINGS = 100000
MAX_LEDGER_ITEMS = 100000
MAX_LEGACY_MIGRATIONS_PER_RUN = 50
QUIET_CLOSE_SECONDS = 3600
HIGH_SEVERITIES = {"HIGH", "CRITICAL"}
OPSGENIE_FORMAT_VERSION = "4"


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
    active_markers = set()
    closed_markers = set()
    token = None
    while True:
        request = {
            "TableName": os.environ["DELIVERY_TABLE_NAME"],
            "ProjectionExpression": "finding_key, notification_kind, notification_payload, notification_pending, notification_updated_at, opsgenie_delivery_mode, opsgenie_state, opsgenie_resolution_state, legacy_group_migrated, opsgenie_open, urgent_state, critical_state, superseded_group_closed",
            "ConsistentRead": True,
        }
        if token:
            request["ExclusiveStartKey"] = token
        page = table.scan(**request)
        for item in page.get("Items", []):
            row = _decode(item)
            marker = row.get("finding_key", "")
            if marker.startswith("group#"):
                if row.get("opsgenie_open") == "1" or row.get("urgent_state") == "SENT" or row.get("critical_state") == "SENT":
                    active_markers.add(marker.removeprefix("group#"))
                if row.get("superseded_group_closed") == "1":
                    closed_markers.add(marker.removeprefix("group#"))
                continue
            if row.get("notification_kind") != "finding":
                continue
            record = json.loads(row["notification_payload"])
            if record.get("group") and not record.get("page_group"):
                record["page_group"] = _page_group_from_remediation(record["group"], record.get("resource", ""))
                if record["page_group"]["key"] != record["group"]["key"]:
                    record["previous_page_group_key"] = record["group"]["key"]
                    if record["severity"] == "CRITICAL":
                        record["page_priority"] = "P2"
            if _timestamp(record["created_at"]) < _timestamp(os.environ["FINDING_CUTOVER_AT"]):
                continue
            record["pending"] = row.get("notification_pending", "1") == "1"
            record["legacy_opsgenie"] = row.get("opsgenie_delivery_mode") == "API" and row.get("opsgenie_state") == "SENT" and row.get("opsgenie_resolution_state") != "SENT" and row.get("legacy_group_migrated") != "1"
            items.append(record)
            if len(items) > MAX_LEDGER_ITEMS:
                raise RuntimeError("Security Hub finding ledger exceeded 100000 items; partition the digest before continuing")
        token = page.get("LastEvaluatedKey")
        if not token:
            return items, active_markers, closed_markers


def _needs_opsgenie_sync(summary, key, active_markers):
    return bool(summary["priority"] or key in active_markers)


def summarize_group(records, identity="group"):
    if not records:
        raise ValueError("Cannot summarize an empty finding group")
    new = [record for record in records if record.get("pending", True)]
    active = [record for record in records if record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"}]
    high = [record for record in active if record["severity"] in HIGH_SEVERITIES]
    def page_priority(record):
        if "page_priority" in record:
            return record["page_priority"]
        # Existing ledger rows predate the configurable policy.
        if record["group"].get("repository") and record["severity"] == "CRITICAL":
            return "P2"
        return "P1" if record["severity"] == "CRITICAL" else None

    urgent = [record for record in active if page_priority(record)]
    priority = "P1" if any(page_priority(record) == "P1" for record in urgent) else "P2" if urgent else None
    titles = collections.Counter(record["title"] for record in active)
    return {
        "group": records[0].get(identity, records[0]["group"]),
        "new_count": len(new),
        "new_records": new,
        "new_severities": dict(collections.Counter(record["severity"] for record in new)),
        "active_count": len(active),
        "high_count": len(high),
        "urgent_count": len(urgent),
        "high_severities": dict(collections.Counter(record["severity"] for record in high)),
        "urgent_titles": collections.Counter(record["title"] for record in urgent).most_common(3),
        "urgent_vulnerability_ids": sorted({identifier for record in urgent for identifier in record["vulnerability_ids"]}),
        "urgent_signature": hashlib.sha256(json.dumps(
            sorted({(record["finding_key"], record["severity"], record.get("page_priority"),
                     tuple(record["vulnerability_ids"]), tuple(record.get("resource_ids", []))) for record in active}),
            separators=(",", ":"),
        ).encode("utf-8")).hexdigest(),
        "sample_resource": next((record["resource"] for record in high if record["resource"]), ""),
        "active_severities": dict(collections.Counter(record["severity"] for record in active)),
        "affected_resources": len({resource for record in active for resource in record.get("resource_ids", [record["resource"]]) if resource}),
        "affected_images": len({resource for record in active for resource in record.get("resource_ids", [record["resource"]]) if "/sha256:" in resource}),
        "public_exposure_count": sum(bool(record.get("public_exposure")) for record in active),
        "vulnerability_ids": sorted({identifier for record in active for identifier in record["vulnerability_ids"]}),
        "top_vulnerabilities": sorted({f"{identifier} — {record['group'].get('package') or 'package unknown'}"
                                        for record in active for identifier in record["vulnerability_ids"]})[:5],
        "top_titles": titles.most_common(5),
        "priority": priority,
        "cleared": not active,
        "latest_updated_at": max(record["updated_at"] for record in records),
        "first_seen_at": min(record.get("first_seen_at", record["created_at"]) for record in records),
        "priority_reasons": sorted({record.get("priority_reason", "") for record in urgent if record.get("priority_reason")}),
        "deployment_status": "deployed" if any(record.get("risk_context", {}).get("deployment") == "deployed" for record in active)
                             else "unused" if active and all(record.get("risk_context", {}).get("deployment") == "unused" for record in active)
                             else "unknown",
        "exposure_status": "exposed" if any(record.get("risk_context", {}).get("exposure") == "exposed" for record in active)
                           else "unexposed" if active and all(record.get("risk_context", {}).get("exposure") == "unexposed" for record in active)
                           else "unknown",
        "fix_status": "available" if active and all(record.get("fix_available") == "YES" for record in active)
                      else "partially available" if any(record.get("fix_available") == "YES" for record in active)
                      else "unavailable" if active and all(record.get("fix_available") == "NO" for record in active)
                      else "unknown",
    }


def _opsgenie_details(summary):
    group = summary["group"]
    details = {
        "AWS account": group["account"],
        "Active findings": str(summary["active_count"]),
        "Affected resources": str(summary["affected_resources"]),
        "Distinct vulnerabilities": str(len(summary["vulnerability_ids"])),
    }
    if group.get("incident_category") == "container-vulnerability":
        details.update({"Application": group["repository"][:100], "Affected images": str(summary["affected_images"]),
                        "Deployment status": summary["deployment_status"], "Exposure status": summary["exposure_status"]})
    else:
        details.update({"Cluster": (group["cluster"] or "n/a")[:50],
                        "Node pool": (group["nodepool"] or "n/a")[:50], "AMI": (group["image"] or "n/a")[:50]})
    return details


def _opsgenie_message(summary):
    prefix = os.environ.get("OPSGENIE_ALERT_PREFIX", "Security Hub")
    return group_message(summary["group"], prefix, summary["priority"])


def _securityhub_url(group):
    return securityhub_url(group)


def _opsgenie_description(summary):
    group = summary["group"]
    if group.get("incident_category") == "container-vulnerability":
        top = "\n".join(f"- {item}" for item in summary["top_vulnerabilities"]) or "- Vulnerability metadata unavailable"
        return (
            f"Priority: {summary['priority']}\nEnvironment: {group.get('environment') or 'Unknown'}\n"
            f"AWS account: {group['account']}\nRegion: {group['region']}\nApplication: {group['repository']}\n"
            f"Critical: {summary['active_severities'].get('CRITICAL', 0)} | High: {summary['active_severities'].get('HIGH', 0)}\n"
            f"Distinct vulnerabilities: {len(summary['vulnerability_ids'])}\n"
            f"Affected resources: {summary['affected_resources']} | Images: {summary['affected_images']}\n"
            f"Deployment: {summary['deployment_status']} | Exposure: {summary['exposure_status']}\n"
            f"Fix availability: {summary['fix_status']}\n"
            f"Escalation reason: {'; '.join(summary['priority_reasons']) or 'Configured investigation policy'}\n"
            f"Top vulnerabilities:\n{top}\n"
            "Recommended action: Verify deployment, exploitability, network exposure, and patched version availability.\n"
            f"Security Hub: {_securityhub_url(group)}\n"
            f"First detected: {summary['first_seen_at']}\nLast updated: {summary['latest_updated_at']}"
        )[:15000]
    top = ", ".join(summary["urgent_vulnerability_ids"][:10]) or ", ".join(title for title, _ in summary["urgent_titles"])
    severities = ", ".join(f"{label} {summary['high_severities'].get(label, 0)}" for label in ("CRITICAL", "HIGH"))
    return (
        description_header(group)
        + f"Urgent findings: {summary['urgent_count']}; HIGH/CRITICAL findings: {summary['high_count']} ({severities})\n"
        f"Affected resources: {summary['affected_resources']}\n"
        f"Urgent vulnerabilities or controls: {top}\n"
        f"Example resource: {summary['sample_resource'] or 'n/a'}\n"
        f"Security Hub: {_securityhub_url(group)}\n"
        "Patch the shared image or control; verify the finding resolves in Security Hub before closing this alert."
    )[:15000]


def _ops_action(method, path, payload):
    response = _request(method, path, payload)
    request_id = response.get("requestId")
    if not request_id:
        raise RuntimeError("Opsgenie group action returned no request ID")
    _wait_for_request(request_id)


def _close_opsgenie_alias(alias, note):
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    try:
        alert = _request("GET", path + "?identifierType=alias").get("data")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        return
    if not alert or alert.get("status") == "closed":
        return
    _ops_action("POST", path + "/close?identifierType=alias", {
        "user": "Security Hub grouped digest", "source": "AWS Security Hub", "note": note,
    })


def _ensure_opsgenie_priority(alias, priority):
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    alert = _request("GET", path + "?identifierType=alias").get("data") or {}
    if alert.get("priority") != priority:
        _ops_action("PUT", path + "/priority?identifierType=alias", {"priority": priority})


def _clear_urgent_claim(table, marker):
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": marker}},
        UpdateExpression="REMOVE #state, #lease, #token, #slack_state, #slack_lease, #slack_token, #critical_state, #critical_lease, #critical_token, #critical_slack_state, #critical_slack_lease, #critical_slack_token, #escalation_state, #escalation_lease, #escalation_token",
        ExpressionAttributeNames={"#state": "urgent_state", "#lease": "urgent_lease", "#token": "urgent_token",
                                  "#slack_state": "urgent_slack_state", "#slack_lease": "urgent_slack_lease", "#slack_token": "urgent_slack_token",
                                  "#critical_state": "critical_state", "#critical_lease": "critical_lease", "#critical_token": "critical_token",
                                  "#critical_slack_state": "critical_slack_state", "#critical_slack_lease": "critical_slack_lease", "#critical_slack_token": "critical_slack_token",
                                  "#escalation_state": "escalation_slack_state", "#escalation_lease": "escalation_slack_lease", "#escalation_token": "escalation_slack_token"},
    )


def sync_opsgenie(table, summary, state, now):
    """Create once, update silently, escalate, and close after a quiet hour."""
    group_key = summary["group"]["key"]
    marker = "group#" + group_key
    alias = "securityhub-group-" + group_key
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    priority = summary["priority"]
    if priority:
        if state.get("opsgenie_no_urgent_since"):
            _set_fields(table, marker, {"opsgenie_no_urgent_since": ""})
        if state.get("opsgenie_open") != "1":
            try:
                remote = _request("GET", path + "?identifierType=alias").get("data") or {}
            except urllib.error.HTTPError as error:
                if error.code != 404:
                    raise
                remote = {}
            if remote.get("status", "").lower() == "open":
                if remote.get("priority") != priority:
                    _ensure_opsgenie_priority(alias, priority)
            else:
                _ops_action("POST", "/v2/alerts", {
                    "message": _opsgenie_message(summary),
                    "alias": alias,
                    "description": _opsgenie_description(summary),
                    "priority": priority,
                    "source": "AWS Security Hub",
                    "tags": ["securityhub-grouped", summary["group"]["product"].lower().replace(" ", "-")],
                    "details": _opsgenie_details(summary),
                })
            # Record confirmed creation before optional enrichment. A failed
            # update then retries the update, not the create notification.
            _set_fields(table, marker, {"opsgenie_open": "1", "opsgenie_priority": priority})
            if remote or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
                # An immediate P1 action may already have created this alias.
                # Enrich it with the complete group on the first reconciliation.
                _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
                _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
            _set_fields(table, marker, {"opsgenie_format_version": OPSGENIE_FORMAT_VERSION,
                                        "opsgenie_urgent_signature": summary["urgent_signature"],
                                        "opsgenie_last_update_at": datetime.fromtimestamp(now, timezone.utc).isoformat()})
        else:
            reformat = state.get("opsgenie_format_version") != OPSGENIE_FORMAT_VERSION
            changed_urgent = state.get("opsgenie_urgent_signature") != summary["urgent_signature"]
            if priority != state.get("opsgenie_priority"):
                _ensure_opsgenie_priority(alias, priority)
                _set_fields(table, marker, {"opsgenie_priority": priority})
            if priority != state.get("opsgenie_priority") or reformat:
                _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
            if changed_urgent or reformat or priority != state.get("opsgenie_priority"):
                _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
                _set_fields(table, marker, {"opsgenie_urgent_signature": summary["urgent_signature"],
                                            "opsgenie_last_update_at": datetime.fromtimestamp(now, timezone.utc).isoformat(),
                                            "opsgenie_active_count": str(summary["active_count"])})
            if reformat:
                _set_fields(table, marker, {"opsgenie_format_version": OPSGENIE_FORMAT_VERSION})
        return
    if state.get("opsgenie_open") == "1" or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
        if summary.get("active_count", 0):
            LOG.warning("Keeping Opsgenie incident open while %d active findings remain for %s", summary["active_count"], group_key)
            return
        quiet_since = state.get("opsgenie_no_urgent_since")
        if not quiet_since:
            _set_fields(table, marker, {"opsgenie_no_urgent_since": datetime.fromtimestamp(now, timezone.utc).isoformat()})
            return
        if now - _timestamp(quiet_since).timestamp() < int(os.environ.get("QUIET_PERIOD_SECONDS", str(QUIET_CLOSE_SECONDS))):
            return
        _close_opsgenie_alias(alias,
            "No active findings meet the paging policy after the quiet period; review remaining findings in Security Hub")
        _set_fields(table, marker, {"opsgenie_open": "0", "opsgenie_priority": "", "opsgenie_active_count": "0",
                                    "opsgenie_format_version": "", "opsgenie_urgent_signature": "", "opsgenie_last_update_at": "",
                                    "opsgenie_no_urgent_since": ""})
        _clear_urgent_claim(table, marker)


def migrate_legacy_alerts(table, records, summary, limit=MAX_LEGACY_MIGRATIONS_PER_RUN):
    """Close old per-finding alerts only after their replacement group exists."""
    replacement_open = _get_item(table, "group#" + summary["group"]["key"]).get("opsgenie_open") == "1"
    digest_represented = (os.environ.get("DAILY_DIGEST_ENABLED", "true") == "true" and
                          all(not record.get("pending", True) for record in records))
    if not replacement_open and not digest_represented:
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


def migrate_previous_groups(table, groups, closed_markers=None):
    """Close a stale fallback alert after its new remediation group is open."""
    active_keys = set(groups)
    closed_markers = closed_markers or set()
    moved = 0
    for key, records in groups.items():
        old_keys = {old for record in records for old in
                    (record.get("previous_group_key"), record.get("previous_page_group_key"))}
        old_keys.discard(None)
        if not old_keys:
            continue
        if (_get_item(table, "group#" + key).get("opsgenie_open") != "1" and
                not (os.environ.get("DAILY_DIGEST_ENABLED", "true") == "true" and
                     any(_actionable(record) for record in records) and
                     all(not record.get("pending") for record in records))):
            continue
        for old_key in old_keys - active_keys:
            if old_key in closed_markers:
                continue
            marker = "group#" + old_key
            state = _get_item(table, marker)
            if state.get("superseded_group_closed") == "1":
                continue
            if state.get("opsgenie_open") == "1" or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
                _close_opsgenie_alias("securityhub-group-" + old_key,
                                      "Replaced by a remediation-group alert for the same resource")
            _set_fields(table, marker, {"opsgenie_open": "0", "superseded_group_closed": "1"})
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
            "routine_count": summary.get("routine_count", 0),
            "routine_severities": summary.get("routine_severities", {}),
            "active_count": summary["active_count"], "active_severities": summary["active_severities"],
            "affected_resources": summary["affected_resources"],
            "vulnerability_count": len(summary["vulnerability_ids"]),
            "top_titles": summary["top_titles"],
            "sample_new_ids": [],
            "finding_url": _securityhub_url(group), "closing": closing,
            "groups_changed": summary.get("groups_changed", [])[:15],
            "groups_changed_total": summary.get("groups_changed_total", len(summary.get("groups_changed", []))),
            "other_group_count": summary.get("other_group_count", 0),
            "groups_cleared": summary.get("groups_cleared", [])[:10],
            "groups_cleared_total": len(summary.get("groups_cleared", [])),
            "baseline": summary.get("baseline", False),
            "digest_kind": summary.get("digest_kind"),
            "application_summaries": summary.get("application_summaries", []),
            "environment": summary.get("environment", group.get("environment", "Unknown")),
            "account_label": summary.get("account_label", group["account"]),
            "top_groups": summary.get("top_groups", []),
            "quiet_count": summary.get("quiet_count", 0),
            "resolved_count": summary.get("resolved_count", 0),
            "regions": summary.get("regions", [group["region"]]),
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


def _actionable(record):
    return (record["record_state"] == "ACTIVE" and record["workflow"] in {"NEW", "NOTIFIED"}
            and record["severity"] not in {"INFORMATIONAL", "UNKNOWN"}
            and record.get("compliance_status") != "PASSED")


def _batch_due(checkpoint, field, seconds, now):
    previous = checkpoint.get(field)
    return not previous or now - _timestamp(previous).timestamp() >= seconds


def _migration_slack_due(groups):
    return any(record.get("migration_brief_pending") and record.get("pending")
               for records in groups.values() for record in records)


def _daily_due(checkpoint, now):
    if os.environ.get("DAILY_DIGEST_ENABLED", "true") != "true":
        return False
    current = datetime.fromtimestamp(now, timezone.utc)
    if current.hour < int(os.environ.get("DAILY_DIGEST_HOUR_UTC", "8")):
        return False
    previous = checkpoint.get("last_daily_slack_at")
    return not previous or _timestamp(previous).date() < current.date()


def _group_rank(summary):
    """Risk before volume: severity, active GuardDuty, exposure, then breadth and change."""
    group = summary["group"]
    severity = summary["active_severities"]
    level = 4 if severity.get("CRITICAL") else 3 if severity.get("HIGH") else 2 if severity.get("MEDIUM") else 1
    return (-level, -(group["product"] in {"GuardDuty", "Amazon GuardDuty"}),
            -summary.get("public_exposure_count", 0), -summary["affected_resources"],
            -summary["new_count"], group["label"], group["key"])


def send_slack_batch(table, sns, groups, now, initial=False):
    """Publish one UTC daily view of all active groups and changes since the last brief."""
    summaries = []
    active_records = []
    new_records = []
    pending_records = []
    quiet_groups = []
    resolved_groups = []
    states = {}
    quiet_seconds = int(os.environ.get("QUIET_PERIOD_SECONDS", str(QUIET_CLOSE_SECONDS)))
    for key, records in groups.items():
        state = _get_item(table, "group#" + key)
        states[key] = state
        active = [record for record in records if _actionable(record)]
        active_records.extend(active)
        pending_records.extend(record for record in records if record.get("pending"))
        changed = [record for record in active if record.get("pending") and
                   record.get("change_kind", "new") in {"new", "escalated", "reopened"}]
        if not initial:
            new_records.extend(changed)
        if active:
            summary = summarize_group(records)
            summary["new_count"] = 0 if initial else len(changed)
            summary["active_count"] = len(active)
            summary["active_severities"] = dict(collections.Counter(record["severity"] for record in active))
            summaries.append(summary)
        elif state.get("slack_open") == "1" and now - _timestamp(max(record["updated_at"] for record in records)).timestamp() >= quiet_seconds:
            quiet_groups.append(records[0]["group"]["label"])
            if all(record["record_state"] != "ACTIVE" or record["workflow"] == "RESOLVED" for record in records):
                resolved_groups.append(records[0]["group"]["label"])

    summaries.sort(key=_group_rank)
    applications = collections.defaultdict(lambda: {"images": set(), "vulnerabilities": set(), "findings": 0,
                                                "new": 0, "critical": 0, "high": 0, "group": None})
    for item in summaries:
        group = item["group"]
        if group.get("product") != "Inspector" or not group.get("repository"):
            continue
        boundary = (group["account"], group["region"], group.get("project", "Unknown"),
                    group.get("environment", "Unknown"), group["repository"])
        app = applications[boundary]
        app["group"] = group
        app["findings"] += item["active_count"]
        app["new"] += item["new_count"]
        app["critical"] += item["active_severities"].get("CRITICAL", 0)
        app["high"] += item["active_severities"].get("HIGH", 0)
        app["vulnerabilities"].update(item["vulnerability_ids"])
        app["images"].update(resource for record in groups[group["key"]] if _actionable(record)
                             for resource in record.get("resource_ids", [record["resource"]]) if "/sha256:" in resource)
    application_summaries = [{"repository": boundary[4], "images": len(app["images"]),
                              "vulnerabilities": len(app["vulnerabilities"]), "findings": app["findings"],
                              "new": app["new"], "critical": app["critical"], "high": app["high"],
                              "deployment_status": "unknown",
                              "url": _securityhub_url(app["group"])}
                             for boundary, app in applications.items()]
    application_summaries.sort(key=lambda item: (-bool(item["critical"]), -item["critical"],
                                                       -item["new"], -item["vulnerabilities"], item["repository"]))
    max_groups = int(os.environ.get("DAILY_DIGEST_MAX_GROUPS", "5"))
    selected = [item for item in summaries if not (item["group"].get("repository") and
                item["group"].get("product") == "Inspector")][:max_groups]
    sample = (active_records or [record for records in groups.values() for record in records])
    first_group = sample[0]["group"] if sample else {
        "key": "daily", "label": "Security Hub daily digest", "account": "unknown",
        "region": os.environ.get("AWS_REGION", "unknown"), "product": "Security Hub",
        "cluster": "", "nodepool": "", "image": "",
    }
    regions = sorted({record["group"]["region"] for record in active_records}) or [first_group["region"]]
    accounts = {record["account"] for record in active_records}
    resources = {resource for record in active_records for resource in record.get("resource_ids", [record["resource"]]) if resource}
    vulnerabilities = {identifier for record in active_records for identifier in record["vulnerability_ids"]}
    summary = {
        "group": {**first_group, "label": "Security Hub daily digest", "product": "Security Hub",
                  "account": next(iter(accounts)) if len(accounts) == 1 else "multiple" if accounts else first_group["account"]},
        "new_count": len(new_records), "new_records": new_records,
        "new_severities": dict(collections.Counter(record["severity"] for record in new_records)),
        "routine_count": sum(record.get("pending", False) and not _actionable(record)
                             for records in groups.values() for record in records),
        "routine_severities": {}, "active_count": len(active_records),
        "active_severities": dict(collections.Counter(record["severity"] for record in active_records)),
        "affected_resources": len(resources), "vulnerability_ids": sorted(vulnerabilities),
        "top_titles": [], "baseline": initial, "digest_kind": "daily",
        "application_summaries": application_summaries,
        "groups_changed": [{"label": item["group"]["label"], "new": item["new_count"],
                            "active": item["active_count"]} for item in selected],
        "groups_cleared": quiet_groups, "quiet_count": len(quiet_groups),
        "resolved_count": len(resolved_groups), "regions": regions,
        "environment": os.environ.get("SECURITY_ENVIRONMENT") or first_group.get("environment", "Unknown"),
        "account_label": os.environ.get("SECURITY_ACCOUNT_LABEL") or
                         (next(iter(accounts)) if len(accounts) == 1 else "Multiple accounts" if accounts else first_group["account"]),
        "top_groups": [{"label": item["group"]["label"], "product": item["group"]["product"],
                        "new": item["new_count"], "active": item["active_count"],
                        "resources": item["affected_resources"],
                        "severity": next((level for level in ("CRITICAL", "HIGH", "MEDIUM", "LOW")
                                          if item["active_severities"].get(level)), "UNKNOWN"),
                        "action": group_action(item["group"]),
                        "url": _securityhub_url(item["group"])} for item in selected],
    }
    summary["groups_changed_total"] = len(summaries)
    summary["other_group_count"] = len(summaries) - len(selected) - sum(
        1 for item in summaries if item["group"].get("product") == "Inspector" and
        item["group"].get("repository"))
    _publish_slack(sns, summary)
    _acknowledge_new(table, pending_records)
    _set_fields(table, "group#checkpoint", {"last_daily_slack_at": datetime.fromtimestamp(now, timezone.utc).isoformat()})
    for key, records in groups.items():
        desired = "1" if any(_actionable(record) for record in records) else "0" if records[0]["group"]["label"] in quiet_groups else None
        if desired is not None and states[key].get("slack_open") != desired:
            _set_fields(table, "group#" + key, {"slack_open": desired})
            if desired == "0":
                _clear_urgent_claim(table, "group#" + key)
    return True


def run(table, securityhub, sns, now=None):
    now = int(time.time() if now is None else now)
    checkpoint_state = _get_item(table, "group#checkpoint")
    initial = not checkpoint_state.get("reconciled_through")
    seen, changed, full = reconcile_findings(table, securityhub, now)
    groups = collections.defaultdict(list)
    page_groups = collections.defaultdict(list)
    records, active_markers, closed_markers = scan_findings(table)
    for record in records:
        groups[record["group"]["key"]].append(record)
        page_groups[record.get("page_group", record["group"])["key"]].append(record)
    sent = 0
    migrated = 0
    failures = []
    for key, records in page_groups.items():
        summary = summarize_group(records, identity="page_group")
        if not _needs_opsgenie_sync(summary, key, active_markers):
            continue
        state = _get_item(table, "group#" + key)
        try:
            sync_opsgenie(table, summary, state, now)
        except Exception as error:
            LOG.exception("Opsgenie group delivery failed for %s", key)
            failures.append(error)
    if _daily_due(checkpoint_state, now):
        sent += int(send_slack_batch(table, sns, groups, now, initial=initial))
    remaining = MAX_LEGACY_MIGRATIONS_PER_RUN
    for key, records in page_groups.items():
        if remaining <= 0:
            break
        try:
            moved = migrate_legacy_alerts(table, records, summarize_group(records, identity="page_group"), remaining)
            migrated += moved
            remaining -= moved
        except Exception as error:
            LOG.exception("Opsgenie legacy migration failed for %s", key)
            failures.append(error)
    try:
        migrated += migrate_previous_groups(table, page_groups, closed_markers)
    except Exception as error:
        LOG.exception("Opsgenie fallback-group migration failed")
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
