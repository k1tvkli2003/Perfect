#!/usr/bin/env python3
"""Fail when protected environment values are present in release artifacts.

Only environment-variable names and artifact paths are accepted on argv. Secret
values are read from the process environment and are never printed, hashed into
logs, or written to disk by this verifier.
"""

from __future__ import annotations

import argparse
import io
import os
from pathlib import Path
import sys
import zipfile


CHUNK_SIZE = 1024 * 1024
MIN_SECRET_BYTES = 8


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--artifact",
        action="append",
        required=True,
        help="File or directory to scan; may be supplied more than once.",
    )
    parser.add_argument(
        "--secret-env",
        action="append",
        required=True,
        help="Environment variable whose value must be absent from artifacts.",
    )
    return parser.parse_args()


def _secret_needles(names: list[str]) -> dict[str, tuple[bytes, ...]]:
    needles: dict[str, tuple[bytes, ...]] = {}
    for name in names:
        value = os.environ.get(name, "")
        if not value:
            continue
        encoded = tuple(
            candidate
            for candidate in {
                value.encode("utf-8"),
                value.encode("utf-16-le"),
                value.encode("utf-16-be"),
            }
            if len(candidate) >= MIN_SECRET_BYTES
        )
        if not encoded:
            raise ValueError(
                f"Protected value {name} is too short for a reliable artifact scan."
            )
        needles[name] = encoded
    if not needles:
        raise ValueError("No protected environment value was configured for the scan.")
    return needles


def _stream_match(
    stream: io.BufferedIOBase,
    needles: dict[str, tuple[bytes, ...]],
) -> str | None:
    longest = max(len(value) for values in needles.values() for value in values)
    overlap = max(0, longest - 1)
    tail = b""
    while True:
        chunk = stream.read(CHUNK_SIZE)
        if not chunk:
            return None
        window = tail + chunk
        for name, values in needles.items():
            if any(value in window for value in values):
                return name
        tail = window[-overlap:] if overlap else b""


def _scan_file(path: Path, needles: dict[str, tuple[bytes, ...]]) -> tuple[str, str] | None:
    with path.open("rb") as stream:
        matched = _stream_match(stream, needles)
    if matched is not None:
        return matched, str(path)

    if not zipfile.is_zipfile(path):
        return None
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            with archive.open(info, "r") as stream:
                matched = _stream_match(stream, needles)
            if matched is not None:
                return matched, f"{path}!/{info.filename}"
    return None


def _artifact_files(artifacts: list[str]) -> list[Path]:
    files: list[Path] = []
    for raw in artifacts:
        path = Path(raw).resolve()
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            files.extend(candidate for candidate in path.rglob("*") if candidate.is_file())
        else:
            raise FileNotFoundError(f"Artifact path does not exist: {path}")
    if not files:
        raise FileNotFoundError("No artifact files were available to scan.")
    return files


def main() -> int:
    args = _arguments()
    try:
        needles = _secret_needles(args.secret_env)
        files = _artifact_files(args.artifact)
        for path in files:
            match = _scan_file(path, needles)
            if match is None:
                continue
            name, location = match
            print(
                f"::error::Protected value {name} was found in release artifact {location}.",
                file=sys.stderr,
            )
            return 1
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"::error::Artifact secret scan could not run: {error}", file=sys.stderr)
        return 2

    print(
        f"Artifact secret absence verified: {len(files)} file(s), "
        f"{len(needles)} protected value(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
