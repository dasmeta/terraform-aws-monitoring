"""Stable, actionable text for Security Hub remediation-group alerts."""

import urllib.parse


def group_action(group):
    if group.get("incident_category") == "container-vulnerability":
        return f"Review container vulnerabilities in {group['repository']}"
    if group.get("repository") and group.get("vulnerability"):
        return f"Patch {group['package']} for {group['vulnerability']} in {group['repository']}"
    if group.get("cluster") and group.get("nodepool") and group.get("image"):
        return f"Patch {group['cluster']}/{group['nodepool']} node image {group['image']}"

    label = group.get("label", "Security Hub finding")
    parts = label.split(" | ")
    if group.get("product") == "Inspector" and len(parts) == 3:
        target, image = parts[1:]
        if image.startswith("sha256:"):
            return f"Patch container image {target}@{image}"
        if image.startswith("ami-"):
            return f"Patch EC2 instance {target} image {image}"
    return f"Investigate {label}"


def group_message(group, prefix, priority):
    if group.get("incident_category") == "container-vulnerability":
        return f"{prefix} | Container vulnerabilities | {group['repository']}"[:130]
    return f"{prefix} Security {priority}: {group_action(group)}"[:130]


def securityhub_url(group):
    region = urllib.parse.quote(group["region"], safe="")
    return f"https://console.aws.amazon.com/securityhub/home?region={region}#/findings"


def description_header(group):
    return f"Action: {group_action(group)}\nRemediation target: {group['label']}\n"
