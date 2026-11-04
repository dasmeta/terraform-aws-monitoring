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


def is_inspector_ecr(finding):
    return finding.get("ProductName") == "Inspector" and any(
        resource.get("Type") == "AwsEcrContainerImage" for resource in finding.get("Resources") or [])


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


def risk_context(finding, verified=None):
    """Unverified ECR ASFF images have no deployment or network-exposure evidence."""
    verified = verified or {}
    deployment = verified.get("deployment") if is_inspector_ecr(finding) else "not_applicable"
    exposure = verified.get("exposure")
    if deployment not in {"deployed", "unused", "unknown", "not_applicable"}:
        deployment = "unknown"
    if exposure not in {"exposed", "unexposed", "unknown"}:
        exposure = "exposed" if public_exposure(finding) else "unknown"
    return {"deployment": deployment or "unknown", "exposure": exposure,
            "active_exploitation": verified.get("active_exploitation") is True}


def _policy():
    return json.loads(os.environ.get("PAGING_POLICY", "{}"))


def priority_with_reason(finding, verified=None):
    """Return an explicit priority and the evidence that justified it."""
    if os.environ.get("REALTIME_ENABLED", "true") != "true" or not active(finding):
        return None, "Inactive finding or real-time routing disabled"
    policy = _policy()
    level = severity(finding)
    context = risk_context(finding, verified)
    allowed = policy.get("environments") or []
    if allowed and environment(finding) not in allowed and is_inspector_ecr(finding):
        return None, "Environment outside configured Inspector escalation scope"
    if is_guardduty(finding):
        finding_type = (finding.get("Types") or [""])[0]
        minimum = SEVERITY_RANK.get(os.environ.get("GUARD_DUTY_MIN_SEVERITY", "HIGH"), 3)
        if SEVERITY_RANK.get(level, 0) < minimum:
            return None, "Below GuardDuty escalation threshold"
        p1 = any(finding_type.startswith(prefix) for prefix in policy.get("guardduty_types") or [])
        p2 = any(finding_type.startswith(prefix) for prefix in policy.get("guardduty_investigation_types") or [])
        port_probe = bool((finding.get("Action") or {}).get("PortProbeAction"))
        if (p1 or level == "CRITICAL" and policy.get("critical", True)) and port_probe and not policy.get("guardduty_port_probe_p1", False):
            return "P2", "GuardDuty port probing requires investigation; compromise unverified"
        if level == "CRITICAL" and policy.get("critical", True):
            return "P1", "Critical GuardDuty threat requiring investigation"
        if p1:
            return "P1", "Configured urgent GuardDuty threat type"
        if p2:
            return "P2", "Configured GuardDuty investigation type"
        return None, "GuardDuty type not configured for Opsgenie"
    if is_inspector_ecr(finding):
        ids = {v.get("Id") for v in finding.get("Vulnerabilities") or [] if v.get("Id")}
        emergency = bool(ids.intersection(policy.get("ecr_emergency_vulnerability_ids") or []))
        production = environment(finding).lower() in {name.lower() for name in
                        policy.get("production_environments", ["production", "prod"])}
        if level == "CRITICAL":
            if not policy.get("critical", True):
                return None, "Critical Opsgenie delivery disabled by policy"
            if context["deployment"] == "unused":
                return None, "Image verified unused; retain finding in daily digest"
            if emergency:
                return "P1", "Security-owner emergency vulnerability override"
            if production and context["deployment"] == "deployed" and (
                    context["active_exploitation"] or
                    context["exposure"] == "exposed" and exploitable(finding)):
                return "P1", "Deployed production image with verified exposure or exploitation"
            fallback = policy.get("ecr_critical_unknown_priority", "P2")
            return (None if fallback == "DIGEST" else fallback), "Critical image deployment or exposure unverified"
        if (level == "HIGH" and production and context["deployment"] == "deployed" and
                context["exposure"] == "exposed" and exploitable(finding) and
                policy.get("high_exploitable", True)):
            return "P1", "Exploitable HIGH on a verified deployed and exposed production image"
        return None, "Routine Inspector image finding for daily digest"
    if level == "CRITICAL":
        return ("P1", "Critical non-container finding") if policy.get("critical", True) else (None, "Critical paging disabled by policy")
    if allowed and environment(finding) not in allowed:
        return None, "Environment outside configured escalation scope"
    if (level == "HIGH" and policy.get("high_exploitable", True) and exploitable(finding) and
            (not policy.get("require_public_exposure", True) or public_exposure(finding))):
        return "P1", "Exploitable HIGH with configured exposure evidence"
    return None, "Below Opsgenie escalation policy"


def realtime(finding, verified=None):
    if os.environ.get("REALTIME_ENABLED", "true") != "true" or not active(finding):
        return False
    level = severity(finding)
    if is_inspector_ecr(finding):
        return priority_with_reason(finding, verified)[0] is not None
    if level == "CRITICAL":
        return True
    if is_guardduty(finding):
        threshold = os.environ.get("GUARD_DUTY_MIN_SEVERITY", "HIGH")
        return SEVERITY_RANK.get(level, 0) >= SEVERITY_RANK.get(threshold, 3)
    return (level == "HIGH" and
            (os.environ.get("HIGH_REQUIRES_EXPLOIT", "true") != "true" or exploitable(finding)) and
            (os.environ.get("HIGH_REQUIRES_PUBLIC_EXPOSURE", "true") != "true" or public_exposure(finding)))


def paging_priority(finding, verified=None):
    return priority_with_reason(finding, verified)[0]
