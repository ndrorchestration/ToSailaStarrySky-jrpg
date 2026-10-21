"""Offline contract tests for issue #293's read-only admin-state probe.

No authenticated requests or release actions are made by this suite.
"""
import contextlib
import copy
from io import StringIO
from pathlib import Path
import importlib.util
import json
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "verify-windows-release-hold-293.py"
spec = importlib.util.spec_from_file_location("release_hold_probe_293", SCRIPT)
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


def fixtures():
    workflow = {"id": 362360040, "name": "Windows desktop package",
                "state": "disabled_manually",
                "path": ".github/workflows/desktop-package.yml"}
    branch = {"commit": {"sha": probe.EXPECTED_MAIN}, "protected": False}
    pr = {"head": {"sha": probe.EXPECTED_SIGNED_PR_299},
          "base": {"sha": probe.EXPECTED_MAIN},
          "state": "open", "draft": True, "merged": False}
    return workflow, branch, pr


class ReleaseHoldStateProbeTests(unittest.TestCase):
    def check(self, edit=None):
        items = [copy.deepcopy(x) for x in fixtures()]
        if edit:
            edit(items)
        return probe.observe_state(*items)

    def test_observed_disable_is_separate_from_unprotected_main(self):
        result = self.check()
        self.assertEqual(result["workflow_disable"], "DISABLED_MANUALLY_OBSERVED")
        self.assertEqual(result["result"], "REVIEW_REQUIRED")
        self.assertEqual(result["reasons"], ["PRIVATE_MAIN_UNPROTECTED"])
        self.assertEqual(result["main_protection"], "UNPROTECTED")
        self.assertIs(result["release_authorized"], False)

    def test_active_workflow_is_review_required_and_not_certified_disabled(self):
        r = self.check(lambda a: a[0].update(state="active"))
        self.assertIn("WORKFLOW_NOT_DISABLED_MANUALLY", r["reasons"])
        self.assertEqual(r["workflow_disable"], "NOT_CONFIRMED_DISABLED_MANUALLY")

    def test_changed_workflow_identifier_or_path_fails(self):
        r = self.check(lambda a: a[0].update(path=".github/workflows/other.yml"))
        self.assertIn("WORKFLOW_IDENTITY_CHANGED", r["reasons"])
        self.assertIs(r["release_authorized"], False)

    def test_main_head_drift_fails(self):
        r = self.check(lambda a: a[1]["commit"].update(sha="a"*40))
        self.assertIn("MAIN_HEAD_CHANGED", r["reasons"])

    def test_pr_head_or_base_drift_fails(self):
        r = self.check(lambda a: a[2]["head"].update(sha="b"*40))
        self.assertIn("PR_299_IDENTITY_CHANGED", r["reasons"])

    def test_pr_draft_conversion_or_merge_status_fails(self):
        r = self.check(lambda a: a[2].update(draft=False))
        self.assertIn("PR_299_ADMISSION_STATE_CHANGED", r["reasons"])

    def test_incomplete_data_is_blocked_not_success(self):
        r = self.check(lambda a: a[0].pop("state"))
        self.assertEqual(r["result"], "BLOCKED")
        self.assertEqual(r["workflow_disable"], "NOT_VERIFIED")
        self.assertIn("SOURCE_FIELDS_INCOMPLETE", r["reasons"])
        self.assertIs(r["release_authorized"], False)

    def test_unauthorized_workflow_read_is_blocked(self):
        w, b, p = fixtures()
        r = probe.observe_state(None, b, p)
        self.assertEqual(r["result"], "BLOCKED")
        self.assertEqual(r["reasons"], ["SOURCE_UNRESOLVED"])

    def test_even_if_protected_and_disabled_no_release_authorization(self):
        r = self.check(lambda a: a[1].update(protected=True))
        self.assertEqual(r["result"], "CONTROL_OBSERVED_ONLY")
        self.assertIs(r["release_authorized"], False)
        self.assertEqual(r["defender_adjudication"], "NOT_ESTABLISHED")
        self.assertEqual(r["reviewer_eligibility"], "NOT_ESTABLISHED")

    def test_no_live_flag_does_not_request_github_and_fails_closed(self):
        stream = StringIO()
        with patch.object(probe, "read_github_json", side_effect=AssertionError("must not fetch")):
            with contextlib.redirect_stdout(stream):
                code = probe.main([])
        self.assertEqual(code, 2)
        self.assertEqual(json.loads(stream.getvalue())["result"], "BLOCKED")

    def test_live_reads_only_exact_three_get_endpoints(self):
        w, b, p = fixtures()
        endpoints = [
            "/repos/ndrorchestration/aetherwake-jrpg/actions/workflows/362360040",
            "/repos/ndrorchestration/aetherwake-jrpg/branches/main",
            "/repos/ndrorchestration/aetherwake-jrpg/pulls/299",
        ]
        observed = []
        def fake_api(endpoint):
            observed.append(endpoint)
            return dict(zip(endpoints, (w, b, p)))[endpoint]
        stream = StringIO()
        with patch.object(probe, "read_github_json", side_effect=fake_api):
            with contextlib.redirect_stdout(stream):
                code = probe.main(["--live"])
        self.assertEqual(code, 1)  # unprotected main remains review-required
        self.assertEqual(observed, endpoints)
        self.assertFalse(json.loads(stream.getvalue())["release_authorized"])


if __name__ == "__main__":
    unittest.main()
