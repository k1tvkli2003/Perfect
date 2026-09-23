from __future__ import annotations

import base64
import hashlib
import json
import os
import pathlib
import time
import urllib.request

ENDPOINT = "http://127.0.0.1:20128/v1/images/generations"
MODEL = "cx/gpt-5.5-image"
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "artifacts" / "stage12-modernize" / "directions"

DIRECTIONS = {
    "a-midnight-command-center": (
        "High fidelity desktop product UI concept for Perfect, a private daily planner. "
        "Distinctive midnight command center: deep ink navy shell, narrow labeled left rail, "
        "compact command header, warm ivory opaque task cards in a true vertical day timeline, "
        "electric cobalt primary action, restrained coral urgency, persistent 360px context rail "
        "with useful selected-task details. Show Now, Next, Scheduled, Anytime, open time block, "
        "and labeled Add task. Dense but calm, premium editorial SaaS, no decorative hero image, "
        "no giant empty cards, no mystery floating button. Realistic app screenshot composition. "
        "Avoid readable fake text, logo, watermark, and placeholder bars."
    ),
    "b-paper-ledger": (
        "High fidelity desktop and tablet product UI concept for Perfect, a private daily planner. "
        "Daylight paper ledger direction: warm white canvas, charcoal ink, one cobalt accent, "
        "thin editorial rules, compact top command bar, action-first Today queue, strong Next task "
        "block, real time rail with hour labels, separate Anytime checklist, labeled bottom/side nav, "
        "clear + Add task control. Use typography and spacing as identity, not gradients or card piles. "
        "Show useful density for many tasks, selected details in a narrow attached rail, no huge greeting, "
        "no ambiguous percentage bubbles, no unlabeled icon-only controls. Realistic app screenshot. "
        "Avoid readable fake text, logo, watermark, and placeholder bars."
    ),
    "c-orbit-workbench": (
        "High fidelity desktop product UI concept for Perfect, a private daily planner. "
        "Original orbit workbench: asymmetrical but disciplined layout, dark graphite canvas, "
        "central luminous timeline spine carrying the Next action, small warm paper task modules "
        "anchored to time, left navigation rail, right contextual planning orbit with next open block, "
        "conflict and notes. One cobalt current-time line, green completion only, coral overdue only. "
        "Memorable spatial composition while remaining highly usable, keyboard-friendly, readable, "
        "and dense. No photo background, no decorative dashboard charts, no giant empty inspector, "
        "no mystery floating target. Realistic premium app screenshot. Avoid readable fake text, "
        "logo, watermark, and placeholder bars."
    ),
}


def find_b64(value: object) -> str | None:
    if isinstance(value, dict):
        direct = value.get("b64_json")
        if isinstance(direct, str) and direct:
            return direct
        for child in value.values():
            result = find_b64(child)
            if result:
                return result
    elif isinstance(value, list):
        for child in value:
            result = find_b64(child)
            if result:
                return result
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
    encoded = None
    for value in reversed(objects):
        encoded = find_b64(value)
        if encoded:
            break
    if not encoded:
        raise RuntimeError("image response omitted b64_json")
    data = base64.b64decode(encoded, validate=True)
    if not (data.startswith(b"RIFF") and data[8:12] == b"WEBP"):
        raise RuntimeError("image response was not WebP")
    return data


def generate(name: str, prompt: str, key: str) -> dict[str, object]:
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "n": 1,
        "quality": "high",
        "size": "1536x1024",
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
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=900) as response:
        body = response.read()
        content_type = response.headers.get("Content-Type", "")
    data = extract(body, content_type)
    output = OUT_DIR / f"{name}.webp"
    output.write_bytes(data)
    return {
        "name": name,
        "model": MODEL,
        "endpoint": "loopback-9router",
        "credentialStored": False,
        "promptSha256": hashlib.sha256(prompt.encode()).hexdigest(),
        "path": str(output.resolve()),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "mime": "image/webp",
    }


def main() -> int:
    key = os.environ.get("NINEROUTER_API_KEY", "").strip()
    if not key:
        raise RuntimeError("NINEROUTER_API_KEY missing")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for name, prompt in DIRECTIONS.items():
        print(f"generating {name}", flush=True)
        results.append(generate(name, prompt, key))
        time.sleep(1)
    receipt = {
        "schemaVersion": 1,
        "status": "PASS_DIRECTIONS_GENERATED",
        "model": MODEL,
        "endpoint": "loopback-9router",
        "credentialStored": False,
        "directions": results,
    }
    (OUT_DIR / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
