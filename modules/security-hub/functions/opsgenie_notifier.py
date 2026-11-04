"""Deliver Security Hub finding lifecycle events to the Opsgenie Alert API."""

import hashlib
import json
import logging
import os
import time
import urllib.parse
import urllib.error
import urllib.request

from group_alert_format import description_header, group_message, securityhub_url


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)


def finding_alias(finding):
    identity = "|".join((finding["AwsAccountId"], finding["ProductArn"], finding["Id"]))
    return "securityhub-" + hashlib.sha256(identity.encode("utf-8")).hexdigest()


def alert_message(finding):
    parts = (
        os.environ.get("OPSGENIE_ALERT_PREFIX", "Security Hub"),
        finding.get("Severity", {}).get("Label", "UNKNOWN"),
        finding.get("ProductName", "Security Hub"),
        finding.get("Title", "Security finding"),
    )
    return " | ".join(parts)[:130]


def _request(method, path, payload=None):
    base = os.environ["OPSGENIE_API_URL"].rstrip("/")
    request = urllib.request.Request(
        base + path,
        data=json.dumps(payload).encode("utf-8") if payload is not None else None,
        headers={
            "Authorization": "GenieKey " + os.environ["OPSGENIE_API_KEY"],
            "Content-Type": "application/json",
        },
        method=method,
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                body = json.loads(response.read())
                if response.status not in (200, 202):
                    raise RuntimeError(f"Opsgenie API returned HTTP {response.status}")
                return body
        except urllib.error.HTTPError as error:
            # Permission propagation, rate limiting, and transient server
            # failures must be retried; persistent failures reach the DLQ.
            if error.code not in (403, 429, 500, 502, 503, 504) or attempt == 3:
                raise
            retry_after = error.headers.get("Retry-After") if error.headers else None
            delay = float(retry_after) if retry_after and retry_after.isdigit() else 0.5 * (attempt + 1)
            time.sleep(min(delay, 5))


def _wait_for_request(request_id):
    path = "/v2/alerts/requests/" + urllib.parse.quote(request_id, safe="")
    for attempt in range(8):
        try:
            result = _request("GET", path)
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            result = {}
        data = result.get("data", {})
        if "isSuccess" in data:
            if not data["isSuccess"]:
                raise RuntimeError("Opsgenie rejected alert action: " + data.get("status", "unknown"))
            return
        time.sleep(min(0.25 * (attempt + 1), 1))
    raise RuntimeError("Opsgenie alert action has no confirmed result")


def deliver(message):
    finding = message["detail"]["findings"][0]
    if message.get("_dasmeta_group_urgent"):
        from finding_router import _group_identity

        group = message.get("_dasmeta_group") or _group_identity(finding)
        alias = "securityhub-group-" + group["key"]
        path = "/v2/alerts/" + urllib.parse.quote(alias, safe="")
        priority = message.get("_dasmeta_page_priority") or "P1"
        try:
            existing = _request("GET", path + "?identifierType=alias").get("data")
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            existing = None
        if existing:
            if existing.get("priority") != priority and priority == "P1":
                result = _request("PUT", path + "/priority?identifierType=alias", {"priority": priority})
                request_id = result.get("requestId")
                if not request_id:
                    raise RuntimeError("Opsgenie priority change returned no request ID")
                _wait_for_request(request_id)
            # Reconciliation updates distinct CVEs in the description. A
            # retried SNS event must not add duplicate Opsgenie notes.
            LOG.info("Opsgenie incident already exists for %s", alias)
            return
        else:
            resource = (finding.get("Resources") or [{}])[0].get("Id", "")
            resource_label = resource.rsplit("/", 1)[-1][:120] if resource else "unknown"
            container = group.get("incident_category") == "container-vulnerability"
            description = (
                f"Priority: {priority}\nEnvironment: {group.get('environment') or 'Unknown'}\n"
                f"AWS account: {group['account']}\nRegion: {group['region']}\n"
                f"Application: {group['repository']}\n"
                f"Deployment: unknown | Exposure: unknown\n"
                f"Escalation reason: {message.get('_dasmeta_priority_reason') or 'Configured investigation policy'}\n"
                f"Finding: {finding.get('Title', 'Security finding')[:180]}\n"
                "Recommended action: Verify deployment, exploitability, exposure, and patched version availability.\n"
                f"Security Hub: {securityhub_url(group)}\n"
                f"First detected: {finding.get('CreatedAt', 'unknown')}\n"
                f"Last updated: {finding.get('UpdatedAt', finding.get('CreatedAt', 'unknown'))}"
            ) if container else (
                description_header(group)
                + f"Severity: {finding.get('Severity', {}).get('Label', 'UNKNOWN')}\n"
                f"Finding: {finding.get('Title', 'Security finding')[:180]}\n"
                f"Resource: {resource_label}\n"
                f"Security Hub: {securityhub_url(group)}\n"
                "Review the finding and related resources in Security Hub."
            )
            result = _request("POST", "/v2/alerts", {
                "message": group_message(group, os.environ.get("OPSGENIE_ALERT_PREFIX", "Security Hub"), priority),
                "alias": alias,
                "description": description[:15000],
                "priority": priority,
                "source": "AWS Security Hub",
                "tags": ["securityhub-grouped", group["product"].lower().replace(" ", "-")],
                "details": ({"AWS account": finding["AwsAccountId"], "Application": group["repository"][:100],
                             "Deployment status": "unknown", "Exposure status": "unknown"} if container else {
                    "AWS account": finding["AwsAccountId"], "Cluster": (group["cluster"] or "n/a")[:50],
                    "Node pool": (group["nodepool"] or "n/a")[:50], "AMI": (group["image"] or "n/a")[:50]}),
            })
        request_id = result.get("requestId")
        if not request_id:
            raise RuntimeError("Opsgenie urgent group action returned no request ID")
        _wait_for_request(request_id)
        LOG.info("Opsgenie urgent group action confirmed for %s", alias)
        return
    alias = finding_alias(finding)
    action = message.get("_dasmeta_opsgenie_action", "create")
    if action == "close":
        path = "/v2/alerts/" + urllib.parse.quote(alias, safe="") + "/close?identifierType=alias"
        result = _request("POST", path, {
            "user": "Security Hub finding router",
            "source": "AWS Security Hub",
            "note": "Finding resolved or archived in Security Hub",
        })
    elif action == "create":
        severity = finding.get("Severity", {}).get("Label", "UNKNOWN")
        result = _request("POST", "/v2/alerts", {
            "message": alert_message(finding),
            "alias": alias,
            "description": (finding.get("Description") or "Security Hub finding")[:15000],
            "priority": {"CRITICAL": "P1", "HIGH": "P2"}.get(severity, "P3"),
            "source": "AWS Security Hub",
            "details": {
                "AWS account": finding["AwsAccountId"],
                "Finding ID": finding["Id"],
                "Product ARN": finding["ProductArn"],
                "Record state": finding.get("RecordState", "UNKNOWN"),
            },
        })
    else:
        raise ValueError("Unknown Opsgenie action")
    request_id = result.get("requestId")
    if not request_id:
        raise RuntimeError("Opsgenie action returned no request ID")
    _wait_for_request(request_id)
    LOG.info("Opsgenie %s confirmed for finding alias %s", action, alias)


def lambda_handler(event, context):
    for record in event.get("Records", []):
        deliver(json.loads(record["Sns"]["Message"]))
