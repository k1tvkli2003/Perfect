#!/usr/bin/env python3
"""Validate and optionally submit a Perfect agent-plan v1 document.

Only a publishable project key and a short-lived authenticated owner access
token are supported. Secrets are read from environment variables so they do not
appear in the command line or committed files.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import datetime as dt
import json
import math
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Any


MAX_DOCUMENT_BYTES = 512 * 1024
MAX_ITEM_BYTES = 32 * 1024
MAX_PAYLOAD_BYTES = 24 * 1024
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
UUID_PATTERN = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
ALLOWED_KINDS = {"one_off_task", "recurring_task", "habit", "project"}
TOP_LEVEL_KEYS = {
    "schema_version",
    "submission_id",
    "agent_device_id",
    "source",
    "plan",
    "items",
}
SOURCE_KEYS = {"agent", "model", "version", "run_id", "generated_at"}
PLAN_KEYS = {"title", "summary"}
ITEM_KEYS = {"id", "kind", "title", "payload"}


class ContractError(ValueError):
    """A stable, user-safe contract validation failure."""


def _compact_json_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _expect_object(value: Any, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{path} must be a JSON object.")
    return value


def _expect_string(
    value: Any,
    path: str,
    *,
    minimum: int = 1,
    maximum: int,
) -> str:
    if not isinstance(value, str):
        raise ContractError(f"{path} must be a string.")
    trimmed = value.strip()
    if not minimum <= len(trimmed) <= maximum:
        raise ContractError(
            f"{path} must contain {minimum} to {maximum} characters."
        )
    return trimmed


def _expect_uuid(value: Any, path: str) -> str:
    if not isinstance(value, str) or UUID_PATTERN.fullmatch(value) is None:
        raise ContractError(f"{path} must be a UUID string.")
    try:
        parsed = uuid.UUID(value)
    except (ValueError, AttributeError) as error:
        raise ContractError(f"{path} must be a UUID string.") from error
    if parsed.int == 0:
        raise ContractError(f"{path} cannot be the nil UUID.")
    return str(parsed)


def _expect_exact_keys(
    value: dict[str, Any],
    path: str,
    *,
    allowed: set[str],
    required: set[str],
) -> None:
    missing = required - value.keys()
    if missing:
        raise ContractError(
            f"{path} is missing required field(s): {', '.join(sorted(missing))}."
        )
    unsupported = value.keys() - allowed
    if unsupported:
        raise ContractError(
            f"{path} has unsupported field(s): "
            f"{', '.join(sorted(unsupported))}."
        )


def validate_document(document: Any) -> dict[str, Any]:
    root = _expect_object(document, "$")
    _expect_exact_keys(
        root,
        "$",
        allowed=TOP_LEVEL_KEYS,
        required=TOP_LEVEL_KEYS,
    )
    if root["schema_version"] != 1 or isinstance(root["schema_version"], bool):
        raise ContractError("$.schema_version must be the integer 1.")
    _expect_uuid(root["submission_id"], "$.submission_id")
    _expect_uuid(root["agent_device_id"], "$.agent_device_id")

    source = _expect_object(root["source"], "$.source")
    _expect_exact_keys(
        source,
        "$.source",
        allowed=SOURCE_KEYS,
        required={"agent"},
    )
    _expect_string(source["agent"], "$.source.agent", maximum=80)
    if "model" in source:
        _expect_string(source["model"], "$.source.model", maximum=120)
    if "version" in source:
        _expect_string(source["version"], "$.source.version", maximum=80)
    if "run_id" in source:
        _expect_string(source["run_id"], "$.source.run_id", maximum=160)
    if "generated_at" in source:
        timestamp = _expect_string(
            source["generated_at"],
            "$.source.generated_at",
            maximum=80,
        )
        try:
            parsed_timestamp = dt.datetime.fromisoformat(
                timestamp.replace("Z", "+00:00")
            )
        except ValueError as error:
            raise ContractError(
                "$.source.generated_at must be an ISO-8601 timestamp."
            ) from error
        if parsed_timestamp.tzinfo is None:
            raise ContractError(
                "$.source.generated_at must include an explicit timezone."
            )

    plan = _expect_object(root["plan"], "$.plan")
    _expect_exact_keys(
        plan,
        "$.plan",
        allowed=PLAN_KEYS,
        required={"title"},
    )
    _expect_string(plan["title"], "$.plan.title", maximum=160)
    if "summary" in plan:
        if not isinstance(plan["summary"], str) or len(plan["summary"]) > 4000:
            raise ContractError(
                "$.plan.summary must be a string of at most 4000 characters."
            )

    items = root["items"]
    if not isinstance(items, list) or not 1 <= len(items) <= 100:
        raise ContractError("$.items must contain 1 to 100 planner proposals.")
    seen_ids: set[str] = set()
    for index, raw_item in enumerate(items):
        path = f"$.items[{index}]"
        item = _expect_object(raw_item, path)
        _expect_exact_keys(
            item,
            path,
            allowed=ITEM_KEYS,
            required={"id", "kind", "title"},
        )
        item_id = _expect_uuid(item["id"], f"{path}.id")
        if item_id in seen_ids:
            raise ContractError(f"{path}.id is duplicated in this document.")
        seen_ids.add(item_id)
        if item["kind"] not in ALLOWED_KINDS:
            raise ContractError(
                f"{path}.kind must be one of: {', '.join(sorted(ALLOWED_KINDS))}."
            )
        _expect_string(item["title"], f"{path}.title", maximum=160)
        payload = _expect_object(item.get("payload", {}), f"{path}.payload")
        if len(payload) > 128:
            raise ContractError(
                f"{path}.payload has more than 128 top-level fields."
            )
        if "agent_proposal" in payload:
            raise ContractError(
                f"{path}.payload.agent_proposal is server-managed."
            )
        if len(_compact_json_bytes(payload)) > MAX_PAYLOAD_BYTES:
            raise ContractError(f"{path}.payload exceeds the 24 KiB limit.")
        if len(_compact_json_bytes(item)) > MAX_ITEM_BYTES:
            raise ContractError(f"{path} exceeds the 32 KiB limit.")

    if len(_compact_json_bytes(root)) > MAX_DOCUMENT_BYTES:
        raise ContractError("The agent plan document exceeds the 512 KiB limit.")
    return root


def _unverified_jwt_role(token: str) -> str | None:
    """Read only the JWT role claim to reject obvious secret/admin tokens."""

    parts = token.split(".")
    if len(parts) != 3:
        return None
    try:
        padded = parts[1] + "=" * (-len(parts[1]) % 4)
        payload = json.loads(base64.urlsafe_b64decode(padded))
    except (ValueError, binascii.Error, json.JSONDecodeError):
        return None
    role = payload.get("role")
    return role if isinstance(role, str) else None


def _require_submission_environment() -> tuple[str, str, str]:
    url = os.environ.get("PERFECT_SUPABASE_URL", "").strip().rstrip("/")
    publishable_key = os.environ.get(
        "PERFECT_SUPABASE_PUBLISHABLE_KEY", ""
    ).strip()
    access_token = os.environ.get("PERFECT_SUPABASE_ACCESS_TOKEN", "").strip()
    missing = [
        name
        for name, value in (
            ("PERFECT_SUPABASE_URL", url),
            ("PERFECT_SUPABASE_PUBLISHABLE_KEY", publishable_key),
            ("PERFECT_SUPABASE_ACCESS_TOKEN", access_token),
        )
        if not value
    ]
    if missing:
        raise ContractError(
            "Submission requires environment variable(s): "
            + ", ".join(missing)
            + "."
        )
    parsed = urllib.parse.urlparse(url)
    is_local = parsed.hostname in {"localhost", "127.0.0.1", "::1"}
    if parsed.scheme != "https" and not (is_local and parsed.scheme == "http"):
        raise ContractError(
            "PERFECT_SUPABASE_URL must use HTTPS (HTTP is allowed only locally)."
        )
    if (
        parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or parsed.path not in {"", "/"}
    ):
        raise ContractError(
            "PERFECT_SUPABASE_URL must be an origin without credentials, "
            "query, fragment, or path."
        )
    hostname = (parsed.hostname or "").lower()
    if not is_local and not hostname.endswith(".supabase.co"):
        raise ContractError(
            "PERFECT_SUPABASE_URL must target the project's supabase.co "
            "origin (or an explicit local development host)."
        )
    if publishable_key.lower().startswith("sb_secret_"):
        raise ContractError(
            "PERFECT_SUPABASE_PUBLISHABLE_KEY is a secret key; this tool "
            "refuses it."
        )
    if access_token.lower().startswith("sb_secret_"):
        raise ContractError(
            "PERFECT_SUPABASE_ACCESS_TOKEN must be a user session token, "
            "not a project secret."
        )
    for label, token in (
        ("publishable key", publishable_key),
        ("access token", access_token),
    ):
        if _unverified_jwt_role(token) == "service_role":
            raise ContractError(
                f"The {label} is a service-role secret; this tool refuses it."
            )
    access_role = _unverified_jwt_role(access_token)
    if access_role is not None and access_role != "authenticated":
        raise ContractError(
            "PERFECT_SUPABASE_ACCESS_TOKEN is not an authenticated user token."
        )
    return url, publishable_key, access_token


def submit_document(document: dict[str, Any], timeout_seconds: float) -> Any:
    if (
        isinstance(timeout_seconds, bool)
        or not isinstance(timeout_seconds, (int, float))
        or not math.isfinite(timeout_seconds)
        or not 1 <= timeout_seconds <= 120
    ):
        raise ContractError("RPC timeout must be between 1 and 120 seconds.")
    url, publishable_key, access_token = _require_submission_environment()
    endpoint = f"{url}/rest/v1/rpc/submit_agent_plan"
    body = _compact_json_bytes({"p_document": document})
    request = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "apikey": publishable_key,
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(
            request, timeout=timeout_seconds
        ) as response:
            raw = response.read(MAX_RESPONSE_BYTES + 1)
            if len(raw) > MAX_RESPONSE_BYTES:
                raise ContractError("Perfect RPC response exceeds 4 MiB.")
    except urllib.error.HTTPError as error:
        error.close()
        raise ContractError(
            f"Perfect RPC rejected the document (HTTP {error.code})."
        ) from error
    except (urllib.error.URLError, TimeoutError) as error:
        raise ContractError("Perfect RPC is unreachable.") from error
    try:
        return json.loads(raw)
    except json.JSONDecodeError as error:
        raise ContractError("Perfect RPC returned invalid JSON.") from error


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Validate a Perfect agent-plan v1 JSON document. Add --submit to "
            "send it through the owner-authenticated Supabase RPC."
        )
    )
    parser.add_argument("document", type=Path, help="Path to agent-plan JSON")
    parser.add_argument(
        "--submit",
        action="store_true",
        help="Submit after validation (default is validation-only).",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="RPC timeout in seconds (default: 30).",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        document = json.loads(args.document.read_text(encoding="utf-8"))
        validated = validate_document(document)
        if not args.submit:
            print(
                "Valid Perfect agent plan: "
                f"{len(validated['items'])} proposed item(s), "
                f"submission {validated['submission_id']}."
            )
            return 0
        result = submit_document(validated, args.timeout)
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    except (OSError, json.JSONDecodeError, ContractError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
