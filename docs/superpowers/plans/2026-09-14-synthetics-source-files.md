# Source-File CloudWatch Synthetics Canaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let consumers supply private Python source-file paths while the public module creates a deterministic Synthetics ZIP and resolves existing AWS secret/SNS resources by name.

**Architecture:** The module validates a grouped per-canary object, builds one archive resource per canary with generated root `config.json`, uploads it to the artifact bucket, and wires looked-up ARNs into runtime IAM/alarm resources. Consumer behavior stays private; public code owns generic packaging and AWS infrastructure.

**Tech Stack:** Terraform `~> 1.3`, AWS provider `>= 5.0, < 7.0`, Archive provider `~> 2.4`, AWS CloudWatch Synthetics `syn-python-selenium-11.1`.

---

The authoritative technical plan is [the Speckit plan](../../../specs/003-synthetics-source-files/plan.md). Execute its seven tasks in order, using test-first static assertions before behavior changes. Do not edit module source until `specs/003-synthetics-source-files/tasks.md` exists.
