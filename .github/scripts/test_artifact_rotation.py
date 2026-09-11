"""Offline destructive-boundary tests. Never contacts GitHub."""

import copy
import datetime as dt
import json
import subprocess
import unittest

from rotate_artifact_transport import GitHub, RotationError, WORKFLOW_PATH, rotate

NOW = dt.datetime(2026, 9, 11, tzinfo=dt.timezone.utc)
VERSION = "1.1.0-build.2061"


def run(identifier, **changes):
    return {
        "id": identifier, "workflow_id": 7, "run_number": identifier,
        "status": "completed", "conclusion": "success", "head_branch": "main",
        "event": "push", "path": WORKFLOW_PATH, **changes,
    }


def artifact(identifier, owner, suffix="windows-x64-msix-configured-private",
             version=VERSION, **changes):
    return {
        "id": identifier, "name": f"perfect-{version}-{suffix}",
        "workflow_run": {"id": owner}, "expired": False,
        "expires_at": "2026-09-25T00:00:00Z", **changes,
    }


class FakeAPI:
    def __init__(self):
        self.runs = {1: run(1), 2: run(2, status="in_progress", conclusion=None)}
        self.items = [artifact(10, 1, version="1.1.0-build.2060"),
                      artifact(20, 2),
                      artifact(21, 2, "android-stable-private-configured-private")]
        self.deleted = []
        self.lookups = {}
        self.on_run = None
        self.sticky = False

    def run(self, identifier):
        self.lookups[identifier] = self.lookups.get(identifier, 0) + 1
        if self.on_run:
            self.on_run(identifier, self.lookups[identifier])
        return copy.deepcopy(self.runs[identifier])

    def artifacts(self):
        return copy.deepcopy(self.items)

    def request(self, endpoint, *, delete=False):
        assert delete and endpoint.startswith("artifacts/")
        identifier = int(endpoint.split("/")[1])
        self.deleted.append(identifier)
        if not self.sticky:
            self.items = [item for item in self.items if item["id"] != identifier]


class RotationTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeAPI()

    def rotate(self, result="success", **kwargs):
        return rotate(self.api, 2, VERSION, result, now=NOW, clock=lambda: NOW,
                      **kwargs)

    def test_default_dry_run_does_not_delete(self):
        result = self.rotate()
        self.assertEqual(result["candidate_ids"], [10, 21])
        self.assertEqual(self.api.deleted, [])

    def test_success_keeps_only_current_baseline_in_owned_transport(self):
        manifests = []
        result = self.rotate(apply=True, report=manifests.append)
        self.assertEqual(result["deleted_ids"], [10, 21])
        self.assertEqual([item["id"] for item in self.api.items], [20])
        self.assertEqual(manifests[0]["candidate_ids"], [10, 21])

    def test_failed_publish_preserves_historical_baseline(self):
        result = self.rotate("failure", apply=True)
        self.assertEqual(result["deleted_ids"], [20, 21])
        self.assertTrue(result["historical_baseline_available"])

    def test_expired_historical_baseline_is_not_reported_available(self):
        self.api.items[0]["expires_at"] = "2026-08-28T00:00:00Z"
        self.assertFalse(self.rotate("skipped")["historical_baseline_available"])

    def test_unrelated_names_workflows_and_branches_are_preserved(self):
        self.api.runs[3] = run(3, workflow_id=8, run_number=1)
        self.api.runs[4] = run(4, head_branch="feature", run_number=1)
        self.api.items += [artifact(30, 3), artifact(40, 4),
                           artifact(50, 1, name="owner-upload"),
                           artifact(51, 1, name="Perfect-backup.zip")]
        self.assertEqual(self.rotate(apply=True)["deleted_ids"], [10, 21])

    def test_every_nonterminal_status_protected(self):
        for status in ["queued", "in_progress", "waiting", "pending", "requested", "new"]:
            with self.subTest(status=status):
                self.api.runs[1]["status"] = status
                self.assertEqual(self.rotate()["candidate_ids"], [21])

    def test_newer_runs_protected(self):
        self.api.runs[1]["run_number"] = 3
        self.assertEqual(self.rotate()["candidate_ids"], [21])

    def test_missing_expired_duplicate_baseline_fail_before_delete(self):
        for mode in ["missing", "expired", "duplicate", "naive_expiry"]:
            with self.subTest(mode=mode):
                self.api = FakeAPI()
                if mode == "missing":
                    self.api.items.pop(1)
                elif mode == "duplicate":
                    self.api.items.append(artifact(22, 2))
                else:
                    self.api.items[1]["expires_at"] = (
                        "2026-08-01T00:00:00Z" if mode == "expired"
                        else "2026-09-25T00:00:00")
                with self.assertRaises(RotationError):
                    self.rotate(apply=True)
                self.assertEqual(self.api.deleted, [])

    def test_untrusted_current_run_rejected(self):
        for changes in [{"head_branch": "feature"}, {"event": "pull_request"},
                        {"path": ".github/workflows/other.yml"}]:
            self.api.runs[2] = run(2, **changes)
            with self.assertRaises(RotationError):
                self.rotate(apply=True)
        self.assertEqual(self.api.deleted, [])

    def test_version_mismatch_rejected(self):
        self.api.items.append(artifact(22, 2, version="1.1.0-build.9999"))
        with self.assertRaises(RotationError):
            self.rotate(apply=True)
        self.assertEqual(self.api.deleted, [])

    def test_run_read_failure_before_delete(self):
        def fail(identifier, count):
            if identifier == 2 and count == 2:
                raise RotationError("API down")
        self.api.on_run = fail
        with self.assertRaises(RotationError):
            self.rotate(apply=True)
        self.assertEqual(self.api.deleted, [])

    def test_rerun_between_inventory_and_apply_is_protected(self):
        def rerun(identifier, count):
            if identifier == 1 and count == 2:
                self.api.runs[1]["status"] = "in_progress"
        self.api.on_run = rerun
        self.assertEqual(self.rotate(apply=True)["deleted_ids"], [21])

    def test_changed_workflow_prevents_all_deletes(self):
        def change(identifier, count):
            if identifier == 2 and count == 2:
                self.api.runs[2]["workflow_id"] = 8
        self.api.on_run = change
        with self.assertRaises(RotationError):
            self.rotate(apply=True)
        self.assertEqual(self.api.deleted, [])

    def test_postcondition_failure_is_not_silent(self):
        self.api.sticky = True
        with self.assertRaisesRegex(RotationError, "postcondition"):
            self.rotate(apply=True)


class APITests(unittest.TestCase):
    def api(self, outputs):
        self.calls = []
        def runner(command, **kwargs):
            self.calls.append(command)
            value = outputs.pop(0)
            if isinstance(value, Exception):
                raise value
            return subprocess.CompletedProcess(command, value[0], value[1], "")
        return GitHub("owner/Perfect", runner=runner, sleep=lambda seconds: None)

    def test_failed_inventory_retries_and_stops(self):
        api = self.api([(1, "private")] * 3)
        with self.assertRaises(RotationError):
            api.artifacts()
        self.assertEqual(len(self.calls), 3)
        self.assertTrue(all("--method" not in call for call in self.calls))

    def test_invalid_json_and_schema_fail_closed(self):
        for text in ["oops", "{}", "[]", '[{"artifacts":null}]',
                     '[{"artifacts":[{"id":true,"name":"x"}]}]']:
            with self.subTest(text=text), self.assertRaises(RotationError):
                self.api([(0, text)]).artifacts()

    def test_paginated_inventory_and_duplicate_detection(self):
        page = {"artifacts": [artifact(10, 1)]}
        api = self.api([(0, json.dumps([page, {"artifacts": []}]))])
        self.assertEqual(len(api.artifacts()), 1)
        self.assertIn("--slurp", self.calls[0])
        with self.assertRaises(RotationError):
            self.api([(0, json.dumps([page, page]))]).artifacts()

    def test_run_identity_validation(self):
        for value in [run(3), run(2, run_number=0), run(2, status="")]:
            with self.assertRaises(RotationError):
                self.api([(0, json.dumps(value))]).run(2)

    def test_timeout_then_success(self):
        api = self.api([subprocess.TimeoutExpired("gh", 45),
                        (0, json.dumps(run(2)))])
        self.assertEqual(api.run(2)["id"], 2)
        self.assertEqual(len(self.calls), 2)

    def test_repository_input_validation(self):
        with self.assertRaises(RotationError):
            GitHub("../../other")


if __name__ == "__main__":
    unittest.main()
