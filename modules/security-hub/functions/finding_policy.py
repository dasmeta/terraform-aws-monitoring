"""Deterministic routing policy for grouped Security Hub findings."""

import json
import os


SEVERITY_RANK = {"UNKNOWN": 0, "INFORMATIONAL": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


def is_guardduty(finding):
    return finding.get("ProductName") in {"GuardDuty", "Amazon GuardDuty"}


def severity(finding):
    return finding.get("Severity", {}).get("Label", "UNKNOWN").upper()


def active(finding):
    return (finding.get("RecordState") == "ACTIVE" and
            finding.get("Workflow", {}).get("Status") in {"NEW", "NOTIFIED"} and
            (finding.get("Compliance") or {}).get("Status") != "PASSED")


def exploitable(finding):
    return any(v.get("ExploitAvailable") == "YES" for v in finding.get("Vulnerabilities") or [])


def environment(finding):
    configured = os.environ.get("SECURITY_ENVIRONMENT", "").strip()
    if configured:
        return configured
    for resource in finding.get("Resources") or []:
        tags = resource.get("Tags") or {}
        value = tags.get("Environment") or tags.get("environment") or tags.get("Env")
        if value:
            return value
    return "Unknown"


def project(finding):
    configured = os.environ.get("SECURITY_PROJECT", "").strip()
    if configured:
        return configured
    for resource in finding.get("Resources") or []:
        tags = resource.get("Tags") or {}
        value = tags.get("Project") or tags.get("project")
        if value:
            return value
    return "Unknown"


def public_exposure(finding):
    """Only explicit resource attributes count as exposure evidence."""
    for resource in finding.get("Resources") or []:
        details = resource.get("Details") or {}
        if details.get("AwsRdsDbInstance", {}).get("PubliclyAccessible") is True:
            return True
        if details.get("AwsElbLoadBalancer", {}).get("Scheme") == "internet-facing":
            return True
        if details.get("AwsEc2Instance", {}).get("PublicIpAddress"):
            return True
    return False


def realtime(finding):
    if os.environ.get("REALTIME_ENABLED", "true") != "true" or not active(finding):
        return False
    level = severity(finding)
    if level == "CRITICAL":
        return True
    if is_guardduty(finding):
        threshold = os.environ.get("GUARD_DUTY_MIN_SEVERITY", "HIGH")
        return SEVERITY_RANK.get(level, 0) >= SEVERITY_RANK.get(threshold, 3)
    return (level == "HIGH" and
            (os.environ.get("HIGH_REQUIRES_EXPLOIT", "true") != "true" or exploitable(finding)) and
            (os.environ.get("HIGH_REQUIRES_PUBLIC_EXPOSURE", "true") != "true" or public_exposure(finding)))


def paging_priority(finding):
    if os.environ.get("REALTIME_ENABLED", "true") != "true" or not active(finding):
        return None
    policy = json.loads(os.environ.get("PAGING_POLICY", "{}"))
    level = severity(finding)
    if level == "CRITICAL":
        return "P1" if policy.get("critical", True) else None
    allowed = policy.get("environments") or []
    if allowed and environment(finding) not in allowed:
        return None
    if is_guardduty(finding):
        finding_type = (finding.get("Types") or [""])[0]
        minimum = SEVERITY_RANK.get(os.environ.get("GUARD_DUTY_MIN_SEVERITY", "HIGH"), 3)
        if SEVERITY_RANK.get(level, 0) >= minimum and any(
                finding_type.startswith(prefix) for prefix in policy.get("guardduty_types") or []):
            return "P1" if level == "HIGH" else "P2"
        return None
    if (level == "HIGH" and policy.get("high_exploitable", True) and exploitable(finding) and
            (not policy.get("require_public_exposure", True) or public_exposure(finding))):
        return "P1"
    return None
