from __future__ import annotations

import base64
import hashlib
import json
import os
import pathlib
import urllib.request

ENDPOINT = "http://127.0.0.1:20128/v1/images/generations"
MODEL = "cx/gpt-5.5-image"
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "artifacts" / "stage12-modernize" / "canonical"

VARIANTS = {
    "phone-dark-390x844": {
        "size": "1024x1536",
        "prompt": "High fidelity portrait mobile UI screenshot for Perfect private daily planner, 390x844 composition. Midnight Ink dark mode: deep ink navy canvas, compact top bar with Today and date, no giant greeting, no decorative hero. One obvious Next task on warm ivory card with time, title, metadata and labeled Start action. Below, compact day progress strip, chronological Scheduled list with clear times, separate Anytime and Habits sections, one blue + Add task action, labeled four-item bottom navigation. Cobalt means action/selection, coral urgency only, green completion only. Dense but calm, 44px touch targets, readable sans typography, no percentages for binary tasks, no mystery floating target, no photo, no glass overload, no logo or watermark, avoid readable fake text.",
    },
    "tablet-light-834x1112": {
        "size": "1024x1536",
        "prompt": "High fidelity portrait tablet UI screenshot for Perfect private daily planner, 834x1112 composition. Paper Ledger light mode: warm paper canvas, charcoal ink, cobalt action accent. Compact command header, Today/date and + Add task. Main agenda/timeline owns width; narrow collapsible contextual side sheet only when selected. Clear Now, Next, Scheduled, Anytime, Habits groups; true time rail only for scheduled work, flexible items never placed on fake hours. Selected task uses subtle cobalt tint and attached detail sheet with notes and schedule. Editorial typography, thin neutral rules, restrained rounded corners, useful density, 48px touch targets, readable contrast, no giant hero, no card pile, no decorative charts, no mystery FAB, no logo or watermark, avoid readable fake text.",
    },
    "desktop-light-1536x1024": {
        "size": "1536x1024",
        "prompt": "High fidelity desktop UI screenshot for Perfect private daily planner, 1536x1024. Same geometry as premium Midnight Command Center but Paper Ledger light mode. Flat narrow labeled navigation rail, compact command header, dominant central Today workbench. Separate focus queue with one Next task, true chronological schedule with hour rail and blue current-time line, flexible Anytime queue and compact Habits. Attached 360px selected-task context rail, useful notes/schedule/actions, no empty inspector. Warm ivory/white surfaces, charcoal text, cobalt primary, coral urgency only, green completion only. Dense elegant operational UI, strong alignment, no giant greeting or hero, no card-on-card piles, no decorative gradients, no unlabeled mystery controls, no logo or watermark, avoid readable fake text.",
    },
}


def find_b64(value: object) -> str | None:
    if isinstance(value, dict):
        candidate = value.get("b64_json")
        if isinstance(candidate, str) and candidate:
            return candidate
        for child in value.values():
            found = find_b64(child)
            if found:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_b64(child)
            if found:
                return found
    return None


def extract(body: bytes, content_type: str) -> bytes:
    text = body.decode("utf-8")
    objects: list[object] = []
    if "event-stream" in content_type or text.lstrip().startswith("data:"):
        for line in text.splitlines():
            if not line.startswith("data:"):
                continue
            payload = line[5:].strip()
            if payload and payload != "[DONE]":
                try:
                    objects.append(json.loads(payload))
                except json.JSONDecodeError:
                    pass
    else:
        objects.append(json.loads(text))
    for value in reversed(objects):
        encoded = find_b64(value)
        if encoded:
            data = base64.b64decode(encoded, validate=True)
            if data.startswith(b"RIFF") and data[8:12] == b"WEBP":
                return data
    raise RuntimeError("image response omitted valid WebP b64_json")


def generate(name: str, spec: dict[str, str], key: str) -> dict[str, object]:
    payload = {
        "model": MODEL,
        "prompt": spec["prompt"],
        "n": 1,
        "quality": "high",
        "size": spec["size"],
        "background": "opaque",
        "output_format": "webp",
        "stream": True,
        "partial_images": 0,
    }
    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
        },
        method="POST",
    )
    with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(
        request, timeout=900
    ) as response:
        data = extract(response.read(), response.headers.get("Content-Type", ""))
    path = OUT / f"{name}.webp"
    path.write_bytes(data)
    return {
        "name": name,
        "model": MODEL,
        "endpoint": "loopback-9router",
        "credentialStored": False,
        "promptSha256": hashlib.sha256(spec["prompt"].encode()).hexdigest(),
        "path": str(path.resolve()),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "mime": "image/webp",
    }


def main() -> int:
    key = os.environ.get("NINEROUTER_API_KEY", "").strip()
    if not key:
        raise RuntimeError("NINEROUTER_API_KEY missing")
    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    for name, spec in VARIANTS.items():
        print(f"generating {name}", flush=True)
        results.append(generate(name, spec, key))
    receipt = {
        "schemaVersion": 1,
        "status": "PASS_CANONICAL_VARIANTS_GENERATED",
        "model": MODEL,
        "endpoint": "loopback-9router",
        "credentialStored": False,
        "variants": results,
    }
    (OUT / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
