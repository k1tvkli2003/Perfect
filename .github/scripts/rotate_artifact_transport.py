"""Fail-closed rotation of this workflow's named Perfect release transport.

Default is a read-only dry run. Release assets are never addressed by this tool.
"""

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import time


VERSION = r"\d+\.\d+\.\d+-build\.\d+"
TRANSPORT = re.compile(
    rf"perfect-{VERSION}-(?:"
    r"android-(?:stable-private-configured-private|"
    r"debug-fallback-verification-only-unconfigured)|"
    r"windows-x64-(?:portable-(?:configured-private|"
    r"verification-only-unconfigured)|msix-configured-private))"
)
WORKFLOW_PATH = ".github/workflows/verify.yml"


class RotationError(RuntimeError):
    pass


class GitHub:
    def __init__(self, repository, runner=subprocess.run, sleep=time.sleep):
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
            raise RotationError("Invalid repository identity.")
        self.base = f"repos/{repository}/actions"
        self.runner = runner
        self.sleep = sleep

    def request(self, endpoint, *, delete=False, pages=False):
        command = ["gh", "api"]
        if delete:
            command += ["--method", "DELETE"]
        if pages:
            command += ["--paginate", "--slurp"]
        command.append(f"{self.base}/{endpoint}")
        for attempt in range(3):
            try:
                result = self.runner(
                    command, capture_output=True, text=True, timeout=45, check=False
                )
            except (subprocess.TimeoutExpired, OSError):
                result = None
            if result is not None and result.returncode == 0:
                if delete:
                    return None
                try:
                    return json.loads(result.stdout)
                except (ValueError, TypeError) as error:
                    raise RotationError("GitHub returned invalid JSON.") from error
            if attempt < 2:
                self.sleep(2 * (attempt + 1))
        # Do not echo command output: API stderr may contain private metadata.
        raise RotationError("GitHub API failed after 3 attempts; rotation stopped.")

    def artifacts(self):
        pages = self.request("artifacts?per_page=100", pages=True)
        if not isinstance(pages, list) or not pages:
            raise RotationError("Missing paginated artifact inventory.")
        artifacts = []
        for page in pages:
            if not isinstance(page, dict) or not isinstance(page.get("artifacts"), list):
                raise RotationError("Malformed artifact inventory page.")
            artifacts.extend(page["artifacts"])
        seen = set()
        for artifact in artifacts:
            if not isinstance(artifact, dict) or not isinstance(artifact.get("name"), str):
                raise RotationError("Malformed artifact record.")
            artifact_id = positive_id(artifact.get("id"))
            if artifact_id in seen:
                raise RotationError("Duplicate artifact ID; inventory changed during pagination.")
            seen.add(artifact_id)
        return artifacts

    def run(self, run_id):
        run = self.request(f"runs/{positive_id(run_id)}")
        if not isinstance(run, dict) or positive_id(run.get("id")) != run_id:
            raise RotationError("Workflow run identity mismatch.")
        positive_id(run.get("workflow_id"))
        positive_id(run.get("run_number"))
        if not isinstance(run.get("status"), str) or not run["status"]:
            raise RotationError("Workflow run status missing.")
        return run


def positive_id(value):
    if type(value) is not int or value <= 0:
        raise RotationError("Missing or invalid numeric GitHub identity.")
    return value


def artifact_run(artifact):
    run = artifact.get("workflow_run")
    if not isinstance(run, dict):
        raise RotationError("Transport artifact has no workflow run.")
    return positive_id(run.get("id"))


def available(artifact, now):
    if artifact.get("expired") is not False:
        return False
    try:
        expires = dt.datetime.fromisoformat(artifact["expires_at"].replace("Z", "+00:00"))
        return expires > now
    except (KeyError, ValueError, TypeError):
        return False


def same_workflow(run, current):
    return (
        run["workflow_id"] == current["workflow_id"]
        and run.get("path") == WORKFLOW_PATH
    )


def rotate(api, run_id, version, publish_result, *, apply=False, now=None,
           clock=lambda: dt.datetime.now(dt.timezone.utc), report=lambda value: None):
    if not re.fullmatch(VERSION, version):
        raise RotationError("Invalid Perfect artifact version.")
    if publish_result not in {"success", "failure", "cancelled", "skipped"}:
        raise RotationError("Unknown publication result.")
    now = now or clock()
    current = api.run(run_id)
    if (
        current.get("path") != WORKFLOW_PATH
        or current.get("head_branch") != "main"
        or current.get("event") not in {"push", "workflow_dispatch"}
    ):
        raise RotationError("Rotation requires the trusted main Perfect workflow.")

    inventory = api.artifacts()
    owned = [item for item in inventory if TRANSPORT.fullmatch(item["name"])]
    runs = {run_id: current}
    # Complete every API/schema preflight before the first destructive request.
    for item in owned:
        owner = artifact_run(item)
        if owner not in runs:
            runs[owner] = api.run(owner)
    keep_name = f"perfect-{version}-windows-x64-msix-configured-private"
    keep_id = None
    if publish_result == "success":
        keep = [
            item for item in owned
            if item["name"] == keep_name and artifact_run(item) == run_id
        ]
        if len(keep) != 1 or not available(keep[0], now):
            raise RotationError(
                "Expected exactly one unexpired current signed Windows upgrade baseline."
            )
        keep_id = keep[0]["id"]

    candidates = []
    for item in owned:
        owner = artifact_run(item)
        run = runs[owner]
        if (item["id"] == keep_id or not same_workflow(run, current)
                or run.get("head_branch") != "main"
                or run.get("event") not in {"push", "workflow_dispatch"}):
            continue
        if owner == run_id and not item["name"].startswith(f"perfect-{version}-"):
            raise RotationError("Current-run transport version mismatch.")
        # Unknown/new statuses are protected too, not merely queued/in_progress.
        if owner != run_id and (
            run["status"] != "completed" or run["run_number"] >= current["run_number"]
        ):
            continue
        if publish_result != "success" and owner != run_id:
            continue
        candidates.append(item)

    deleted = []
    report({
        "mode": "apply" if apply else "dry-run",
        "candidate_ids": [item["id"] for item in candidates],
        "protected_current_baseline_id": keep_id,
    })
    if apply:
        # Recheck every candidate before any DELETE, so a failed run lookup
        # cannot produce a partially applied preflight.
        fresh_runs = {}
        for item in candidates:
            owner = artifact_run(item)
            if owner not in fresh_runs:
                fresh_runs[owner] = api.run(owner)
        for item in candidates:
            owner = artifact_run(item)
            fresh = fresh_runs[owner]
            if (not same_workflow(fresh, current)
                    or fresh.get("head_branch") != "main"
                    or fresh.get("event") not in {"push", "workflow_dispatch"}
                    or fresh["run_number"] != runs[owner]["run_number"]):
                raise RotationError("Workflow changed after inventory; rotation stopped.")
        for item in candidates:
            owner = artifact_run(item)
            fresh = fresh_runs[owner]
            if owner != run_id and fresh["status"] != "completed":
                # A completed run can be rerun between preflight and deletion.
                continue
            api.request(f"artifacts/{item['id']}", delete=True)
            deleted.append(item["id"])
        remaining = api.artifacts()
        remaining_ids = {item["id"] for item in remaining}
        if remaining_ids.intersection(deleted):
            raise RotationError("Deleted transport still present; postcondition failed.")
        if keep_id is not None:
            preserved = [item for item in remaining if item["id"] == keep_id]
            if len(preserved) != 1 or not available(
                preserved[0], clock()
            ):
                raise RotationError("Current signed Windows baseline is missing or expired.")
    else:
        remaining = inventory

    # Failed publication never implies that a usable historical baseline exists.
    historical = [
        item for item in remaining
        if item["name"].endswith("-windows-x64-msix-configured-private")
        and TRANSPORT.fullmatch(item["name"])
        and available(item, now)
        and artifact_run(item) in runs
        and same_workflow(runs[artifact_run(item)], current)
        and runs[artifact_run(item)].get("head_branch") == "main"
        and runs[artifact_run(item)]["status"] == "completed"
        and runs[artifact_run(item)].get("conclusion") == "success"
        and runs[artifact_run(item)]["run_number"] < current["run_number"]
    ]
    return {
        "mode": "apply" if apply else "dry-run",
        "candidate_ids": [item["id"] for item in candidates],
        "deleted_ids": deleted,
        "current_baseline_id": keep_id,
        "historical_baseline_available": bool(historical),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        result = rotate(
            GitHub(os.environ["GITHUB_REPOSITORY"]),
            int(os.environ["GITHUB_RUN_ID"]),
            os.environ["PERFECT_ARTIFACT_VERSION"],
            os.environ["PERFECT_PUBLISH_RESULT"],
            apply=args.apply,
            report=lambda manifest: print(json.dumps(manifest, sort_keys=True), flush=True),
        )
    except (KeyError, ValueError, RotationError) as error:
        print(f"::error::{error}")
        return 1
    print(json.dumps(result, sort_keys=True))
    if (
        os.environ["PERFECT_PUBLISH_RESULT"] != "success"
        and not result["historical_baseline_available"]
    ):
        print("::warning::No unexpired prior successful Windows upgrade baseline was found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
