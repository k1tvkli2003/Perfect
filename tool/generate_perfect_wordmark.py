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

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "assets" / "fonts" / "PlusJakartaSans-Variable.ttf"
OUTPUT_DIR = ROOT / "assets" / "brand"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
MANIFEST = OUTPUT_DIR / "perfect-wordmark-manifest.json"

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


def _font(size: int, weight: int = WEIGHT) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT_PATH), size=size)
    font.set_variation_by_axes([weight])
    return font


def _render_wordmark(*, ink: str, accent: str) -> Image.Image:
    size = 420
    font = _font(size)
    canvas = Image.new("RGBA", (2400, 720), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    bbox = font.getbbox(WORDMARK)
    baseline_y = 30 - bbox[1]
    draw.text((30, baseline_y), "Perfect", font=font, fill=ink)
    accent_x = 30 + draw.textlength("Perfect", font=font) - 5
    draw.text((accent_x, baseline_y), "!", font=font, fill=accent)

    alpha_bounds = canvas.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise RuntimeError("Wordmark rendering produced no visible pixels.")
    left, top, right, bottom = alpha_bounds
    padding = 24
    return canvas.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(canvas.width, right + padding),
            min(canvas.height, bottom + padding),
        )
    )


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


def _path_svg(*, ink: str, accent: str) -> str:
    variable_font = TTFont(FONT_PATH)
    font = instantiateVariableFont(variable_font, {"wght": WEIGHT}, inplace=False)
    glyph_set = font.getGlyphSet()
    cmap = font.getBestCmap()
    units_per_em = font["head"].unitsPerEm
    metric_font_size = 1000
    metric_font = _font(metric_font_size)
    metric_draw = ImageDraw.Draw(Image.new("L", (1, 1)))

    records: list[dict[str, object]] = []
    overall_left = float("inf")
    overall_bottom = float("inf")
    overall_right = float("-inf")
    overall_top = float("-inf")
    for index, character in enumerate(WORDMARK):
        glyph_name = cmap.get(ord(character))
        if glyph_name is None:
            raise ValueError(f"Missing glyph for {character!r} in {FONT_PATH.name}.")
        glyph = glyph_set[glyph_name]
        bounds_pen = BoundsPen(glyph_set)
        glyph.draw(bounds_pen)
        if bounds_pen.bounds is None:
            raise ValueError(f"Glyph {glyph_name} has no outline.")
        path_pen = SVGPathPen(glyph_set)
        glyph.draw(path_pen)
        x_pixels = metric_draw.textlength(WORDMARK[:index], font=metric_font)
        x_units = float(x_pixels) * units_per_em / metric_font_size
        left, bottom, right, top = bounds_pen.bounds
        overall_left = min(overall_left, x_units + left)
        overall_bottom = min(overall_bottom, bottom)
        overall_right = max(overall_right, x_units + right)
        overall_top = max(overall_top, top)
        records.append(
            {
                "path": path_pen.getCommands(),
                "x": x_units,
                "fill": accent if character == "!" else ink,
            }
        )

    padding = units_per_em * 0.06
    width = (overall_right - overall_left) + (padding * 2)
    height = (overall_top - overall_bottom) + (padding * 2)
    origin_x = padding - overall_left
    baseline_y = padding + overall_top
    paths = "\n".join(
        (
            f'  <path fill="{record["fill"]}" d="{record["path"]}" '
            f'transform="translate({origin_x + float(record["x"]):.3f} '
            f'{baseline_y:.3f}) scale(1 -1)"/>'
        )
        for record in records
    )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.3f} {height:.3f}" '
        'role="img" aria-labelledby="perfect-wordmark-title">\n'
        '  <title id="perfect-wordmark-title">Perfect!</title>\n'
        f"{paths}\n"
        "</svg>\n"
    )


def _write_variant(name: str, ink: str, accent: str) -> tuple[Path, Path, Image.Image]:
    png_path = OUTPUT_DIR / f"{name}.png"
    svg_path = OUTPUT_DIR / f"{name}.svg"
    raster = _render_wordmark(ink=ink, accent=accent)
    raster.save(png_path, optimize=True)
    svg_path.write_text(_path_svg(ink=ink, accent=accent), encoding="utf-8")
    return png_path, svg_path, raster


def main() -> None:
    if not FONT_PATH.is_file():
        raise FileNotFoundError(FONT_PATH)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    variants = [
        ("perfect-wordmark", INK_LIGHT, ACCENT_LIGHT),
        ("perfect-wordmark-dark", INK_DARK, ACCENT_DARK),
        ("perfect-wordmark-high-contrast-light", HC_LIGHT, HC_LIGHT),
        ("perfect-wordmark-high-contrast-dark", HC_DARK, HC_DARK),
    ]
    outputs: list[dict[str, object]] = []
    light_raster: Image.Image | None = None
    for name, ink, accent in variants:
        png_path, svg_path, raster = _write_variant(name, ink, accent)
        if name == "perfect-wordmark":
            light_raster = raster
        outputs.extend(
            [
                {
                    "path": png_path.relative_to(ROOT).as_posix(),
                    "sha256": _sha256(png_path),
                    "kind": "raster-fallback",
                    "pixels": list(raster.size),
                    "alpha_bounds": list(raster.getchannel("A").getbbox() or ()),
                },
                {
                    "path": svg_path.relative_to(ROOT).as_posix(),
                    "sha256": _sha256(svg_path),
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
                "sha256": _sha256(destination),
                "kind": "android-widget-raster",
                "pixels": list(native.size),
                "alpha_bounds": list(native.getchannel("A").getbbox() or ()),
            }
        )

    manifest = {
        "schema_version": 1,
        "identity": "Perfect! authored wordmark",
        "font_source": {
            "path": FONT_PATH.relative_to(ROOT).as_posix(),
            "sha256": _sha256(FONT_PATH),
            "weight": WEIGHT,
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
    MANIFEST.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"font_sha256={_sha256(FONT_PATH)}")
    print(f"manifest={MANIFEST}")
    print(f"outputs={len(outputs)}")


if __name__ == "__main__":
    main()
