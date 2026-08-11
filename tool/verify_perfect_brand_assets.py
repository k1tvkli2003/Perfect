"""Fail fast when Perfect! brand sources, derivatives or consumers drift."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BRAND_DIR = ROOT / "assets" / "brand"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
MARK_MANIFEST = BRAND_DIR / "perfect-mark-manifest.json"
WORDMARK_MANIFEST = BRAND_DIR / "perfect-wordmark-manifest.json"
WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}
ICO_VISIBLE_RATIOS = {
    16: 0.70,
    20: 0.72,
    24: 0.74,
    32: 0.78,
    40: 0.80,
    48: 0.82,
    64: 0.84,
    128: 0.87,
    256: 0.88,
}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def _verify_canonical_text_bytes() -> None:
    attributes = (ROOT / ".gitattributes").read_text(encoding="utf-8")
    for contract in (
        "assets/brand/*.svg text eol=lf",
        "assets/brand/*-manifest.json text eol=lf",
    ):
        _require(
            contract in attributes,
            f"Missing cross-platform brand EOL contract: {contract}",
        )

    generated_text = [MARK_MANIFEST, WORDMARK_MANIFEST, *BRAND_DIR.glob("*.svg")]
    for path in generated_text:
        _require(path.is_file(), f"Missing generated brand text output: {path}")
        _require(
            b"\r" not in path.read_bytes(),
            f"Generated brand text must use canonical LF bytes: {path}",
        )


def _bounds(image: Image.Image, threshold: int = 1) -> tuple[int, int, int, int]:
    alpha = image.convert("RGBA").getchannel("A")
    if threshold > 1:
        alpha = alpha.point(lambda value: 255 if value >= threshold else 0)
    bounds = alpha.getbbox()
    if bounds is None:
        raise AssertionError("Expected visible pixels.")
    return bounds


def _components(image: Image.Image, threshold: int = 128) -> int:
    alpha = image.convert("RGBA").getchannel("A")
    width, height = image.size
    visible = [value >= threshold for value in alpha.get_flattened_data()]
    components = 0
    for index in range(len(visible)):
        if not visible[index]:
            continue
        components += 1
        visible[index] = False
        queue = [index]
        for current in queue:
            x = current % width
            y = current // width
            for offset_y in (-1, 0, 1):
                for offset_x in (-1, 0, 1):
                    if offset_x == 0 and offset_y == 0:
                        continue
                    next_x = x + offset_x
                    next_y = y + offset_y
                    if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                        continue
                    neighbour = (next_y * width) + next_x
                    if visible[neighbour]:
                        visible[neighbour] = False
                        queue.append(neighbour)
    return components


def _verify_manifest_hashes(manifest_path: Path) -> dict[str, object]:
    _require(manifest_path.is_file(), f"Missing manifest: {manifest_path}")
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    for entry in payload["outputs"]:
        path = ROOT / entry["path"]
        _require(path.is_file(), f"Missing generated brand output: {path}")
        _require(
            _sha256(path) == entry["sha256"],
            f"Generated output drifted from {manifest_path.name}: {path}",
        )
    return payload


def _verify_mark_assets(manifest: dict[str, object]) -> None:
    source = ROOT / manifest["selected_source"]["path"]
    _require(
        _sha256(source) == manifest["selected_source"]["sha256"],
        "The user-selected Day Compass source changed.",
    )

    master_path = BRAND_DIR / "perfect-launcher.png"
    with Image.open(master_path) as opened:
        master = opened.convert("RGBA")
    _require(master.size == (512, 512), "Perfect mark master must be 512x512.")
    left, top, right, bottom = _bounds(master)
    _require(
        min(left, top, 512 - right, 512 - bottom) >= 26,
        f"Perfect mark lost its transparent perimeter: {(left, top, right, bottom)}",
    )
    _require(
        max(right - left, bottom - top) >= 440,
        "Perfect mark became optically too small inside its master.",
    )
    _require(_components(master) == 7, "Perfect mark must retain six modules and one core.")
    master_centre = master.getpixel((master.width // 2, master.height // 2))
    _require(
        master_centre[3] >= 240 and max(master_centre[:3]) < 100,
        "Light/platform mark lost its dark owner core.",
    )
    magenta = sum(
        1
        for red, green, blue, alpha in master.get_flattened_data()
        if alpha and red > 170 and blue > 170 and green < 70
    )
    _require(magenta == 0, f"Perfect mark retains {magenta} chroma-key pixels.")

    with Image.open(BRAND_DIR / "perfect-mark-dark.png") as opened:
        dark_mark = opened.convert("RGBA")
    dark_centre = dark_mark.getpixel((dark_mark.width // 2, dark_mark.height // 2))
    _require(
        dark_centre[3] >= 240 and min(dark_centre[:3]) > 235,
        "Dark-surface mark must lift the owner core without changing geometry.",
    )
    for name, expected in (
        ("perfect-mark-high-contrast-light.png", (17, 18, 24)),
        ("perfect-mark-high-contrast-dark.png", (255, 253, 248)),
    ):
        with Image.open(BRAND_DIR / name) as opened:
            contrast_mark = opened.convert("RGBA")
        opaque_colours = {
            pixel[:3]
            for pixel in contrast_mark.get_flattened_data()
            if pixel[3] >= 250
        }
        _require(
            opaque_colours == {expected},
            f"{name} is not the expected single-ink high-contrast silhouette.",
        )

    for density, scale in DENSITIES.items():
        widget_path = (
            ANDROID_RES / f"drawable-{density}" / "perfect_widget_mark_raster.png"
        )
        with Image.open(widget_path) as opened:
            widget = opened.convert("RGBA")
        expected_widget = round(48 * scale)
        _require(
            widget.size == (expected_widget, expected_widget),
            f"{density} widget mark is not a 48dp surface canvas.",
        )
        widget_bounds = _bounds(widget)
        widget_perimeter_dp = min(
            widget_bounds[0],
            widget_bounds[1],
            widget.width - widget_bounds[2],
            widget.height - widget_bounds[3],
        ) / scale
        _require(
            widget_perimeter_dp >= 3.5,
            f"{density} widget mark crowds its canvas: {widget_bounds}",
        )
        _require(
            _components(widget, threshold=192) == 7,
            f"{density} widget mark lost a visually opaque module.",
        )

        splash_path = (
            ANDROID_RES / f"drawable-{density}" / "perfect_splash_mark_raster.png"
        )
        with Image.open(splash_path) as opened:
            splash = opened.convert("RGBA")
        expected_splash = round(288 * scale)
        _require(
            splash.size == (expected_splash, expected_splash),
            f"{density} splash must expose Android's 288dp canvas.",
        )
        splash_bounds = _bounds(splash, threshold=8)
        visible_width_dp = (splash_bounds[2] - splash_bounds[0]) / scale
        visible_height_dp = (splash_bounds[3] - splash_bounds[1]) / scale
        _require(
            max(visible_width_dp, visible_height_dp) <= 170,
            f"{density} splash exceeds the 192dp no-background safe circle.",
        )
        start_dp = splash_bounds[0] / scale
        end_dp = (splash.width - splash_bounds[2]) / scale
        top_dp = splash_bounds[1] / scale
        bottom_dp = (splash.height - splash_bounds[3]) / scale
        _require(abs(start_dp - end_dp) <= 1.25, f"{density} splash is not centred horizontally.")
        _require(abs(top_dp - bottom_dp) <= 1.25, f"{density} splash is not centred vertically.")
        _require(
            _components(splash, threshold=192) == 7,
            f"{density} splash lost a visually opaque module.",
        )

        night_splash_path = (
            ANDROID_RES
            / f"drawable-night-{density}"
            / "perfect_splash_mark_raster.png"
        )
        with Image.open(night_splash_path) as opened:
            night_splash = opened.convert("RGBA")
        _require(
            night_splash.size == (expected_splash, expected_splash),
            f"{density} night splash must expose Android's 288dp canvas.",
        )
        _require(
            _bounds(night_splash, threshold=8) == splash_bounds,
            f"{density} night splash changed Day Compass geometry.",
        )
        _require(
            _components(night_splash, threshold=192) == 7,
            f"{density} night splash lost a visually opaque module.",
        )
        night_centre = night_splash.getpixel(
            (night_splash.width // 2, night_splash.height // 2)
        )
        _require(
            night_centre[3] >= 240 and min(night_centre[:3]) > 235,
            f"{density} night splash owner core lacks dark-background contrast.",
        )


def _verify_wordmark_assets(manifest: dict[str, object]) -> None:
    font_source = ROOT / manifest["font_source"]["path"]
    _require(
        _sha256(font_source) == manifest["font_source"]["sha256"],
        "The authored wordmark font source changed.",
    )
    variants = (
        "perfect-wordmark",
        "perfect-wordmark-dark",
        "perfect-wordmark-high-contrast-light",
        "perfect-wordmark-high-contrast-dark",
    )
    for variant in variants:
        source = (BRAND_DIR / f"{variant}.svg").read_text(encoding="utf-8")
        lowered = source.lower()
        _require("<text" not in lowered, f"{variant}.svg contains live SVG text.")
        _require(source.count("<path ") == 8, f"{variant}.svg must contain eight glyph paths.")
        _require("Perfect!" in source, f"{variant}.svg needs one accessible title.")

    for density, scale in DENSITIES.items():
        path = (
            ANDROID_RES
            / f"drawable-{density}"
            / "perfect_widget_wordmark_raster.png"
        )
        with Image.open(path) as opened:
            wordmark = opened.convert("RGBA")
        expected = (round(96 * scale), round(24 * scale))
        _require(wordmark.size == expected, f"{density} native wordmark has wrong canvas.")
        left, top, right, bottom = _bounds(wordmark)
        _require(left > 0 and top > 0 and right < wordmark.width and bottom < wordmark.height,
                 f"{density} native wordmark touches its canvas edge.")


def _verify_windows_icon() -> None:
    with Image.open(WINDOWS_ICO) as ico:
        actual_sizes = {size[0] for size in ico.ico.sizes()}
        _require(
            actual_sizes == set(ICO_VISIBLE_RATIOS),
            f"Windows ICO frame set drifted: {sorted(actual_sizes)}",
        )
        for size, ratio in ICO_VISIBLE_RATIOS.items():
            frame = ico.ico.getimage((size, size)).convert("RGBA")
            left, top, right, bottom = _bounds(frame)
            minimum_perimeter = max(1, math.floor((size - (size * ratio)) / 2) - 1)
            _require(
                min(left, top, size - right, size - bottom) >= minimum_perimeter,
                f"Windows {size}px frame crowds its edge: {(left, top, right, bottom)}",
            )
            if size >= 48:
                _require(
                    _components(frame, threshold=192) == 7,
                    f"Windows {size}px frame lost a visually opaque module.",
                )


def _verify_android_consumers() -> None:
    day = (ANDROID_RES / "values-v31" / "styles.xml").read_text(encoding="utf-8")
    night = (ANDROID_RES / "values-night-v31" / "styles.xml").read_text(encoding="utf-8")
    for source in (day, night):
        _require("@drawable/perfect_splash_mark_raster" in source, "Android 12+ splash lacks its dedicated asset.")
        _require("@drawable/perfect_widget_mark" not in source, "Splash must never reuse the widget mark.")
    day_color = (ANDROID_RES / "values" / "colors.xml").read_text(encoding="utf-8")
    night_color = (ANDROID_RES / "values-night" / "colors.xml").read_text(encoding="utf-8")
    _require("#FFFFFBF6" in day_color, "Light splash colour drifted.")
    _require("#FF171821" in night_color, "Dark splash colour drifted.")

    for layout_name in (
        "perfect_today_widget_small.xml",
        "perfect_today_widget_tall.xml",
        "perfect_today_widget_wide.xml",
        "perfect_today_widget_large.xml",
    ):
        source = (ANDROID_RES / "layout" / layout_name).read_text(encoding="utf-8")
        _require("@drawable/perfect_widget_mark" in source, f"{layout_name} lacks the mark.")
        _require(
            "@drawable/perfect_widget_wordmark_raster" in source,
            f"{layout_name} lacks the authored native wordmark.",
        )
        _require('android:text="Perfect!"' not in source, f"{layout_name} recreates the brand as ordinary text.")
        _require('android:text="Perfect! Today"' not in source, f"{layout_name} recreates the brand as ordinary text.")


def main() -> None:
    _verify_canonical_text_bytes()
    mark_manifest = _verify_manifest_hashes(MARK_MANIFEST)
    wordmark_manifest = _verify_manifest_hashes(WORDMARK_MANIFEST)
    _verify_mark_assets(mark_manifest)
    _verify_wordmark_assets(wordmark_manifest)
    _verify_windows_icon()
    _verify_android_consumers()
    print("Perfect! brand assets: verified")


if __name__ == "__main__":
    main()
