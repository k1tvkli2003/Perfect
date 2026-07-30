from __future__ import annotations

import base64
import copy
import importlib.util
import io
import json
import os
import unittest
import urllib.error
from unittest import mock
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "submit_agent_plan.py"
SPEC = importlib.util.spec_from_file_location("submit_agent_plan", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
submit_agent_plan = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(submit_agent_plan)


class SubmitAgentPlanContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.document = json.loads(
            (
                REPO_ROOT
                / "supabase"
                / "contracts"
                / "examples"
                / "agent-plan-v1.example.json"
            ).read_text(encoding="utf-8")
        )

    def test_example_is_valid(self) -> None:
        validated = submit_agent_plan.validate_document(self.document)
        self.assertEqual(validated["schema_version"], 1)
        self.assertEqual(len(validated["items"]), 3)

    def test_duplicate_entity_id_is_rejected(self) -> None:
        duplicate = copy.deepcopy(self.document["items"][0])
        self.document["items"].append(duplicate)
        with self.assertRaisesRegex(
            submit_agent_plan.ContractError,
            "duplicated",
        ):
            submit_agent_plan.validate_document(self.document)

    def test_server_managed_review_metadata_is_rejected(self) -> None:
        self.document["items"][0]["payload"]["agent_proposal"] = {
            "review": {"status": "accepted"}
        }
        with self.assertRaisesRegex(
            submit_agent_plan.ContractError,
            "server-managed",
        ):
            submit_agent_plan.validate_document(self.document)

    def test_unknown_top_level_field_is_rejected(self) -> None:
        self.document["owner_id"] = "3be2d15c-f53b-4865-9bd0-e219ca026813"
        with self.assertRaisesRegex(
            submit_agent_plan.ContractError,
            "unsupported field",
        ):
            submit_agent_plan.validate_document(self.document)

    def test_service_role_jwt_is_detected_without_printing_it(self) -> None:
        def segment(value: dict[str, str]) -> str:
            raw = json.dumps(value, separators=(",", ":")).encode()
            return base64.urlsafe_b64encode(raw).decode().rstrip("=")

        token = (
            f"{segment({'alg': 'none'})}."
            f"{segment({'role': 'service_role'})}.signature"
        )
        self.assertEqual(
            submit_agent_plan._unverified_jwt_role(token),
            "service_role",
        )

    def test_modern_supabase_secret_key_is_refused(self) -> None:
        with mock.patch.dict(
            os.environ,
            {
                "PERFECT_SUPABASE_URL": "https://perfect.example.supabase.co",
                "PERFECT_SUPABASE_PUBLISHABLE_KEY": "sb_secret_do-not-use",
                "PERFECT_SUPABASE_ACCESS_TOKEN": "not-inspected-yet",
            },
            clear=True,
        ):
            with self.assertRaisesRegex(
                submit_agent_plan.ContractError,
                "secret key",
            ):
                submit_agent_plan._require_submission_environment()

    def test_uuid_validation_matches_database_canonical_shape(self) -> None:
        self.document["submission_id"] = (
            "{3be2d15c-f53b-4865-9bd0-e219ca026813}"
        )
        with self.assertRaisesRegex(
            submit_agent_plan.ContractError,
            "UUID string",
        ):
            submit_agent_plan.validate_document(self.document)

    def test_supabase_origin_rejects_embedded_credentials_and_paths(self) -> None:
        for unsafe_url in (
            "https://user:password@perfect.example.supabase.co",
            "https://perfect.example.supabase.co/rest/v1",
            "https://perfect.example.supabase.co?token=unsafe",
        ):
            with self.subTest(url=unsafe_url), mock.patch.dict(
                os.environ,
                {
                    "PERFECT_SUPABASE_URL": unsafe_url,
                    "PERFECT_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                    "PERFECT_SUPABASE_ACCESS_TOKEN": "owner-session",
                },
                clear=True,
            ):
                with self.assertRaisesRegex(
                    submit_agent_plan.ContractError,
                    "must be an origin",
                ):
                    submit_agent_plan._require_submission_environment()

    def test_supabase_credentials_cannot_be_sent_to_an_arbitrary_host(self) -> None:
        with mock.patch.dict(
            os.environ,
            {
                "PERFECT_SUPABASE_URL": "https://attacker.example",
                "PERFECT_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                "PERFECT_SUPABASE_ACCESS_TOKEN": "owner-session",
            },
            clear=True,
        ):
            with self.assertRaisesRegex(
                submit_agent_plan.ContractError,
                "supabase.co",
            ):
                submit_agent_plan._require_submission_environment()

    def test_timeout_is_finite_and_bounded_before_network_access(self) -> None:
        for timeout in (0, 121, float("inf"), float("nan")):
            with self.subTest(timeout=timeout), self.assertRaisesRegex(
                submit_agent_plan.ContractError,
                "between 1 and 120",
            ):
                submit_agent_plan.submit_document(self.document, timeout)

    def test_http_error_body_is_never_reflected(self) -> None:
        remote_error = urllib.error.HTTPError(
            "https://perfect.example.supabase.co/rest/v1/rpc/submit_agent_plan",
            400,
            "Bad Request",
            {},
            io.BytesIO(b'{"message":"secret=must-not-be-reflected"}'),
        )
        with mock.patch.dict(
            os.environ,
            {
                "PERFECT_SUPABASE_URL": "https://perfect.example.supabase.co",
                "PERFECT_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                "PERFECT_SUPABASE_ACCESS_TOKEN": "owner-session",
            },
            clear=True,
        ), mock.patch.object(
            submit_agent_plan.urllib.request,
            "urlopen",
            side_effect=remote_error,
        ):
            with self.assertRaises(submit_agent_plan.ContractError) as caught:
                submit_agent_plan.submit_document(self.document, 30)
        self.assertIn("HTTP 400", str(caught.exception))
        self.assertNotIn("must-not-be-reflected", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
