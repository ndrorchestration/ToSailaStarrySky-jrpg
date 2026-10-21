#!/usr/bin/env python3
"""Read-only Aetherwake #293 Windows-release control-plane verification.

Requires an *already authorized* GitHub CLI account with private repository
metadata and Actions read permissions. Run locally with --live, never in the
release workflow. This script does not dispatch jobs, change workflow state,
merge, tag, download binaries, or certify installer safety.

A successfully observed administrative disable is distinct from branch
protection, non-author approval, malware adjudication and release admission.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import subprocess
import sys
from typing import Any

REPO = "ndrorchestration/aetherwake-jrpg"
WORKFLOW_ID = 362360040
EXPECTED_WORKFLOW_PATH = ".github/workflows/desktop-package.yml"
EXPECTED_MAIN = "7364d43c202b2186e2d4eb3c752367afe61ee408"
EXPECTED_SIGNED_PR_299 = "5fc3ea2fa9b5963594863efb232e6280a6df3a56"


def observe_state(workflow: Any, branch: Any, pr: Any) -> dict[str, Any]:
    """Assess only trusted API response fields; fail closed on missing identities."""
    result: dict[str, Any] = {
        "repository": REPO,
        "workflow_id": WORKFLOW_ID,
        "result": "BLOCKED",
        "workflow_disable": "NOT_VERIFIED",
        "main_protection": "NOT_VERIFIED",
        "release_authorized": False,
        "reviewer_eligibility": "NOT_ESTABLISHED",
        "defender_adjudication": "NOT_ESTABLISHED",
        "reasons": [],
    }
    if not all(isinstance(x, dict) for x in (workflow, branch, pr)):
        result["reasons"].append("SOURCE_UNRESOLVED")
        return result

    try:
        state = workflow["state"]
        ident = workflow["id"]
        path = workflow["path"]
        main_sha = branch["commit"]["sha"]
        protected = branch["protected"]
        head_sha = pr["head"]["sha"]
        base_sha = pr["base"]["sha"]
        pr_state = pr["state"]
        pr_draft = pr["draft"]
        pr_merged = pr["merged"]
        if not (isinstance(state, str) and isinstance(path, str) and
                isinstance(main_sha, str) and isinstance(head_sha, str) and
                isinstance(base_sha, str) and isinstance(protected, bool) and
                isinstance(pr_draft, bool) and isinstance(pr_merged, bool) and
                isinstance(pr_state, str) and type(ident) is int):
            raise TypeError("Malformed GitHub identity")
    except (KeyError, TypeError, ValueError):
        result["reasons"].append("SOURCE_FIELDS_INCOMPLETE")
        return result

    result["observed"] = {
        "workflow_state": state,
        "workflow_path": path,
        "main_sha": main_sha,
        "main_protected": protected,
        "pr_299_head_sha": head_sha,
        "pr_299_base_sha": base_sha,
        "pr_299_draft": pr_draft,
        "pr_299_merged": pr_merged,
    }
    if ident != WORKFLOW_ID or path != EXPECTED_WORKFLOW_PATH:
        result["reasons"].append("WORKFLOW_IDENTITY_CHANGED")
    if state == "disabled_manually":
        result["workflow_disable"] = "DISABLED_MANUALLY_OBSERVED"
    else:
        result["workflow_disable"] = "NOT_CONFIRMED_DISABLED_MANUALLY"
        result["reasons"].append("WORKFLOW_NOT_DISABLED_MANUALLY")
    if main_sha != EXPECTED_MAIN:
        result["reasons"].append("MAIN_HEAD_CHANGED")
    if head_sha != EXPECTED_SIGNED_PR_299 or base_sha != EXPECTED_MAIN:
        result["reasons"].append("PR_299_IDENTITY_CHANGED")
    if pr_state != "open" or not pr_draft or pr_merged:
        result["reasons"].append("PR_299_ADMISSION_STATE_CHANGED")
    result["main_protection"] = "PROTECTED_FLAG_TRUE" if protected else "UNPROTECTED"
    if not protected:
        result["reasons"].append("PRIVATE_MAIN_UNPROTECTED")
    # Even a successful read of an administratively disabled workflow cannot
    # authorize release or imply malware/independent review conclusions.
    result["result"] = "REVIEW_REQUIRED" if result["reasons"] else "CONTROL_OBSERVED_ONLY"
    return result


def read_github_json(endpoint: str) -> dict[str, Any] | None:
    """Use GitHub CLI GET only, no shell, and suppress possible credential errors."""
    try:
        p = subprocess.run(
            ["gh", "api", "--method", "GET", endpoint],
            check=False, capture_output=True, text=True, timeout=20,
        )
        if p.returncode != 0:
            return None
        parsed = json.loads(p.stdout)
        return parsed if isinstance(parsed, dict) else None
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true",
                        help="Run three explicit authenticated read-only GitHub GET requests.")
    args = parser.parse_args(argv)
    if not args.live:
        print(json.dumps({"result": "BLOCKED", "reason": "EXPLICIT_LIVE_READ_REQUIRED",
                          "release_authorized": False}))
        return 2
    prefix = f"/repos/{REPO}"
    workflow = read_github_json(f"{prefix}/actions/workflows/{WORKFLOW_ID}")
    branch = read_github_json(f"{prefix}/branches/main")
    pr = read_github_json(f"{prefix}/pulls/299")
    result = observe_state(workflow, branch, pr)
    result["observed_at_utc"] = datetime.now(timezone.utc).isoformat()
    print(json.dumps(result, sort_keys=True, indent=2))
    return 2 if result["result"] == "BLOCKED" else (1 if result["result"] == "REVIEW_REQUIRED" else 0)


if __name__ == "__main__":
    sys.exit(main())
