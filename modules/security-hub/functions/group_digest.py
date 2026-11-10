"""Reconcile Security Hub and send bounded remediation-group notifications."""

import base64
import collections
import concurrent.futures
import hashlib
import json
import logging
import os
import time
import urllib.error
import urllib.parse
import uuid
import zlib
from datetime import datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError

from finding_router import _finding_key, _page_group_from_remediation, _record_grouped, _timestamp
from finding_policy import environment_for_account
from deployment_inventory import displayed_environment, load_inventory
from group_alert_format import description_header, group_action, group_message, incident_signature, securityhub_url
from opsgenie_notifier import _request, _wait_for_request


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)
MAX_RECONCILED_FINDINGS = 250000
MAX_LEDGER_ITEMS = 1000000
MAX_GROUP_ITEMS = 1000000
RECONCILE_PAGES_PER_RUN = 300
RECONCILE_SECONDS_PER_RUN = 240
RECONCILE_WINDOW_SECONDS = 900
RECENT_RECONCILE_MAX_PAGES = 250
RECENT_RECONCILE_SECONDS_PER_RUN = 180
RECENT_RECONCILE_WINDOW_SECONDS = 300
LEDGER_SCAN_SEGMENTS = 8
MAX_LEGACY_MIGRATIONS_PER_RUN = 50
QUIET_CLOSE_SECONDS = 3600
MAX_EXTERNAL_CLOSED_FINDINGS = 3000
HIGH_SEVERITIES = {"HIGH", "CRITICAL"}
OPSGENIE_FORMAT_VERSION = "4"


def _decode(item):
    return {key: next(iter(value.values())) for key, value in item.items()}


def _resolve_record_environment(record):
    """Refresh stored labels without changing the ledger's grouping keys."""
    for identity in ("group", "page_group"):
        if record.get(identity):
            group = record[identity]
            group["environment"] = environment_for_account(
                group["account"], group.get("environment", "Unknown"))
    policy = json.loads(os.environ.get("PAGING_POLICY", "{}"))
    if (record.get("group", {}).get("environment") in policy.get("inspector_critical_p2_environments", []) and
            record.get("severity") == "CRITICAL" and
            record.get("group", {}).get("product") == "Inspector" and
            ":ecr:" not in record.get("resource", "") and
            record.get("page_priority") == "P1"):
        record["page_priority"] = "P2"
        record["priority_reason"] = "Critical Inspector finding in configured P2 environment"
    return record


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


def _read_page(call, **request):
    """Retry transient AWS read failures without advancing pagination state."""
    retryable = {"ThrottlingException", "TooManyRequestsException", "RequestLimitExceeded",
                 "LimitExceededException", "InternalException",
                 "ProvisionedThroughputExceededException", "InternalServerException",
                 "InternalServerError", "ServiceUnavailableException", "TransactionInProgressException"}
    for attempt in range(3):
        try:
            return call(**request)
        except ClientError as error:
            if attempt == 2 or error.response.get("Error", {}).get("Code") not in retryable:
                raise
            time.sleep(0.2 * (2 ** attempt))


def _batch_get_findings(table, findings, consumed=None):
    """Read one Security Hub page of ledger rows; fail if any key stays unprocessed."""
    table_name = os.environ["DELIVERY_TABLE_NAME"]
    keys = {_finding_key(finding) for finding in findings}
    if not keys:
        return {}
    request = {table_name: {"Keys": [{"finding_key": {"S": key}} for key in keys],
                            "ConsistentRead": True}}
    items = {}
    for attempt in range(5):
        response = _read_page(table.batch_get_item, RequestItems=request, ReturnConsumedCapacity="TOTAL")
        if consumed is not None:
            consumed[0] += sum(item.get("CapacityUnits", 0) for item in response.get("ConsumedCapacity", []))
        for item in response.get("Responses", {}).get(table_name, []):
            decoded = _decode(item)
            items[decoded["finding_key"]] = decoded
        request = response.get("UnprocessedKeys") or {}
        if not request:
            return items
        time.sleep(0.2 * (2 ** attempt))
    raise RuntimeError(f"DynamoDB left {len(request.get(table_name, {}).get('Keys', []))} finding keys unprocessed")


def _mark_legacy_index(table, row):
    """Keep unresolved legacy alerts queryable after the full-scan bootstrap."""
    old_state = row.get("notification_state")
    if old_state == "LEGACY_PENDING":
        return
    values = {":legacy": {"S": "LEGACY_PENDING"}, ":payload": {"S": row["notification_payload"]}}
    condition = "#payload = :payload AND "
    if old_state:
        values[":old"] = {"S": old_state}
        condition += "#state = :old"
    else:
        condition += "attribute_not_exists(#state)"
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": row["finding_key"]}},
            UpdateExpression="SET #state = :legacy",
            ConditionExpression=condition,
            ExpressionAttributeNames={"#state": "notification_state", "#payload": "notification_payload"},
            ExpressionAttributeValues=values,
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
            raise


def _retire_legacy_index(table, key):
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": key}},
            UpdateExpression="SET #state = :archived",
            ConditionExpression="#state = :legacy",
            ExpressionAttributeNames={"#state": "notification_state"},
            ExpressionAttributeValues={":legacy": {"S": "LEGACY_PENDING"}, ":archived": {"S": "ARCHIVED"}},
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
            raise


class PackedRecords:
    """Decode one finding at a time so large legacy groups fit in memory."""

    def __init__(self, blobs):
        self.blobs = blobs

    def __len__(self):
        return len(self.blobs)

    def __iter__(self):
        for blob in self.blobs:
            yield json.loads(zlib.decompress(blob))

    def __getitem__(self, index):
        if isinstance(index, slice):
            return [json.loads(zlib.decompress(blob)) for blob in self.blobs[index]]
        return json.loads(zlib.decompress(self.blobs[index]))


class PackedGroups:
    """Keep ledger payloads compressed and decode only the group being handled."""

    def __init__(self, groups):
        self.groups = groups

    def __len__(self):
        return len(self.groups)

    def __iter__(self):
        return iter(self.groups)

    def __getitem__(self, key):
        return PackedRecords(self.groups[key])

    def items(self):
        for key in self.groups:
            yield key, self[key]

    def values(self):
        for key in self.groups:
            yield self[key]


class MissingMarkerSnapshot(RuntimeError):
    """An open incident cannot be closed safely without its last group facts."""


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
    pages = 0
    read_units = [0.0]
    while True:
        request = {"Filters": filters, "MaxResults": 100}
        if token:
            request["NextToken"] = token
        page = _read_page(securityhub.get_findings, **request)
        pages += 1
        findings = page.get("Findings", [])
        current_items = _batch_get_findings(table, findings, read_units)
        for finding in findings:
            seen += 1
            if seen > MAX_RECONCILED_FINDINGS:
                LOG.error("Security Hub reconciliation limit reached: pages=%d seen=%d", pages, seen)
                raise RuntimeError(f"Security Hub reconciliation exceeded {MAX_RECONCILED_FINDINGS} findings; widen or partition the worker before continuing")
            changed += int(_record_grouped(table, finding, current=current_items.get(_finding_key(finding), {})))
        token = page.get("NextToken")
        if pages % 25 == 0:
            LOG.info("Security Hub reconciliation progress: pages=%d seen=%d changed=%d ledger_read_units=%.1f",
                     pages, seen, changed, read_units[0])
        if not token:
            break
    LOG.info("Security Hub reconciliation: pages=%d seen=%d changed=%d ledger_read_units=%.1f from=%s",
             pages, seen, changed, read_units[0], since.isoformat())
    return seen, changed, full


def _save_reconcile_progress(table, state, fields):
    """Compare-and-set a durable cursor so overlapping invocations cannot regress it."""
    version = uuid.uuid4().hex
    fields = {**fields, "reconcile_version": version}
    names = {f"#f{index}": name for index, name in enumerate(fields)}
    values = {f":v{index}": {"S": value} for index, value in enumerate(fields.values())}
    names.update({"#version": "reconcile_version", "#through": "reconciled_through"})
    old_version = state.get("reconcile_version")
    old_through = state.get("reconciled_through")
    conditions = []
    if old_version:
        values[":old_version"] = {"S": old_version}
        conditions.append("#version = :old_version")
    else:
        conditions.append("attribute_not_exists(#version)")
    if old_through:
        values[":old_through"] = {"S": old_through}
        conditions.append("#through = :old_through")
    else:
        conditions.append("attribute_not_exists(#through)")
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": "group#checkpoint"}},
            UpdateExpression="SET " + ", ".join(f"#f{i} = :v{i}" for i in range(len(fields))),
            ConditionExpression=" AND ".join(conditions),
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
            raise RuntimeError("Reconciliation checkpoint changed concurrently; retry") from error
        raise
    state.update(fields)


def reconcile_findings_bounded(table, securityhub, now, checkpoint, context=None):
    """Advance fixed 15-minute update windows and persist a cursor before returning.

    A failed page is replayed on the next invocation. Successful windows are
    never replayed solely because a later window or the daily digest failed.
    """
    cutover = _timestamp(os.environ["FINDING_CUTOVER_AT"])
    target_text = checkpoint.get("reconcile_target")
    if target_text:
        if not checkpoint.get("reconcile_cursor"):
            raise RuntimeError("Reconciliation checkpoint has a target but no cursor")
        cursor = _timestamp(checkpoint["reconcile_cursor"])
        target = _timestamp(target_text)
        token = checkpoint.get("reconcile_next_token") or None
        full = checkpoint.get("reconcile_full") == "1"
    else:
        last_full = checkpoint.get("last_full_reconcile")
        previous = checkpoint.get("reconciled_through")
        full = not last_full or now - _timestamp(last_full).timestamp() >= 86400
        cursor = cutover if full or not previous else max(cutover, _timestamp(previous) - timedelta(hours=1))
        target = datetime.fromtimestamp(now, timezone.utc)
        token = None
    if cursor > target:
        raise RuntimeError("Reconciliation cursor is newer than its target")
    seen = changed = pages = 0
    read_units = [0.0]
    started = time.monotonic()
    while cursor < target:
        window_end = min(cursor + timedelta(seconds=RECONCILE_WINDOW_SECONDS), target)
        filters = {
            "CreatedAt": [{"Start": cutover.isoformat(), "End": target.isoformat()}],
            "UpdatedAt": [{"Start": cursor.isoformat(), "End": window_end.isoformat()}],
        }
        # Bound the number of Inspector calls before the next durable cursor.
        request = {"Filters": filters, "MaxResults": 50 if os.environ.get("ECR_DEPLOYMENT_LOOKUP_ENABLED") == "true" else 100}
        if token:
            request["NextToken"] = token
        try:
            page = _read_page(securityhub.get_findings, **request)
        except ClientError as error:
            # Security Hub tokens need not live as long as a multi-run replay.
            # Restart only this small window if a saved token has expired.
            if not token or error.response.get("Error", {}).get("Code") not in {"InvalidInputException", "InvalidTokenException"}:
                raise
            _save_reconcile_progress(table, checkpoint, {
                "reconcile_cursor": cursor.isoformat(), "reconcile_target": target.isoformat(),
                "reconcile_next_token": "", "reconcile_full": "1" if full else "0",
            })
            LOG.warning("Expired Security Hub page token; restarting the current update window")
            return seen, changed, full, False
        pages += 1
        findings = page.get("Findings", [])
        current_items = _batch_get_findings(table, findings, read_units)
        for finding in findings:
            seen += 1
            changed += int(_record_grouped(table, finding, current=current_items.get(_finding_key(finding), {})))
        token = page.get("NextToken")
        if pages % 25 == 0:
            LOG.info("Bounded reconciliation progress: pages=%d seen=%d changed=%d ledger_read_units=%.1f",
                     pages, seen, changed, read_units[0])
        if not token:
            cursor = window_end
            if cursor == target:
                fields = {"reconciled_through": target.isoformat(), "reconcile_cursor": "",
                          "reconcile_target": "", "reconcile_next_token": "", "reconcile_full": ""}
                if full:
                    fields["last_full_reconcile"] = target.isoformat()
                _save_reconcile_progress(table, checkpoint, fields)
                LOG.info("Security Hub reconciliation complete: pages=%d seen=%d changed=%d ledger_read_units=%.1f",
                         pages, seen, changed, read_units[0])
                return seen, changed, full, True
        remaining = context.get_remaining_time_in_millis() if context else None
        if (pages >= RECONCILE_PAGES_PER_RUN or time.monotonic() - started >= RECONCILE_SECONDS_PER_RUN or
                remaining is not None and remaining < 360000):
            _save_reconcile_progress(table, checkpoint, {
                "reconcile_cursor": cursor.isoformat(), "reconcile_target": target.isoformat(),
                "reconcile_next_token": token or "", "reconcile_full": "1" if full else "0",
            })
            LOG.info("Security Hub reconciliation paused: pages=%d seen=%d changed=%d cursor=%s",
                     pages, seen, changed, cursor.isoformat())
            return seen, changed, full, False
    fields = {"reconciled_through": target.isoformat(), "reconcile_cursor": "",
              "reconcile_target": "", "reconcile_next_token": "", "reconcile_full": ""}
    if full:
        fields["last_full_reconcile"] = target.isoformat()
    _save_reconcile_progress(table, checkpoint, fields)
    return seen, changed, full, True


def reconcile_recent_findings(table, securityhub, now, checkpoint=None, context=None):
    """Checkpoint bounded recent windows while the historical replay catches up."""
    checkpoint = checkpoint if checkpoint is not None else _get_item(table, "group#checkpoint")
    cutover = _timestamp(os.environ["FINDING_CUTOVER_AT"])
    end = datetime.fromtimestamp(now, timezone.utc)
    target_text = checkpoint.get("recent_target")
    reconciled_through = checkpoint.get("reconciled_through")
    if target_text and reconciled_through and _timestamp(reconciled_through) >= _timestamp(target_text):
        # The historical pass has already covered this entire recent window.
        target_text = None
    if target_text:
        if not checkpoint.get("recent_cursor"):
            raise RuntimeError("Recent reconciliation checkpoint has a target but no cursor")
        cursor = _timestamp(checkpoint["recent_cursor"])
        target = _timestamp(target_text)
        token = checkpoint.get("recent_next_token") or None
    else:
        previous = checkpoint.get("recent_completed_at")
        since = _timestamp(previous) if previous else end
        if reconciled_through:
            since = max(since, _timestamp(reconciled_through))
        cursor = max(cutover, since - timedelta(hours=1))
        target = end
        token = None
    if cursor > target:
        raise RuntimeError("Recent reconciliation cursor is newer than its target")
    seen = changed = pages = 0
    started = time.monotonic()
    while cursor < target:
        window_end = min(cursor + timedelta(seconds=RECENT_RECONCILE_WINDOW_SECONDS), target)
        request = {"Filters": {
            "CreatedAt": [{"Start": cutover.isoformat(), "End": target.isoformat()}],
            "UpdatedAt": [{"Start": cursor.isoformat(), "End": window_end.isoformat()}],
        }, "MaxResults": 100}
        if token:
            request["NextToken"] = token
        try:
            page = _read_page(securityhub.get_findings, **request)
        except ClientError as error:
            if not token or error.response.get("Error", {}).get("Code") not in {"InvalidInputException", "InvalidTokenException"}:
                raise
            _save_reconcile_progress(table, checkpoint, {
                "recent_cursor": cursor.isoformat(), "recent_target": target.isoformat(),
                "recent_next_token": "",
            })
            LOG.warning("Expired recent Security Hub page token; restarting the current update window")
            return seen, changed
        pages += 1
        findings = page.get("Findings", [])
        current_items = _batch_get_findings(table, findings)
        for finding in findings:
            seen += 1
            changed += int(_record_grouped(table, finding, current=current_items.get(_finding_key(finding), {}),
                                           lookup_inspector=False))
        token = page.get("NextToken")
        if not token:
            cursor = window_end
            if cursor == target:
                _save_reconcile_progress(table, checkpoint, {
                    "recent_cursor": "", "recent_target": "", "recent_next_token": "",
                    "recent_completed_at": target.isoformat(),
                })
                LOG.info("Recent Security Hub reconciliation: pages=%d seen=%d changed=%d", pages, seen, changed)
                return seen, changed
        remaining = context.get_remaining_time_in_millis() if context else None
        if (pages >= RECENT_RECONCILE_MAX_PAGES or
                time.monotonic() - started >= RECENT_RECONCILE_SECONDS_PER_RUN or
                remaining is not None and remaining < 540000):
            _save_reconcile_progress(table, checkpoint, {
                "recent_cursor": cursor.isoformat(), "recent_target": target.isoformat(),
                "recent_next_token": token or "",
            })
            LOG.info("Recent Security Hub reconciliation paused: pages=%d seen=%d changed=%d cursor=%s",
                     pages, seen, changed, cursor.isoformat())
            return seen, changed
    _save_reconcile_progress(table, checkpoint, {
        "recent_cursor": "", "recent_target": "", "recent_next_token": "",
        "recent_completed_at": target.isoformat(),
    })
    return seen, changed


def _scan_segment(table, packed=False, segment=0, segments=1, pending_after=None, state=None, index_legacy=False):
    items = [] if not packed else None
    groups = collections.defaultdict(list) if packed else None
    page_groups = collections.defaultdict(list) if packed else None
    active_markers = set()
    closed_markers = set()
    token = None
    pages = 0
    scanned = 0
    read_units = 0.0
    findings = 0
    while True:
        if state is None:
            request = {
                "TableName": os.environ["DELIVERY_TABLE_NAME"],
                "ProjectionExpression": "finding_key, notification_kind, notification_payload, notification_pending, notification_digest_pending, notification_pending_at, notification_updated_at, notification_state, opsgenie_delivery_mode, opsgenie_state, opsgenie_resolution_state, legacy_group_migrated, opsgenie_open, urgent_state, critical_state, superseded_group_closed, opsgenie_external_closed_signature",
                "ConsistentRead": True,
                "ReturnConsumedCapacity": "TOTAL",
            }
            if segments > 1:
                request.update(Segment=segment, TotalSegments=segments)
        else:
            request = {
                "TableName": os.environ["DELIVERY_TABLE_NAME"],
                "IndexName": "notification-state",
                "KeyConditionExpression": "#state = :state",
                "ExpressionAttributeNames": {"#state": "notification_state"},
                "ExpressionAttributeValues": {":state": {"S": state}},
                "ReturnConsumedCapacity": "TOTAL",
            }
        if token:
            request["ExclusiveStartKey"] = token
        page = _read_page(table.scan if state is None else table.query, **request)
        pages += 1
        scanned += page.get("ScannedCount", len(page.get("Items", [])))
        read_units += (page.get("ConsumedCapacity") or {}).get("CapacityUnits", 0)
        for item in page.get("Items", []):
            row = _decode(item)
            marker = row.get("finding_key", "")
            if marker.startswith("group#"):
                if row.get("opsgenie_open") != "1" and (
                        row.get("superseded_group_closed") == "1" or row.get("opsgenie_external_closed_signature")):
                    if row.get("superseded_group_closed") == "1":
                        closed_markers.add(marker.removeprefix("group#"))
                    continue
                if row.get("opsgenie_open") == "1" or row.get("urgent_state") == "SENT" or row.get("critical_state") == "SENT":
                    active_markers.add(marker.removeprefix("group#"))
                if row.get("superseded_group_closed") == "1":
                    closed_markers.add(marker.removeprefix("group#"))
                continue
            if row.get("notification_kind") != "finding":
                continue
            if state == "LEGACY_PENDING" and row.get("legacy_group_migrated") == "1":
                _retire_legacy_index(table, marker)
                continue
            record = json.loads(row["notification_payload"])
            if record.get("group") and not record.get("page_group"):
                record["page_group"] = _page_group_from_remediation(record["group"], record.get("resource", ""))
                if record["page_group"]["key"] != record["group"]["key"]:
                    record["previous_page_group_key"] = record["group"]["key"]
                    if record["severity"] == "CRITICAL":
                        record["page_priority"] = "P2"
            _resolve_record_environment(record)
            if _timestamp(record["created_at"]) < _timestamp(os.environ["FINDING_CUTOVER_AT"]):
                continue
            pending_at = (row.get("notification_pending_at") or row.get("notification_updated_at") or
                          record.get("updated_at") or record["created_at"])
            record["pending"] = (row.get("notification_digest_pending") == "1" if
                                 "notification_digest_pending" in row else
                                 row.get("notification_pending", "1") == "1" and
                                 (not pending_after or _timestamp(pending_at) > _timestamp(pending_after)))
            record["_digest_pending_explicit"] = row.get("notification_digest_pending") == "1"
            record["_ledger_revision"] = pending_at
            if record["pending"] and not packed:
                record["_ledger_payload"] = row["notification_payload"]
            record["legacy_opsgenie"] = row.get("opsgenie_delivery_mode") == "API" and row.get("opsgenie_state") == "SENT" and row.get("opsgenie_resolution_state") != "SENT" and row.get("legacy_group_migrated") != "1"
            if index_legacy and state is None and record["legacy_opsgenie"] and (record["record_state"] != "ACTIVE" or record["workflow"] == "RESOLVED"):
                _mark_legacy_index(table, row)
            findings += 1
            if packed:
                blob = zlib.compress(json.dumps(record, separators=(",", ":")).encode("utf-8"), level=1)
                group_records = groups[record["group"]["key"]]
                page_records = page_groups[record.get("page_group", record["group"])["key"]]
                group_records.append(blob)
                page_records.append(blob)
                if len(group_records) > MAX_GROUP_ITEMS or len(page_records) > MAX_GROUP_ITEMS:
                    raise RuntimeError(f"Security Hub group exceeded {MAX_GROUP_ITEMS} findings; partition group processing")
            else:
                items.append(record)
            if findings > MAX_LEDGER_ITEMS:
                LOG.error("Finding ledger limit reached: pages=%d scanned=%d findings=%d read_units=%.1f",
                          pages, scanned, findings, read_units)
                raise RuntimeError(f"Security Hub finding ledger exceeded {MAX_LEDGER_ITEMS} items; partition the digest before continuing")
        token = page.get("LastEvaluatedKey")
        if pages % 25 == 0:
            LOG.info("Finding ledger progress: pages=%d scanned=%d findings=%d read_units=%.1f",
                     pages, scanned, findings, read_units)
        if not token:
            LOG.info("Finding ledger complete: pages=%d scanned=%d findings=%d read_units=%.1f",
                     pages, scanned, findings, read_units)
            if packed:
                return groups, page_groups, active_markers, closed_markers, findings, scanned, read_units
            return items, active_markers, closed_markers, findings, scanned, read_units


def scan_findings(table, packed=False, segments=1, pending_after=None, index_legacy=False):
    """Read the ledger in parallel while keeping every group in one result."""
    if segments == 1:
        result = _scan_segment(table, packed, pending_after=pending_after, index_legacy=index_legacy)
        if packed:
            groups, page_groups, active, closed, _, _, _ = result
            return PackedGroups(groups), PackedGroups(page_groups), active, closed
        items, active, closed, _, _, _ = result
        return items, active, closed
    if not packed:
        raise ValueError("Parallel ledger scans require packed groups")
    with concurrent.futures.ThreadPoolExecutor(max_workers=segments) as executor:
        futures = [executor.submit(_scan_segment, table, True, segment, segments, pending_after, None, index_legacy)
                   for segment in range(segments)]
        results = [future.result() for future in futures]
    return _merge_packed_parts(results, f"parallel segments={segments}")


def _merge_packed_parts(results, label):
    groups = collections.defaultdict(list)
    page_groups = collections.defaultdict(list)
    active_markers, closed_markers = set(), set()
    findings = scanned = 0
    read_units = 0.0
    for part_groups, part_pages, part_active, part_closed, part_findings, part_scanned, part_units in results:
        findings += part_findings
        scanned += part_scanned
        read_units += part_units
        if findings > MAX_LEDGER_ITEMS:
            raise RuntimeError(f"Security Hub finding ledger exceeded {MAX_LEDGER_ITEMS} items; partition the digest before continuing")
        for key, blobs in part_groups.items():
            groups[key].extend(blobs)
            if len(groups[key]) > MAX_GROUP_ITEMS:
                raise RuntimeError(f"Security Hub group exceeded {MAX_GROUP_ITEMS} findings; partition group processing")
        for key, blobs in part_pages.items():
            page_groups[key].extend(blobs)
            if len(page_groups[key]) > MAX_GROUP_ITEMS:
                raise RuntimeError(f"Security Hub group exceeded {MAX_GROUP_ITEMS} findings; partition group processing")
        active_markers.update(part_active)
        closed_markers.update(part_closed)
    LOG.info("Finding ledger complete: %s scanned=%d findings=%d read_units=%.1f",
             label, scanned, findings, read_units)
    return PackedGroups(groups), PackedGroups(page_groups), active_markers, closed_markers


def _query_open_markers(table):
    markers = {}
    token = None
    while True:
        request = {
            "TableName": os.environ["DELIVERY_TABLE_NAME"], "IndexName": "notification-state",
            "KeyConditionExpression": "#state = :state",
            "ExpressionAttributeNames": {"#state": "notification_state"},
            "ExpressionAttributeValues": {":state": {"S": "OPEN_MARKER"}},
        }
        if token:
            request["ExclusiveStartKey"] = token
        page = _read_page(table.query, **request)
        for item in page.get("Items", []):
            row = _decode(item)
            key = row.get("finding_key", "")
            if key.startswith("group#") and key != "group#checkpoint":
                markers[key.removeprefix("group#")] = row
        token = page.get("LastEvaluatedKey")
        if not token:
            return markers


def _closed_marker_record(group, last_updated):
    return {
        "finding_key": "group#" + group["key"], "group": group, "page_group": group,
        "record_state": "ARCHIVED", "workflow": "RESOLVED", "severity": "UNKNOWN",
        "title": "", "vulnerability_ids": [], "resource": "", "resource_ids": [],
        "updated_at": last_updated, "created_at": last_updated,
        "first_seen_at": last_updated, "pending": False, "page_priority": None,
        "fix_available": "UNKNOWN", "risk_context": {}, "public_exposure": False,
    }


def _dedupe_index_results(groups):
    """An eventually consistent GSI can briefly return both sides of a state change."""
    newest = {}
    for blobs in groups.groups.values():
        for blob in blobs:
            record = json.loads(zlib.decompress(blob))
            key = record["finding_key"]
            revision = _timestamp(record["_ledger_revision"])
            if key not in newest or revision > newest[key][0]:
                newest[key] = (revision, record, blob)
    by_group = collections.defaultdict(list)
    by_page = collections.defaultdict(list)
    for _, record, blob in newest.values():
        by_group[record["group"]["key"]].append(blob)
        by_page[record.get("page_group", record["group"])["key"]].append(blob)
    return PackedGroups(by_group), PackedGroups(by_page)


def scan_findings_indexed(table, pending_after, now):
    """Read active findings, recent inactive changes, and open incidents only."""
    if not pending_after:
        raise ValueError("Indexed ledger scan requires a successful daily acknowledgement watermark")
    first = _timestamp(pending_after).date()
    last = datetime.fromtimestamp(now, timezone.utc).date()
    days = (last - first).days
    if days < 0 or days > 31:
        raise RuntimeError("Daily digest watermark is too old for bounded indexed reconciliation")
    states = ["ACTIVE", "LEGACY_PENDING"] + [
        "INACTIVE#" + (first + timedelta(days=index)).isoformat() for index in range(days + 1)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(LEDGER_SCAN_SEGMENTS, len(states) + 1)) as executor:
        futures = [executor.submit(_scan_segment, table, True, 0, 1, pending_after, state)
                   for state in states]
        markers_future = executor.submit(_query_open_markers, table)
        results = [future.result() for future in futures]
        markers = markers_future.result()
    groups, page_groups, active, closed = _merge_packed_parts(results, "indexed states=" + str(len(states)))
    groups, page_groups = _dedupe_index_results(groups)
    active.update(markers)
    for key, marker in markers.items():
        if key in page_groups.groups:
            continue
        try:
            group = json.loads(marker["opsgenie_group_payload"])
            last_updated = marker["opsgenie_group_updated_at"]
        except (KeyError, ValueError, TypeError) as error:
            raise MissingMarkerSnapshot(f"Open group {key} has no durable snapshot") from error
        record = _closed_marker_record(group, last_updated)
        blob = zlib.compress(json.dumps(record, separators=(",", ":")).encode("utf-8"), level=1)
        page_groups.groups[key].append(blob)
        groups.groups[key].append(blob)
    return groups, page_groups, active, closed


def _needs_opsgenie_sync(summary, key, active_markers):
    return bool(summary["priority"] or key in active_markers)


def summarize_group(records, identity="group", inventory=None):
    if not records:
        raise ValueError("Cannot summarize an empty finding group")
    new_severities = collections.Counter(record["severity"] for record in records if record.get("pending", True))
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
    result = {
        "group": records[0].get(identity, records[0]["group"]),
        "new_count": sum(new_severities.values()),
        "new_severities": dict(new_severities),
        "active_count": len(active),
        "high_count": len(high),
        "urgent_count": len(urgent),
        "high_severities": dict(collections.Counter(record["severity"] for record in high)),
        "urgent_titles": collections.Counter(record["title"] for record in urgent).most_common(3),
        "urgent_vulnerability_ids": sorted({identifier for record in urgent for identifier in record["vulnerability_ids"]}),
        "urgent_finding_keys": sorted({record["finding_key"] for record in urgent}),
        "legacy_urgent_signature": hashlib.sha256(json.dumps(
            sorted({(record["finding_key"], record["severity"], record.get("page_priority"),
                     tuple(record["vulnerability_ids"]), tuple(record.get("resource_ids", []))) for record in active}),
            separators=(",", ":"),
        ).encode("utf-8")).hexdigest(),
        "urgent_signature": incident_signature([
            {**record, "page_priority": page_priority(record)} for record in urgent]),
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
                             else "observed in use" if any(record.get("risk_context", {}).get("deployment") == "observed_in_use" for record in active)
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
    if inventory is not None and result["group"].get("repository") and result["group"].get("product") == "Inspector":
        result["running_environment"] = displayed_environment(active or records, inventory)
    return result


def _opsgenie_details(summary):
    group = summary["group"]
    details = {
        "AWS account": group["account"],
        "Environment": group.get("environment") or "Unknown",
        "Active findings": str(summary["active_count"]),
        "Affected resources": str(summary["affected_resources"]),
        "Distinct vulnerabilities": str(len(summary["vulnerability_ids"])),
    }
    if group.get("incident_category") == "container-vulnerability":
        details.update({"Application": group["repository"][:100], "Affected images": str(summary["affected_images"]),
                        "Deployment status": summary["deployment_status"], "Exposure status": summary["exposure_status"]})
        if "running_environment" in summary:
            details["Running environment"] = summary["running_environment"][:100]
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
        running_line = f"Running environments: {summary['running_environment']}\n" if "running_environment" in summary else ""
        return (
            f"Priority: {summary['priority']}\nEnvironment: {group.get('environment') or 'Unknown'}\n"
            f"{running_line}"
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
        + f"Environment: {group.get('environment') or 'Unknown'}\n"
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
    return _wait_for_request(request_id)


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


def _capture_opsgenie_alert_id(table, marker, alias, state):
    """Keep the alert ID for a direct Slack link, including after closure."""
    if not os.environ.get("OPSGENIE_WEB_URL") or state.get("opsgenie_alert_id"):
        return
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    try:
        alert = _request("GET", path + "?identifierType=alias").get("data") or {}
    except Exception as error:
        LOG.warning("Could not read Opsgenie incident ID for %s: %s", alias, error)
        return
    if alert.get("id"):
        _set_fields(table, marker, {"opsgenie_alert_id": alert["id"]})


def _opsgenie_incident_url(alert_id):
    base = os.environ.get("OPSGENIE_WEB_URL", "")
    if not base or not alert_id:
        return ""
    if base == "auto":
        base = ("https://app.eu.opsgenie.com" if "api.eu.opsgenie.com" in
                os.environ.get("OPSGENIE_API_URL", "") else "https://app.opsgenie.com")
    return base.rstrip("/") + "/alert/detail/" + urllib.parse.quote(alert_id, safe="") + "/details"


def _externally_closed_fields(summary, priority):
    vulnerabilities = summary.get("urgent_vulnerability_ids", [])
    finding_keys = summary.get("urgent_finding_keys", [])
    return {"opsgenie_open": "0", "opsgenie_priority": "", "notification_state": "OPEN_MARKER",
            "opsgenie_external_closed_signature": summary["urgent_signature"],
            "opsgenie_external_closed_priority": priority,
            "opsgenie_external_closed_urgent_count": str(summary.get("urgent_count", 0)),
            "opsgenie_external_closed_vulnerabilities": json.dumps(vulnerabilities[:256]),
            "opsgenie_external_closed_vulnerability_total": str(len(vulnerabilities)),
            "opsgenie_external_closed_finding_keys": json.dumps(finding_keys[:MAX_EXTERNAL_CLOSED_FINDINGS]),
            "opsgenie_external_closed_finding_total": str(len(finding_keys))}


def _new_urgent_after_external_close(summary, state, priority):
    if priority == "P1" and state.get("opsgenie_external_closed_priority") != "P1":
        return True
    if int(summary.get("urgent_count", 0)) > int(state.get("opsgenie_external_closed_urgent_count", "0")):
        return True
    if state.get("opsgenie_external_closed_finding_keys") and summary.get("urgent_finding_keys") is not None:
        finding_keys = summary["urgent_finding_keys"]
        old_keys = json.loads(state["opsgenie_external_closed_finding_keys"])
        if len(finding_keys) > MAX_EXTERNAL_CLOSED_FINDINGS or int(state.get("opsgenie_external_closed_finding_total", "0")) > MAX_EXTERNAL_CLOSED_FINDINGS:
            return summary["urgent_signature"] != state["opsgenie_external_closed_signature"]
        return bool(set(finding_keys) - set(old_keys))
    vulnerabilities = summary.get("urgent_vulnerability_ids", [])
    previous = json.loads(state.get("opsgenie_external_closed_vulnerabilities") or "[]")
    if len(vulnerabilities) > 256 or int(state.get("opsgenie_external_closed_vulnerability_total", "0")) > 256:
        return summary["urgent_signature"] != state["opsgenie_external_closed_signature"]
    return bool(set(vulnerabilities) - set(previous))


def _create_group_alert(alias, summary, priority):
    return _ops_action("POST", "/v2/alerts", {
        "message": _opsgenie_message(summary), "alias": alias,
        "description": _opsgenie_description(summary), "priority": priority,
        "source": "AWS Security Hub",
        "tags": ["securityhub-grouped", summary["group"]["product"].lower().replace(" ", "-")],
        "details": _opsgenie_details(summary),
    })


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


def _clear_critical_claim(table, marker):
    """Allow a later P1 episode after an incident is confirmed back at P2."""
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": marker}},
        UpdateExpression="REMOVE #state, #lease, #token, #slack_state, #slack_lease, #slack_token",
        ExpressionAttributeNames={
            "#state": "critical_state", "#lease": "critical_lease", "#token": "critical_token",
            "#slack_state": "critical_slack_state", "#slack_lease": "critical_slack_lease",
            "#slack_token": "critical_slack_token",
        },
    )


def _stage_incident_slack(table, marker, summary, state, action, priority):
    """Persist the Slack copy before changing the corresponding Opsgenie alert."""
    alias = "securityhub-group-" + summary["group"]["key"]
    identity = [alias, action, priority, summary["urgent_signature"], summary["latest_updated_at"]]
    delivery_id = hashlib.sha256(json.dumps(identity, separators=(",", ":")).encode()).hexdigest()
    payload = _slack_payload(summary, closing=action == "closed")
    payload["_dasmeta_group_digest"].update({
        "digest_kind": "incident", "incident_action": action, "incident_priority": priority,
        "incident_alias": alias, "incident_signature": summary["urgent_signature"],
        "incident_delivery_id": delivery_id,
        "priority_reasons": summary.get("priority_reasons", []),
        "deployment_status": summary.get("deployment_status", "unknown"),
        "exposure_status": summary.get("exposure_status", "unknown"),
        "fix_status": summary.get("fix_status", "unknown"),
        "top_vulnerabilities": summary.get("top_vulnerabilities", []),
    })
    if state.get("opsgenie_slack_sent") != delivery_id:
        old_pending = state.get("opsgenie_slack_pending") or ""
        if old_pending and old_pending != delivery_id:
            # The old Opsgenie action was not confirmed in the ledger. Keep an
            # audit marker while advancing to the latest complete group view.
            LOG.warning("Superseding unconfirmed grouped Slack copy for %s", marker)
        names = {"#pending": "opsgenie_slack_pending", "#payload": "opsgenie_slack_payload"}
        values = {":id": {"S": delivery_id}, ":empty": {"S": ""},
                  ":old": {"S": old_pending},
                  ":payload": {"S": json.dumps(payload, separators=(",", ":"))}}
        update = "SET #pending = :id, #payload = :payload"
        if old_pending and old_pending != delivery_id:
            names["#superseded"] = "opsgenie_slack_superseded_id"
            update += ", #superseded = :old"
        # An overlapping worker can only advance the pending copy it observed.
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": marker}},
            UpdateExpression=update,
            ConditionExpression="attribute_not_exists(#pending) OR #pending = :empty OR #pending = :old",
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
        )


def _deliver_incident_slack(table, sns, marker):
    """Retry a confirmed Opsgenie change until its Slack copy is published."""
    state = _get_item(table, marker)
    delivery_id = state.get("opsgenie_slack_pending")
    if not delivery_id:
        return False
    payload = json.loads(state["opsgenie_slack_payload"])
    incident = payload["_dasmeta_group_digest"]
    incident["incident_url"] = _opsgenie_incident_url(state.get("opsgenie_alert_id"))
    closing = incident["incident_action"] == "closed"
    confirmed = (state.get("opsgenie_open") == "0" if closing else
                 state.get("opsgenie_open") == "1" and
                 state.get("opsgenie_priority") == incident["incident_priority"] and
                 state.get("opsgenie_urgent_signature") == incident["incident_signature"])
    if not confirmed:
        return False
    if state.get("opsgenie_slack_sent") != delivery_id:
        sns.publish(TopicArn=os.environ["SLACK_TOPIC_ARN"], Subject="Security Hub grouped incident",
                    Message=json.dumps(payload, separators=(",", ":")))
    # Checkpoint the exact pending ID atomically. An overlapping worker can
    # stage a newer copy during SNS publication; this must not clear it.
    names = {"#pending": "opsgenie_slack_pending", "#payload": "opsgenie_slack_payload",
             "#sent": "opsgenie_slack_sent", "#slack_sig": "slack_incident_signature",
             "#slack_priority": "slack_incident_priority", "#slack_open": "slack_open"}
    values = {":id": {"S": delivery_id}, ":empty": {"S": ""},
              ":sig": {"S": incident["incident_signature"]},
              ":priority": {"S": incident["incident_priority"]},
              ":slack_open": {"S": "0" if closing else "1"}}
    update = "SET #sent = :id, #pending = :empty, #payload = :empty, #slack_sig = :sig, #slack_priority = :priority, #slack_open = :slack_open"
    condition = "#pending = :id"
    if closing:
        names.update({"#state": "notification_state", "#open": "opsgenie_open"})
        values.update({":closed": {"S": "CLOSED_MARKER"}, ":zero": {"S": "0"}})
        update += ", #state = :closed"
        condition += " AND #open = :zero"
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"], Key={"finding_key": {"S": marker}},
        UpdateExpression=update, ConditionExpression=condition,
        ExpressionAttributeNames=names, ExpressionAttributeValues=values,
    )
    return True


def sync_opsgenie(table, summary, state, now, sns=None):
    """Create once, update silently, escalate, and close after a quiet hour."""
    group_key = summary["group"]["key"]
    marker = "group#" + group_key
    alias = "securityhub-group-" + group_key
    path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
    priority = summary["priority"]
    previous_group = json.loads(state.get("opsgenie_group_payload") or "{}")
    environment_changed = (previous_group.get("environment") and
                           previous_group["environment"] != summary["group"].get("environment"))
    if sns is not None and state.get("opsgenie_slack_pending"):
        _capture_opsgenie_alert_id(table, marker, alias, state)
        _deliver_incident_slack(table, sns, marker)
        state = _get_item(table, marker)
    if (state.get("opsgenie_open") == "1" and summary.get("urgent_signature") and
            state.get("opsgenie_signature_version") != "2" and
            state.get("opsgenie_urgent_signature") == summary.get("legacy_urgent_signature")):
        # Upgrade unchanged open markers without posting a synthetic update.
        _set_fields(table, marker, {"opsgenie_urgent_signature": summary["urgent_signature"],
                                    "opsgenie_signature_version": "2"})
        state = {**state, "opsgenie_urgent_signature": summary["urgent_signature"],
                 "opsgenie_signature_version": "2"}
    if priority and state.get("opsgenie_open") == "1" and not state.get("opsgenie_active_count") and summary.get("active_count") is not None:
        _set_fields(table, marker, {"opsgenie_active_count": str(summary["active_count"])})
        state = {**state, "opsgenie_active_count": str(summary["active_count"])}
    group_updated_at = summary.get("latest_updated_at") or datetime.fromtimestamp(now, timezone.utc).isoformat()
    if not priority and state.get("opsgenie_external_closed_signature"):
        _set_fields(table, marker, {"opsgenie_external_closed_signature": "",
                                    "opsgenie_external_closed_priority": "",
                                    "opsgenie_external_closed_urgent_count": "0",
                                    "opsgenie_external_closed_vulnerabilities": "[]",
                                    "opsgenie_external_closed_vulnerability_total": "0",
                                    "opsgenie_external_closed_finding_keys": "[]",
                                    "opsgenie_external_closed_finding_total": "0"})
    if priority and state.get("opsgenie_external_closed_signature"):
        if not _new_urgent_after_external_close(summary, state, priority):
            if state["opsgenie_external_closed_signature"] != summary["urgent_signature"]:
                _set_fields(table, marker, _externally_closed_fields(summary, priority))
            return
    if priority or state.get("opsgenie_open") == "1" or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
        group_payload = json.dumps(summary["group"], separators=(",", ":"))
        if (state.get("notification_state") != "OPEN_MARKER" or
                state.get("opsgenie_group_payload") != group_payload or
                state.get("opsgenie_group_updated_at") != group_updated_at):
            _set_fields(table, marker, {"notification_state": "OPEN_MARKER",
                                        "opsgenie_group_payload": group_payload,
                                        "opsgenie_group_updated_at": group_updated_at})
    if priority:
        display_environment = summary.get("running_environment", summary["group"].get("environment", "Unknown"))
        changed_environment = ("running_environment" in summary and
                               state.get("opsgenie_display_environment") != display_environment)
        incident_changed = (state.get("opsgenie_open") != "1" or
                            state.get("opsgenie_priority") != priority or
                            state.get("opsgenie_urgent_signature") != summary["urgent_signature"] or
                            state.get("opsgenie_format_version") != OPSGENIE_FORMAT_VERSION or
                            changed_environment)
        immediate_copy = (state.get("slack_open") == "1" and
                          state.get("slack_incident_priority") == priority and
                          state.get("slack_incident_signature") == summary["urgent_signature"] and
                          not changed_environment)
        if sns is not None and incident_changed and not immediate_copy:
            action = ("opened" if state.get("opsgenie_open") != "1" else
                      "escalated" if state.get("opsgenie_priority") == "P2" and priority == "P1" else
                      "downgraded" if state.get("opsgenie_priority") == "P1" and priority == "P2" else
                      "updated")
            _stage_incident_slack(table, marker, summary, state, action, priority)
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
                created = _create_group_alert(alias, summary, priority)
                alert_id = created.get("alertId") if isinstance(created, dict) else None
                if isinstance(alert_id, str) and alert_id:
                    _set_fields(table, marker, {"opsgenie_alert_id": alert_id})
                    state = {**state, "opsgenie_alert_id": alert_id}
            if remote.get("id") and not state.get("opsgenie_alert_id"):
                _set_fields(table, marker, {"opsgenie_alert_id": remote["id"]})
                state = {**state, "opsgenie_alert_id": remote["id"]}
            # Record confirmed creation before optional enrichment. A failed
            # update then retries the update, not the create notification.
            confirmed = {"opsgenie_open": "1", "opsgenie_priority": priority}
            if state.get("opsgenie_external_closed_signature"):
                confirmed["opsgenie_external_closed_signature"] = ""
            _set_fields(table, marker, confirmed)
            if remote or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
                # An immediate P1 action may already have created this alias.
                # Enrich it with the complete group on the first reconciliation.
                _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
                _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
            _set_fields(table, marker, {"opsgenie_format_version": OPSGENIE_FORMAT_VERSION,
                                        "opsgenie_signature_version": "2",
                                        "opsgenie_urgent_signature": summary["urgent_signature"],
                                        "opsgenie_display_environment": display_environment,
                                        "opsgenie_last_update_at": datetime.fromtimestamp(now, timezone.utc).isoformat()})
        else:
            reformat = state.get("opsgenie_format_version") != OPSGENIE_FORMAT_VERSION
            changed_urgent = state.get("opsgenie_urgent_signature") != summary["urgent_signature"]
            changed_count = state.get("opsgenie_active_count") != str(summary["active_count"])
            try:
                if priority != state.get("opsgenie_priority"):
                    _ensure_opsgenie_priority(alias, priority)
                    if state.get("opsgenie_priority") == "P1" and priority == "P2":
                        _clear_critical_claim(table, marker)
                    _set_fields(table, marker, {"opsgenie_priority": priority})
                if priority != state.get("opsgenie_priority") or reformat:
                    _ops_action("PUT", path + "/message?identifierType=alias", {"message": _opsgenie_message(summary)})
                if changed_urgent or changed_count or changed_environment or environment_changed or reformat or priority != state.get("opsgenie_priority"):
                    _ops_action("POST", path + "/details?identifierType=alias", {"details": _opsgenie_details(summary), "source": "AWS Security Hub"})
                    _ops_action("PUT", path + "/description?identifierType=alias", {"description": _opsgenie_description(summary)})
                    _set_fields(table, marker, {"opsgenie_urgent_signature": summary["urgent_signature"],
                                                "opsgenie_signature_version": "2",
                                                "opsgenie_last_update_at": datetime.fromtimestamp(now, timezone.utc).isoformat(),
                                                "opsgenie_display_environment": display_environment,
                                                "opsgenie_active_count": str(summary["active_count"])})
                if reformat:
                    _set_fields(table, marker, {"opsgenie_format_version": OPSGENIE_FORMAT_VERSION})
            except (urllib.error.HTTPError, RuntimeError) as error:
                missing = error.code == 404 if isinstance(error, urllib.error.HTTPError) else "Alert does not exist" in str(error)
                if not missing:
                    raise
                closed_priority = state.get("opsgenie_priority") or priority
                _set_fields(table, marker, _externally_closed_fields(summary, closed_priority))
                if priority == "P1" and closed_priority != "P1":
                    _create_group_alert(alias, summary, priority)
                    _set_fields(table, marker, {"opsgenie_open": "1", "opsgenie_priority": priority,
                                                "notification_state": "OPEN_MARKER", "opsgenie_external_closed_signature": "",
                                                "opsgenie_urgent_signature": summary["urgent_signature"],
                                                "opsgenie_signature_version": "2",
                                                "opsgenie_format_version": OPSGENIE_FORMAT_VERSION,
                                                "opsgenie_display_environment": display_environment,
                                                "opsgenie_last_update_at": datetime.fromtimestamp(now, timezone.utc).isoformat(),
                                                "opsgenie_active_count": str(summary["active_count"])})
                elif sns is not None:
                    # The attempted update found an externally closed alert;
                    # no Opsgenie action was delivered to mirror.
                    _set_fields(table, marker, {"opsgenie_slack_pending": "", "opsgenie_slack_payload": ""})
        if sns is not None:
            if incident_changed:
                _capture_opsgenie_alert_id(table, marker, alias, state)
            _deliver_incident_slack(table, sns, marker)
        return
    if state.get("opsgenie_open") == "1" or state.get("urgent_state") == "SENT" or state.get("critical_state") == "SENT":
        quiet_since = state.get("opsgenie_no_urgent_since")
        if not quiet_since:
            _set_fields(table, marker, {"opsgenie_no_urgent_since": datetime.fromtimestamp(now, timezone.utc).isoformat()})
            return
        if now - _timestamp(quiet_since).timestamp() < int(os.environ.get("QUIET_PERIOD_SECONDS", str(QUIET_CLOSE_SECONDS))):
            return
        if sns is not None:
            _stage_incident_slack(table, marker, summary, state, "closed", state.get("opsgenie_priority", "P2"))
            _capture_opsgenie_alert_id(table, marker, alias, state)
        _close_opsgenie_alias(alias,
            "No active findings meet the paging policy after the quiet period; review remaining findings in Security Hub")
        _clear_urgent_claim(table, marker)
        _set_fields(table, marker, {"opsgenie_open": "0", "opsgenie_priority": "", "opsgenie_active_count": "0",
                                    "opsgenie_format_version": "", "opsgenie_urgent_signature": "", "opsgenie_last_update_at": "",
                                    "opsgenie_no_urgent_since": ""})
        if sns is not None:
            _deliver_incident_slack(table, sns, marker)
        else:
            _set_fields(table, marker, {"notification_state": "CLOSED_MARKER"})
    elif state.get("notification_state") == "OPEN_MARKER" and not state.get("opsgenie_slack_pending"):
        _set_fields(table, marker, {"notification_state": "CLOSED_MARKER"})


def migrate_legacy_alerts(table, records, summary, limit=MAX_LEGACY_MIGRATIONS_PER_RUN):
    """Close old per-finding alerts only after their replacement group exists."""
    replacement_open = _get_item(table, "group#" + summary["group"]["key"]).get("opsgenie_open") == "1"
    if not replacement_open:
        return 0
    moved = 0
    for record in records:
        if moved >= limit:
            break
        if not record.get("legacy_opsgenie"):
            continue
        alias = "securityhub-" + record["finding_key"]
        _close_opsgenie_alias(alias,
            "Replaced by remediation-group alert; individual finding remains in Security Hub")
        _set_fields(table, record["finding_key"], {"legacy_group_migrated": "1"})
        _retire_legacy_index(table, record["finding_key"])
        moved += 1
    return moved


def migrate_previous_groups(table, groups, closed_markers=None):
    """Close a stale fallback alert after its new remediation group is open."""
    active_keys = {key for key, records in groups.items()
                   if records and not records[0].get("finding_key", "").startswith("group#")}
    closed_markers = closed_markers or set()
    moved = 0
    for key, records in groups.items():
        old_keys = {old for record in records for old in
                    (record.get("previous_group_key"), record.get("previous_page_group_key"))}
        old_keys.discard(None)
        if not old_keys:
            continue
        if _get_item(table, "group#" + key).get("opsgenie_open") != "1":
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
            _clear_urgent_claim(table, marker)
            _set_fields(table, marker, {"notification_state": "CLOSED_MARKER"})
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
            "groups_cleared_total": summary.get("groups_cleared_total", len(summary.get("groups_cleared", []))),
            "baseline": summary.get("baseline", False),
            "digest_kind": summary.get("digest_kind"),
            "application_summaries": summary.get("application_summaries", [])[:3],
            "application_total": summary.get("application_total", len(summary.get("application_summaries", []))),
            "environment": summary.get("environment", group.get("environment", "Unknown")),
            "running_environment": summary.get("running_environment"),
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
        if "_ledger_payload" not in record:
            raise ValueError("Digest acknowledgement requires the exact ledger snapshot")
        try:
            table.update_item(
                TableName=os.environ["DELIVERY_TABLE_NAME"],
                Key={"finding_key": {"S": record["finding_key"]}},
                UpdateExpression="SET #pending = :done",
                ConditionExpression="#updated = :updated AND #payload = :payload AND #pending = :expected",
                ExpressionAttributeNames={"#pending": "notification_pending", "#updated": "notification_updated_at",
                                          "#payload": "notification_payload"},
                ExpressionAttributeValues={":done": {"S": "0"}, ":updated": {"S": record["updated_at"]},
                                           ":payload": {"S": record["_ledger_payload"]}, ":expected": {"S": "1"}},
            )
        except ClientError as error:
            if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
            # A newer import arrived during this digest; keep it pending.


def _acknowledge_pending_batch(table, records):
    """Conditionally acknowledge a brief in bounded transactions."""
    def flush(batch):
        if not batch:
            return
        if not hasattr(table, "transact_write_items"):
            _acknowledge_new(table, batch)
            return
        actions = [{"Update": {
            "TableName": os.environ["DELIVERY_TABLE_NAME"],
            "Key": {"finding_key": {"S": record["finding_key"]}},
            "UpdateExpression": "SET #pending = :done",
            "ConditionExpression": "#updated = :updated AND #payload = :payload AND #pending = :expected",
            "ExpressionAttributeNames": {"#pending": "notification_pending", "#updated": "notification_updated_at",
                                         "#payload": "notification_payload"},
            "ExpressionAttributeValues": {":done": {"S": "0"}, ":updated": {"S": record["updated_at"]},
                                          ":payload": {"S": record["_ledger_payload"]}, ":expected": {"S": "1"}},
        }} for record in batch]
        try:
            _read_page(table.transact_write_items, TransactItems=actions)
        except ClientError as error:
            if error.response.get("Error", {}).get("Code") != "TransactionCanceledException":
                raise
            # One concurrent finding update can reject the whole transaction.
            # Retry each row with the original exact-snapshot condition.
            _acknowledge_new(table, batch)

    batch = []
    size = 0
    keys = set()
    for record in records:
        if "_ledger_payload" not in record:
            raise ValueError("Digest acknowledgement requires the exact ledger snapshot")
        estimate = len(record["_ledger_payload"].encode("utf-8")) + 500
        if batch and (len(batch) >= 100 or size + estimate > 3000000 or record["finding_key"] in keys):
            flush(batch)
            batch, size, keys = [], 0, set()
        batch.append(record)
        keys.add(record["finding_key"])
        size += estimate
    flush(batch)


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
                                                "new": 0, "critical": 0, "high": 0, "group": None,
                                                "deployment_statuses": set()})
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
        app["deployment_statuses"].add(item["deployment_status"])
        app["vulnerabilities"].update(item["vulnerability_ids"])
        app["images"].update(resource for record in groups[group["key"]] if _actionable(record)
                             for resource in record.get("resource_ids", [record["resource"]]) if "/sha256:" in resource)
    application_summaries = [{"repository": boundary[4], "images": len(app["images"]),
                              "vulnerabilities": len(app["vulnerabilities"]), "findings": app["findings"],
                              "new": app["new"], "critical": app["critical"], "high": app["high"],
                              "deployment_status": ("deployed" if "deployed" in app["deployment_statuses"]
                                                    else "observed in use" if "observed in use" in app["deployment_statuses"]
                                                    else "unused" if app["deployment_statuses"] == {"unused"}
                                                    else "unknown"),
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
    environments = {record["group"].get("environment", "Unknown") for record in active_records}
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
        "environment": next(iter(environments)) if len(environments) == 1 else "Multiple environments" if environments else first_group.get("environment", "Unknown"),
        "account_label": (os.environ.get("SECURITY_ACCOUNT_LABEL") or next(iter(accounts))) if len(accounts) == 1 and
                         next(iter(environments), "") == os.environ.get("SECURITY_ENVIRONMENT", "") else
                         next(iter(accounts)) if len(accounts) == 1 else "Multiple accounts" if accounts else first_group["account"],
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


DAILY_OUTBOX_KEY = "group#daily-outbox"
DAILY_CHANGE_CHUNK = 500


def _stage_daily_outbox(table, summary, changes, pending_records, now):
    """Persist the exact SNS payload and group changes before any publish."""
    delivery_id = uuid.uuid4().hex
    day = datetime.fromtimestamp(now, timezone.utc).date().isoformat()
    watermark = datetime.fromtimestamp(now, timezone.utc).isoformat()
    payload = _slack_payload(summary, False)
    payload["_dasmeta_daily_delivery_id"] = delivery_id
    message = json.dumps(payload, separators=(",", ":"))
    if len(message.encode("utf-8")) > 250000:
        raise RuntimeError("Daily digest exceeds the SNS message limit; no delivery was staged")
    chunks = [changes[index:index + DAILY_CHANGE_CHUNK]
              for index in range(0, len(changes), DAILY_CHANGE_CHUNK)]
    for index, chunk in enumerate(chunks):
        encoded = base64.b64encode(zlib.compress(json.dumps(chunk, separators=(",", ":")).encode())).decode()
        table.put_item(TableName=os.environ["DELIVERY_TABLE_NAME"], Item={
            "finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{delivery_id}#{index}"},
            "daily_changes": {"S": encoded},
        })
    ack_chunks = [pending_records[index:index + DAILY_CHANGE_CHUNK]
                  for index in range(0, len(pending_records), DAILY_CHANGE_CHUNK)]
    for index, chunk in enumerate(ack_chunks):
        encoded = base64.b64encode(zlib.compress(json.dumps(chunk, separators=(",", ":")).encode())).decode()
        table.put_item(TableName=os.environ["DELIVERY_TABLE_NAME"], Item={
            "finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{delivery_id}#ack#{index}"},
            "daily_acks": {"S": encoded},
        })
    try:
        table.put_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Item={"finding_key": {"S": DAILY_OUTBOX_KEY}, "daily_id": {"S": delivery_id},
                  "daily_day": {"S": day}, "daily_watermark": {"S": watermark},
                  "daily_message": {"S": message}, "daily_state": {"S": "READY"},
                  "daily_change_chunks": {"N": str(len(chunks))}, "daily_change_cursor": {"N": "0"},
                  "daily_ack_chunks": {"N": str(len(ack_chunks))}, "daily_ack_cursor": {"N": "0"},
                  "daily_lease": {"N": "0"}},
            ConditionExpression="attribute_not_exists(finding_key) OR (#state = :done AND #day < :day)",
            ExpressionAttributeNames={"#state": "daily_state", "#day": "daily_day"},
            ExpressionAttributeValues={":done": {"S": "DONE"}, ":day": {"S": day}},
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
            raise
        # Another invocation already staged this day. Its durable payload wins.
        for index in range(len(chunks)):
            table.delete_item(TableName=os.environ["DELIVERY_TABLE_NAME"],
                              Key={"finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{delivery_id}#{index}"}})
        for index in range(len(ack_chunks)):
            table.delete_item(TableName=os.environ["DELIVERY_TABLE_NAME"],
                              Key={"finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{delivery_id}#ack#{index}"}})


def _write_owned_daily(table, delivery_id, owner, fields):
    names = {f"#f{index}": name for index, name in enumerate(fields)}
    values = {f":v{index}": {"N" if isinstance(value, int) else "S": str(value)}
              for index, value in enumerate(fields.values())}
    names.update({"#id": "daily_id", "#owner": "daily_owner"})
    values.update({":id": {"S": delivery_id}, ":owner": {"S": owner}})
    table.update_item(
        TableName=os.environ["DELIVERY_TABLE_NAME"],
        Key={"finding_key": {"S": DAILY_OUTBOX_KEY}},
        UpdateExpression="SET " + ", ".join(f"#f{i} = :v{i}" for i in range(len(fields))),
        ConditionExpression="#id = :id AND #owner = :owner",
        ExpressionAttributeNames=names, ExpressionAttributeValues=values,
    )


def _advance_daily_watermark(table, watermark):
    checkpoint = _get_item(table, "group#checkpoint")
    old = checkpoint.get("last_daily_slack_at")
    if old and _timestamp(old) >= _timestamp(watermark):
        return
    names = {"#last": "last_daily_slack_at"}
    values = {":new": {"S": watermark}}
    condition = "attribute_not_exists(#last)"
    if old:
        values[":old"] = {"S": old}
        condition = "#last = :old"
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": "group#checkpoint"}},
            UpdateExpression="SET #last = :new", ConditionExpression=condition,
            ExpressionAttributeNames=names, ExpressionAttributeValues=values,
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
            raise
        current = _get_item(table, "group#checkpoint").get("last_daily_slack_at")
        if not current or _timestamp(current) < _timestamp(watermark):
            raise


def _deliver_daily_outbox(table, sns):
    outbox = _get_item(table, DAILY_OUTBOX_KEY)
    if outbox.get("daily_state") not in {"READY", "CLAIMED"}:
        return False
    owner = uuid.uuid4().hex
    lease_now = int(time.time())
    try:
        table.update_item(
            TableName=os.environ["DELIVERY_TABLE_NAME"],
            Key={"finding_key": {"S": DAILY_OUTBOX_KEY}},
            UpdateExpression="SET #state = :claimed, #owner = :owner, #lease = :lease",
            ConditionExpression="#id = :id AND (#state = :ready OR (#state = :claimed AND #lease <= :now))",
            ExpressionAttributeNames={"#id": "daily_id", "#state": "daily_state",
                                      "#owner": "daily_owner", "#lease": "daily_lease"},
            ExpressionAttributeValues={":id": {"S": outbox["daily_id"]}, ":ready": {"S": "READY"},
                                       ":claimed": {"S": "CLAIMED"}, ":owner": {"S": owner},
                                       ":lease": {"N": str(lease_now + 900)}, ":now": {"N": str(lease_now)}},
        )
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
            return False
        raise
    watermark = outbox["daily_watermark"]
    for index in range(int(outbox.get("daily_ack_cursor", 0)), int(outbox.get("daily_ack_chunks", 0))):
        chunk = _get_item(table, f"{DAILY_OUTBOX_KEY}#{outbox['daily_id']}#ack#{index}")
        if not chunk.get("daily_acks"):
            raise RuntimeError("Daily digest finding-ack chunk is missing; retry after recovery")
        acknowledgements = json.loads(zlib.decompress(base64.b64decode(chunk["daily_acks"])))

        def acknowledge(item):
            key, revision = item
            try:
                table.update_item(
                    TableName=os.environ["DELIVERY_TABLE_NAME"],
                    Key={"finding_key": {"S": key}},
                    UpdateExpression="SET #pending = :done",
                    ConditionExpression="#pending = :one AND #revision = :revision",
                    ExpressionAttributeNames={"#pending": "notification_digest_pending",
                                              "#revision": "notification_pending_at"},
                    ExpressionAttributeValues={":done": {"S": "0"}, ":one": {"S": "1"},
                                               ":revision": {"S": revision}},
                )
            except ClientError as error:
                if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                    raise
                # A newer finding snapshot must remain pending for a later brief.
        # A large first digest can include hundreds of thousands of findings.
        # Keep each chunk bounded while overlapping independent conditional writes.
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            for _ in executor.map(acknowledge, acknowledgements):
                pass
        _write_owned_daily(table, outbox["daily_id"], owner, {"daily_ack_cursor": index + 1})
    checkpoint = _get_item(table, "group#checkpoint")
    if not checkpoint.get("last_daily_slack_at") or _timestamp(checkpoint["last_daily_slack_at"]) < _timestamp(watermark):
        # SNS and DynamoDB cannot commit atomically. A crash here can replay
        # this same delivery ID; the end-to-end Slack path is at least once.
        sns.publish(TopicArn=os.environ["SLACK_TOPIC_ARN"], Subject="Security Hub finding digest",
                    Message=outbox["daily_message"])
        _advance_daily_watermark(table, watermark)
    for index in range(int(outbox.get("daily_change_cursor", 0)), int(outbox["daily_change_chunks"])):
        chunk = _get_item(table, f"{DAILY_OUTBOX_KEY}#{outbox['daily_id']}#{index}")
        if not chunk.get("daily_changes"):
            raise RuntimeError("Daily digest group-state chunk is missing; retry after recovery")
        changes = json.loads(zlib.decompress(base64.b64decode(chunk["daily_changes"])))
        for key, desired in changes:
            _set_fields(table, "group#" + key, {"slack_open": desired})
            if desired == "0":
                _clear_urgent_claim(table, "group#" + key)
        _write_owned_daily(table, outbox["daily_id"], owner, {"daily_change_cursor": index + 1})
    _write_owned_daily(table, outbox["daily_id"], owner, {"daily_state": "DONE"})
    for index in range(int(outbox["daily_change_chunks"])):
        try:
            table.delete_item(TableName=os.environ["DELIVERY_TABLE_NAME"],
                              Key={"finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{outbox['daily_id']}#{index}"}})
        except Exception:
            LOG.exception("Daily digest change-chunk cleanup failed; delivery remains complete")
    for index in range(int(outbox.get("daily_ack_chunks", 0))):
        try:
            table.delete_item(TableName=os.environ["DELIVERY_TABLE_NAME"],
                              Key={"finding_key": {"S": f"{DAILY_OUTBOX_KEY}#{outbox['daily_id']}#ack#{index}"}})
        except Exception:
            LOG.exception("Daily digest acknowledgement cleanup failed; delivery remains complete")
    return True


def send_slack_batch_packed(table, sns, groups, page_groups, now, initial=False, inventory=None):
    """Build the same daily brief without retaining every decoded finding."""
    existing = _get_item(table, DAILY_OUTBOX_KEY)
    day = datetime.fromtimestamp(now, timezone.utc).date().isoformat()
    if existing.get("daily_state") in {"READY", "CLAIMED"} or existing.get("daily_day") == day:
        return _deliver_daily_outbox(table, sns)
    max_groups = int(os.environ.get("DAILY_DIGEST_MAX_GROUPS", "5"))
    quiet_seconds = int(os.environ.get("QUIET_PERIOD_SECONDS", str(QUIET_CLOSE_SECONDS)))
    selected = []
    changes = []
    pending_records = []
    first_group = None
    first_active_group = None
    active_count = new_count = routine_count = active_groups = container_groups = 0
    quiet_count = resolved_count = 0
    active_severities = collections.Counter()
    new_severities = collections.Counter()
    accounts, regions, resources, vulnerabilities, environments = set(), set(), set(), set(), set()
    quiet_labels = []
    watermark = datetime.fromtimestamp(now, timezone.utc)
    def pending_in_snapshot(record):
        revision = record.get("_ledger_revision")
        return record.get("pending") and (not revision or _timestamp(revision) <= watermark)

    for key, records in groups.items():
        if not records:
            continue
        first_group = first_group or records[0]["group"]
        state = _get_item(table, "group#" + key)
        pending_records.extend((record["finding_key"], record["_ledger_revision"])
                               for record in records if pending_in_snapshot(record) and
                               record.get("_digest_pending_explicit") and record.get("_ledger_revision"))
        active = [record for record in records if _actionable(record)]
        routine_count += sum(pending_in_snapshot(record) and not _actionable(record) for record in records)
        changed = [record for record in active if pending_in_snapshot(record) and
                   record.get("change_kind", "new") in {"new", "escalated", "reopened"}]
        if active:
            first_active_group = first_active_group or active[0]["group"]
            active_groups += 1
            active_count += len(active)
            for record in active:
                active_severities[record["severity"]] += 1
                accounts.add(record["account"])
                environments.add(record["group"].get("environment", "Unknown"))
                regions.add(record["group"]["region"])
                resources.update(item for item in record.get("resource_ids", [record["resource"]]) if item)
                vulnerabilities.update(record["vulnerability_ids"])
            if not initial:
                new_count += len(changed)
                new_severities.update(record["severity"] for record in changed)
            summary = summarize_group(records, inventory=inventory)
            summary.pop("new_records", None)
            summary["new_count"] = 0 if initial else len(changed)
            summary["active_count"] = len(active)
            summary["active_severities"] = dict(collections.Counter(record["severity"] for record in active))
            if summary["group"].get("repository") and summary["group"].get("product") == "Inspector":
                container_groups += 1
            else:
                selected.append(summary)
                selected.sort(key=_group_rank)
                del selected[max_groups:]
            if state.get("slack_open") != "1":
                changes.append((key, "1"))
        elif state.get("slack_open") == "1" and now - _timestamp(max(record["updated_at"] for record in records)).timestamp() >= quiet_seconds:
            quiet_count += 1
            if len(quiet_labels) < 10:
                quiet_labels.append(records[0]["group"]["label"])
            if all(record["record_state"] != "ACTIVE" or record["workflow"] == "RESOLVED" for record in records):
                resolved_count += 1
            changes.append((key, "0"))

    application_summaries = []
    application_total = 0
    for _, records in page_groups.items():
        if not records:
            continue
        group = records[0].get("page_group", records[0]["group"])
        if group.get("incident_category") != "container-vulnerability":
            continue
        active = [record for record in records if _actionable(record)]
        if not active:
            continue
        app = summarize_group(records, identity="page_group", inventory=inventory)
        application_total += 1
        item = {"repository": group["repository"], "images": app["affected_images"],
                "vulnerabilities": len(app["vulnerability_ids"]), "findings": len(active),
                "new": 0 if initial else sum(pending_in_snapshot(record) and record.get("change_kind", "new") in
                                               {"new", "escalated", "reopened"} for record in active),
                "critical": sum(record["severity"] == "CRITICAL" for record in active),
                "high": sum(record["severity"] == "HIGH" for record in active),
                "deployment_status": app["deployment_status"], "url": _securityhub_url(group)}
        application_summaries.append(item)
        application_summaries.sort(key=lambda value: (-bool(value["critical"]), -value["critical"],
                                                      -value["new"], -value["vulnerabilities"], value["repository"]))
        del application_summaries[3:]

    first_group = first_active_group or first_group or {
        "key": "daily", "label": "Security Hub daily digest", "account": "unknown",
        "region": os.environ.get("AWS_REGION", "unknown"), "product": "Security Hub",
        "cluster": "", "nodepool": "", "image": "",
    }
    account = next(iter(accounts)) if len(accounts) == 1 else "multiple" if accounts else first_group["account"]
    summary = {
        "group": {**first_group, "label": "Security Hub daily digest", "product": "Security Hub", "account": account},
        "new_count": new_count, "new_severities": dict(new_severities), "routine_count": routine_count,
        "routine_severities": {}, "active_count": active_count, "active_severities": dict(active_severities),
        "affected_resources": len(resources), "vulnerability_ids": sorted(vulnerabilities),
        "top_titles": [], "baseline": initial, "digest_kind": "daily",
        "application_summaries": application_summaries, "application_total": application_total,
        "groups_changed": [{"label": item["group"]["label"], "new": item["new_count"],
                            "active": item["active_count"]} for item in selected],
        "groups_changed_total": active_groups,
        "other_group_count": active_groups - len(selected) - container_groups,
        "groups_cleared": quiet_labels, "groups_cleared_total": quiet_count,
        "quiet_count": quiet_count, "resolved_count": resolved_count,
        "regions": sorted(regions) or [first_group["region"]],
        "environment": next(iter(environments)) if len(environments) == 1 else "Multiple environments" if environments else first_group.get("environment", "Unknown"),
        "account_label": (os.environ.get("SECURITY_ACCOUNT_LABEL") or next(iter(accounts))) if len(accounts) == 1 and
                         next(iter(environments), "") == os.environ.get("SECURITY_ENVIRONMENT", "") else
                         next(iter(accounts)) if len(accounts) == 1 else "Multiple accounts" if accounts else first_group["account"],
        "top_groups": [{"label": item["group"]["label"], "product": item["group"]["product"],
                        "new": item["new_count"], "active": item["active_count"],
                        "resources": item["affected_resources"],
                        "severity": next((level for level in ("CRITICAL", "HIGH", "MEDIUM", "LOW")
                                         if item["active_severities"].get(level)), "UNKNOWN"),
                        "action": group_action(item["group"]), "url": _securityhub_url(item["group"])}
                       for item in selected],
    }
    _stage_daily_outbox(table, summary, changes, pending_records, now)
    return _deliver_daily_outbox(table, sns)


def run(table, securityhub, sns, now=None, context=None):
    now = int(time.time() if now is None else now)
    inventory = load_inventory(now=datetime.fromtimestamp(now, timezone.utc))
    recovered_daily = _deliver_daily_outbox(table, sns)
    checkpoint_state = _get_item(table, "group#checkpoint")
    initial = not checkpoint_state.get("reconciled_through")
    bootstrap = checkpoint_state.get("ledger_index_ready") != "1"
    if bootstrap:
        seen = changed = 0
        complete = False
        groups, page_groups, active_markers, closed_markers = scan_findings(
            table, packed=True, segments=LEDGER_SCAN_SEGMENTS,
            pending_after=checkpoint_state.get("last_daily_slack_at"), index_legacy=True)
    else:
        recent_seen = recent_changed = 0
        if checkpoint_state.get("reconcile_target"):
            recent_seen, recent_changed = reconcile_recent_findings(
                table, securityhub, now, checkpoint_state, context)
        seen, changed, _, complete = reconcile_findings_bounded(table, securityhub, now, checkpoint_state, context)
        seen += recent_seen
        changed += recent_changed
        pending_after = checkpoint_state.get("last_daily_slack_at")
        if not pending_after and os.environ.get("DAILY_DIGEST_ENABLED", "true") != "true":
            pending_after = datetime.fromtimestamp(now - 86400, timezone.utc).isoformat()
        try:
            groups, page_groups, active_markers, closed_markers = scan_findings_indexed(
                table, pending_after, now)
        except MissingMarkerSnapshot:
            _set_fields(table, "group#checkpoint", {"ledger_index_ready": "0"})
            raise
    sent = int(recovered_daily)
    migrated = 0
    failures = []
    for key, records in page_groups.items():
        summary = summarize_group(records, identity="page_group", inventory=inventory)
        if not _needs_opsgenie_sync(summary, key, active_markers):
            continue
        state = _get_item(table, "group#" + key)
        try:
            sync_opsgenie(table, summary, state, now, sns=sns)
        except Exception as error:
            LOG.exception("Opsgenie group delivery failed for %s", key)
            failures.append(error)
    if _daily_due(checkpoint_state, now):
        sent += int(send_slack_batch_packed(table, sns, groups, page_groups, now, initial=initial, inventory=inventory))
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
    if bootstrap:
        for key in active_markers:
            state = _get_item(table, "group#" + key)
            if state.get("opsgenie_open") != "1" and (
                    state.get("superseded_group_closed") == "1" or state.get("opsgenie_external_closed_signature")):
                continue
            if (state.get("opsgenie_open") == "1" or state.get("urgent_state") == "SENT" or
                    state.get("critical_state") == "SENT") and (
                        state.get("notification_state") != "OPEN_MARKER" or not state.get("opsgenie_group_payload")):
                raise RuntimeError(f"Open group {key} lacks an indexed snapshot; retry bootstrap")
        today = datetime.fromtimestamp(now, timezone.utc).date()
        last_daily = checkpoint_state.get("last_daily_slack_at")
        digest_current = bool(last_daily and _timestamp(last_daily).date() == today)
        if sent or digest_current or os.environ.get("DAILY_DIGEST_ENABLED", "true") != "true":
            _set_fields(table, "group#checkpoint", {"ledger_index_ready": "1"})
    result = {"reconciled": seen, "changed": changed, "reconciliation_complete": complete,
              "ledger_bootstrap": bootstrap, "groups": len(groups),
              "slack_digests": sent, "legacy_alerts_migrated": migrated}
    LOG.info("Security Hub group digest: %s", result)
    return result


def lambda_handler(event, context):
    return run(boto3.client("dynamodb"), boto3.client("securityhub"), boto3.client("sns"), context=context)
