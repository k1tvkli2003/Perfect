"""Generate the authored Perfect! wordmark as path SVG and raster fallbacks.

The selected identity uses a fixed Plus Jakarta Sans variable-font instance at
weight 660 with a lilac exclamation mark. SVG outputs contain final glyph
outlines, never live text, so the identity does not depend on a host font or an
SVG text renderer. PNGs remain deterministic fallbacks and native-widget art.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageColor


ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "assets" / "fonts" / "PlusJakartaSans-Variable.ttf"
OUTPUT_DIR = ROOT / "assets" / "brand"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
MANIFEST = OUTPUT_DIR / "perfect-wordmark-manifest.json"
PATH_MASTER = OUTPUT_DIR / "perfect-wordmark.svg"
PATH_MASTER_SHA256 = "45a952196efaddb3749ccab6760420d17dc68f9f36f4922919445a8157086a2c"

FOUNDATION_DIR = (
    ROOT
    / "docs"
    / "codex"
    / "2026-07-27-perfect-orbit-day-private-planner-rebuild"
    / "design"
    / "01-foundations"
    / "stage03-selected"
)
LIGHT_RASTER_SOURCE = FOUNDATION_DIR / "perfect-wordmark.png"
DARK_RASTER_SOURCE = FOUNDATION_DIR / "perfect-wordmark-dark.png"
LIGHT_RASTER_SOURCE_SHA256 = "89a010f6d60f414c144045f2aeddd81a023b4e9cd9bf67c7262a77813a06e87b"
DARK_RASTER_SOURCE_SHA256 = "3a5eefc491e2e1bb9ef51ecd279d3c8d1016f00a11abe3bf3ed0b72af3e3a0cf"

WORDMARK = "Perfect!"
WEIGHT = 660
INK_LIGHT = "#1D2030"
ACCENT_LIGHT = "#A99ADE"
INK_DARK = "#FFF9F1"
ACCENT_DARK = "#B9AAEB"
HC_LIGHT = "#111218"
HC_DARK = "#FFFDF8"
ANDROID_DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}
WIDGET_WORDMARK_CANVAS_DP = (96, 24)
WIDGET_WORDMARK_VISIBLE_DP = (88, 20)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _rgba_sha256(image: Image.Image) -> str:
    rgba = image.convert("RGBA")
    digest = hashlib.sha256()
    digest.update(b"perfect-rgba-v1\0")
    digest.update(rgba.width.to_bytes(4, "big"))
    digest.update(rgba.height.to_bytes(4, "big"))
    digest.update(rgba.tobytes())
    return digest.hexdigest()


def _load_rgba(path: Path) -> Image.Image:
    with Image.open(path) as opened:
        return opened.convert("RGBA")


def _recolour_wordmark(source: Image.Image, *, ink: str, accent: str) -> Image.Image:
    rgba = source.convert("RGBA")
    alpha = rgba.getchannel("A")
    visible_columns = [
        any(alpha.getpixel((x, y)) > 0 for y in range(alpha.height))
        for x in range(alpha.width)
    ]
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for x, visible in enumerate([*visible_columns, False]):
        if visible and start is None:
            start = x
        elif not visible and start is not None:
            runs.append((start, x))
            start = None
    if len(runs) < len(WORDMARK):
        raise ValueError("Protected wordmark raster lost a glyph component.")
    accent_start = runs[-1][0]
    ink_rgb = ImageColor.getrgb(ink)
    accent_rgb = ImageColor.getrgb(accent)
    output = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    pixels = output.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            opacity = alpha.getpixel((x, y))
            if opacity:
                colour = accent_rgb if x >= accent_start else ink_rgb
                pixels[x, y] = (*colour, opacity)
    return output


def _resize_rgba_premultiplied(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    red, green, blue, alpha = image.convert("RGBA").split()
    premultiplied = [
        ImageChops.multiply(channel, alpha).resize(target, Image.Resampling.LANCZOS)
        for channel in (red, green, blue)
    ]
    resized_alpha = alpha.resize(target, Image.Resampling.LANCZOS)
    raw_channels = [list(channel.get_flattened_data()) for channel in premultiplied]
    alpha_values = list(resized_alpha.get_flattened_data())
    restored: list[list[int]] = [[], [], []]
    for index, alpha_value in enumerate(alpha_values):
        if alpha_value == 0:
            for channel in restored:
                channel.append(0)
            continue
        for channel_index in range(3):
            value = round((raw_channels[channel_index][index] * 255) / alpha_value)
            restored[channel_index].append(max(0, min(255, value)))
    channels = [Image.new("L", target), Image.new("L", target), Image.new("L", target)]
    for channel, values in zip(channels, restored, strict=True):
        channel.putdata(values)
    return Image.merge("RGBA", (*channels, resized_alpha))


def _fit_on_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    visible_size: tuple[int, int],
) -> Image.Image:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Wordmark has no visible pixels.")
    cropped = image.crop(bounds)
    scale = min(visible_size[0] / cropped.width, visible_size[1] / cropped.height)
    target = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    resized = _resize_rgba_premultiplied(cropped, target)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((canvas_size[0] - target[0]) // 2, (canvas_size[1] - target[1]) // 2),
    )
    return canvas


def _svg_variant(*, ink: str, accent: str) -> str:
    source = PATH_MASTER.read_text(encoding="utf-8")
    if source.count("<path ") != len(WORDMARK):
        raise ValueError("Authored wordmark path master must retain eight glyph paths.")
    if INK_LIGHT not in source or ACCENT_LIGHT not in source:
        raise ValueError("Authored wordmark path master lost its selected colour roles.")
    return source.replace(INK_LIGHT, ink).replace(ACCENT_LIGHT, accent)


def _write_variant(
    name: str,
    ink: str,
    accent: str,
    *,
    raster_source: Path | None = None,
) -> tuple[Path, Path, Image.Image]:
    png_path = OUTPUT_DIR / f"{name}.png"
    svg_path = OUTPUT_DIR / f"{name}.svg"
    if raster_source is not None:
        png_path.write_bytes(raster_source.read_bytes())
        raster = _load_rgba(raster_source)
    else:
        raster = _recolour_wordmark(
            _load_rgba(LIGHT_RASTER_SOURCE),
            ink=ink,
            accent=accent,
        )
        raster.save(png_path, optimize=True)

    svg = _svg_variant(ink=ink, accent=accent)
    if svg_path == PATH_MASTER:
        if svg.encode("utf-8") != PATH_MASTER.read_bytes():
            raise ValueError("Light wordmark path master is not canonical.")
    else:
        svg_path.write_bytes(svg.encode("utf-8"))
    return png_path, svg_path, raster


def main() -> None:
    if not FONT_PATH.is_file():
        raise FileNotFoundError(FONT_PATH)
    for path, expected_hash in (
        (PATH_MASTER, PATH_MASTER_SHA256),
        (LIGHT_RASTER_SOURCE, LIGHT_RASTER_SOURCE_SHA256),
        (DARK_RASTER_SOURCE, DARK_RASTER_SOURCE_SHA256),
    ):
        if not path.is_file():
            raise FileNotFoundError(path)
        actual_hash = _sha256(path)
        if actual_hash != expected_hash:
            raise ValueError(
                f"Protected wordmark source changed: {path}; "
                f"expected {expected_hash}, got {actual_hash}."
            )
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    variants = [
        ("perfect-wordmark", INK_LIGHT, ACCENT_LIGHT, LIGHT_RASTER_SOURCE),
        ("perfect-wordmark-dark", INK_DARK, ACCENT_DARK, DARK_RASTER_SOURCE),
        ("perfect-wordmark-high-contrast-light", HC_LIGHT, HC_LIGHT, None),
        ("perfect-wordmark-high-contrast-dark", HC_DARK, HC_DARK, None),
    ]
    outputs: list[dict[str, object]] = []
    light_raster: Image.Image | None = None
    for name, ink, accent, raster_source in variants:
        png_path, svg_path, raster = _write_variant(
            name,
            ink,
            accent,
            raster_source=raster_source,
        )
        if name == "perfect-wordmark":
            light_raster = raster
        outputs.extend(
            [
                {
                    "path": png_path.relative_to(ROOT).as_posix(),
                    "sha256": _rgba_sha256(raster),
                    "hash_basis": "rgba-v1",
                    "kind": "raster-fallback",
                    "pixels": list(raster.size),
                    "alpha_bounds": list(raster.getchannel("A").getbbox() or ()),
                },
                {
                    "path": svg_path.relative_to(ROOT).as_posix(),
                    "sha256": _sha256(svg_path),
                    "hash_basis": "bytes-v1",
                    "kind": "path-svg-master",
                    "glyph_paths": len(WORDMARK),
                },
            ]
        )

    if light_raster is None:
        raise RuntimeError("Light wordmark variant was not generated.")
    for density, scale in ANDROID_DENSITIES.items():
        canvas = (
            round(WIDGET_WORDMARK_CANVAS_DP[0] * scale),
            round(WIDGET_WORDMARK_CANVAS_DP[1] * scale),
        )
        visible = (
            round(WIDGET_WORDMARK_VISIBLE_DP[0] * scale),
            round(WIDGET_WORDMARK_VISIBLE_DP[1] * scale),
        )
        native = _fit_on_canvas(light_raster, canvas, visible)
        destination = (
            ANDROID_RES
            / f"drawable-{density}"
            / "perfect_widget_wordmark_raster.png"
        )
        destination.parent.mkdir(parents=True, exist_ok=True)
        native.save(destination, optimize=True)
        outputs.append(
            {
                "path": destination.relative_to(ROOT).as_posix(),
                "sha256": _rgba_sha256(native),
                "hash_basis": "rgba-v1",
                "kind": "android-widget-raster",
                "pixels": list(native.size),
                "alpha_bounds": list(native.getchannel("A").getbbox() or ()),
            }
        )

    manifest = {
        "schema_version": 2,
        "identity": "Perfect! authored wordmark",
        "font_source": {
            "path": FONT_PATH.relative_to(ROOT).as_posix(),
            "sha256": _sha256(FONT_PATH),
            "weight": WEIGHT,
        },
        "authored_sources": {
            "path_master": {
                "path": PATH_MASTER.relative_to(ROOT).as_posix(),
                "sha256": PATH_MASTER_SHA256,
            },
            "light_raster": {
                "path": LIGHT_RASTER_SOURCE.relative_to(ROOT).as_posix(),
                "sha256": LIGHT_RASTER_SOURCE_SHA256,
            },
            "dark_raster": {
                "path": DARK_RASTER_SOURCE.relative_to(ROOT).as_posix(),
                "sha256": DARK_RASTER_SOURCE_SHA256,
            },
        },
        "contract": {
            "text": WORDMARK,
            "runtime_text_nodes": False,
            "light": {"ink": INK_LIGHT, "accent": ACCENT_LIGHT},
            "dark": {"ink": INK_DARK, "accent": ACCENT_DARK},
            "high_contrast_light": HC_LIGHT,
            "high_contrast_dark": HC_DARK,
            "android_widget_canvas_dp": list(WIDGET_WORDMARK_CANVAS_DP),
            "android_widget_visible_dp": list(WIDGET_WORDMARK_VISIBLE_DP),
        },
        "outputs": sorted(outputs, key=lambda item: str(item["path"])),
    }
    MANIFEST.write_bytes(
        (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8"),
    )
    print(f"font_sha256={_sha256(FONT_PATH)}")
    print(f"manifest={MANIFEST}")
    print(f"outputs={len(outputs)}")


if __name__ == "__main__":
    main()
