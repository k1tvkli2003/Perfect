"""Generate deterministic Perfect! Day Compass assets for every host surface.

The approved ImageGen concept is a six-module pastel Day Compass around one
dark owner core. Its chroma source is immutable. This generator removes the
magenta canvas once, then produces surface-specific compositions instead of
reusing one bitmap across incompatible launcher, splash, widget and Windows
safe zones.

Run from the repository root:

    python -m pip install -r tool/requirements.txt
    python tool/generate_day_compass_assets.py
    dart run flutter_launcher_icons
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from statistics import median

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
SELECTION_DIR = (
    ROOT
    / "docs"
    / "codex"
    / "2026-07-27-perfect-orbit-day-private-planner-rebuild"
    / "icon-concepts-v2"
    / "selected"
)
SOURCE = SELECTION_DIR / "day-compass-selected-chroma-1254.png"
SOURCE_SHA256 = "10280e3c4fae3b80bafdc8df35bcf26d75653566c7b9670fc6ca2462801dce77"

BRAND_DIR = ROOT / "assets" / "brand"
MASTER_1024 = BRAND_DIR / "perfect-mark-1024.png"
MASTER = BRAND_DIR / "perfect-launcher.png"
MONOCHROME = BRAND_DIR / "perfect-launcher-monochrome.png"
DARK_MARK = BRAND_DIR / "perfect-mark-dark.png"
HIGH_CONTRAST_LIGHT = BRAND_DIR / "perfect-mark-high-contrast-light.png"
HIGH_CONTRAST_DARK = BRAND_DIR / "perfect-mark-high-contrast-dark.png"
WINDOWS_PNG = BRAND_DIR / "perfect-windows-icon.png"
SPLASH_PREVIEW = BRAND_DIR / "perfect-splash-android-288.png"
SPLASH_DARK_PREVIEW = BRAND_DIR / "perfect-splash-android-dark-288.png"
WIDGET_PREVIEW = BRAND_DIR / "perfect-widget-mark-48.png"
MANIFEST = BRAND_DIR / "perfect-mark-manifest.json"
SELECTION_PREVIEW = SELECTION_DIR / "day-compass-transparent-512.png"

WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

MASTER_SIZE = 512
MASTER_MARGIN = 28
WIDGET_CANVAS_DP = 48
WIDGET_VISIBLE_DP = 40
SPLASH_CANVAS_DP = 288
SPLASH_VISIBLE_DP = 168
ANDROID_DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}
WINDOWS_VISIBLE_RATIOS = {
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


def _smoothstep(edge0: float, edge1: float, value: float) -> float:
    normalized = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return normalized * normalized * (3.0 - (2.0 * normalized))


def _sample_chroma(image: Image.Image) -> tuple[int, int, int]:
    """Use border medians instead of assuming ImageGen emitted exact #FF00FF."""

    rgb = image.convert("RGB")
    width, height = rgb.size
    band = max(4, min(width, height) // 100)
    samples: list[tuple[int, int, int]] = []
    for y in range(height):
        for x in range(width):
            if x < band or x >= width - band or y < band or y >= height - band:
                samples.append(rgb.getpixel((x, y)))
    return tuple(int(median(channel)) for channel in zip(*samples, strict=True))


def _remove_magenta(image: Image.Image) -> Image.Image:
    """Recover alpha while borrowing clean colour for chroma-composited edges."""

    rgb = image.convert("RGB")
    chroma = _sample_chroma(rgb)
    width, height = rgb.size
    source = list(rgb.get_flattened_data())

    def classification(colour: tuple[int, int, int]) -> str:
        red, green, blue = colour
        magenta_brightness = min(red, blue)
        magenta_dominance = magenta_brightness - green
        if magenta_brightness > 175 and magenta_dominance > 150:
            return "background"
        if magenta_brightness > 170 and magenta_dominance > 25 and green < 155:
            return "edge"
        return "interior"

    classes = [classification(colour) for colour in source]

    def nearest_interior(x: int, y: int) -> tuple[int, int, int] | None:
        for radius in range(1, 9):
            candidates: list[tuple[int, int, int]] = []
            x0 = max(0, x - radius)
            x1 = min(width - 1, x + radius)
            y0 = max(0, y - radius)
            y1 = min(height - 1, y + radius)
            for sample_y in range(y0, y1 + 1):
                for sample_x in range(x0, x1 + 1):
                    if abs(sample_x - x) != radius and abs(sample_y - y) != radius:
                        continue
                    index = (sample_y * width) + sample_x
                    if classes[index] == "interior":
                        candidates.append(source[index])
            if candidates:
                return tuple(
                    round(sum(colour[channel] for colour in candidates) / len(candidates))
                    for channel in range(3)
                )
        return None

    output_pixels: list[tuple[int, int, int, int]] = []
    for index, pixel in enumerate(source):
        kind = classes[index]
        if kind == "background":
            output_pixels.append((0, 0, 0, 0))
            continue
        if kind == "interior":
            output_pixels.append((*pixel, 255))
            continue

        x = index % width
        y = index // width
        foreground = nearest_interior(x, y)
        if foreground is None:
            dominance = min(pixel[0], pixel[2]) - pixel[1]
            alpha = 1.0 - _smoothstep(60.0, 150.0, float(dominance))
            foreground = pixel
        else:
            delta = tuple(foreground[channel] - chroma[channel] for channel in range(3))
            observed = tuple(pixel[channel] - chroma[channel] for channel in range(3))
            denominator = sum(channel * channel for channel in delta)
            alpha = (
                sum(observed[channel] * delta[channel] for channel in range(3))
                / denominator
                if denominator
                else 1.0
            )
        alpha = max(0.0, min(1.0, alpha))
        if alpha <= 0.015:
            output_pixels.append((0, 0, 0, 0))
        else:
            output_pixels.append((*foreground, round(alpha * 255.0)))

    output = Image.new("RGBA", rgb.size)
    output.putdata(output_pixels)
    return output


def _resize_rgba_premultiplied(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    """Resize RGBA data without pulling transparent RGB into the edge."""

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


def _decontaminate_resized_edge(image: Image.Image) -> Image.Image:
    """Borrow colour from opaque neighbours for antialiased boundary pixels."""

    rgba = image.convert("RGBA")
    width, height = rgba.size
    source = list(rgba.get_flattened_data())
    output = list(source)
    for index, pixel in enumerate(source):
        if pixel[3] == 0 or pixel[3] >= 250:
            continue
        x = index % width
        y = index // width
        replacement: tuple[int, int, int, int] | None = None
        for radius in range(1, 5):
            candidates: list[tuple[int, int, int, int]] = []
            for sample_y in range(max(0, y - radius), min(height, y + radius + 1)):
                for sample_x in range(max(0, x - radius), min(width, x + radius + 1)):
                    if abs(sample_x - x) != radius and abs(sample_y - y) != radius:
                        continue
                    candidate = source[(sample_y * width) + sample_x]
                    if candidate[3] >= 250:
                        candidates.append(candidate)
            if candidates:
                replacement = max(candidates, key=lambda colour: colour[3])
                break
        if replacement is not None:
            output[index] = (*replacement[:3], pixel[3])
    rgba.putdata(output)
    return rgba


def _compose(mark: Image.Image, canvas_size: int, visible_size: int) -> Image.Image:
    bounds = mark.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("The chroma-keyed source contains no visible mark.")
    cropped = mark.crop(bounds)
    scale = min(visible_size / cropped.width, visible_size / cropped.height)
    target = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = _resize_rgba_premultiplied(cropped, target)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    origin = ((canvas_size - target[0]) // 2, (canvas_size - target[1]) // 2)
    canvas.alpha_composite(resized, origin)
    return _decontaminate_resized_edge(canvas)


def _component_count(image: Image.Image, threshold: int = 128) -> int:
    alpha = image.getchannel("A")
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


def _silhouette(mark: Image.Image, colour: tuple[int, int, int]) -> Image.Image:
    result = Image.new("RGBA", mark.size, (*colour, 0))
    result.putalpha(mark.getchannel("A"))
    return result


def _dark_surface_mark(mark: Image.Image) -> Image.Image:
    """Keep pastel modules and lift only the central dark owner core."""

    rgba = mark.convert("RGBA")
    width, height = rgba.size
    centre_x = (width - 1) / 2
    centre_y = (height - 1) / 2
    core_radius = min(width, height) * 0.13
    output: list[tuple[int, int, int, int]] = []
    for index, pixel in enumerate(rgba.get_flattened_data()):
        x = index % width
        y = index // width
        distance_squared = ((x - centre_x) ** 2) + ((y - centre_y) ** 2)
        luminance = (0.2126 * pixel[0]) + (0.7152 * pixel[1]) + (0.0722 * pixel[2])
        if pixel[3] and distance_squared <= core_radius**2 and luminance < 105:
            output.append((255, 249, 241, pixel[3]))
        else:
            output.append(pixel)
    result = Image.new("RGBA", rgba.size)
    result.putdata(output)
    return result


def _validate_master(master: Image.Image) -> None:
    if master.size != (MASTER_SIZE, MASTER_SIZE) or master.mode != "RGBA":
        raise ValueError("Master must be a 512x512 RGBA image.")
    bounds = master.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Master must contain visible pixels.")
    left, top, right, bottom = bounds
    if min(left, top, MASTER_SIZE - right, MASTER_SIZE - bottom) < MASTER_MARGIN - 2:
        raise ValueError(f"Master does not retain its optical perimeter: {bounds}.")
    if max(right - left, bottom - top) < 440:
        raise ValueError(f"Selected mark is too small inside its master: {bounds}.")
    if _component_count(master) != 7:
        raise ValueError("Day Compass must retain six modules plus its owner core.")
    contaminated = 0
    for red, green, blue, alpha in master.get_flattened_data():
        if alpha and red > 170 and blue > 170 and green < 70:
            contaminated += 1
    if contaminated:
        raise ValueError(f"Master retains {contaminated} magenta-key pixels.")


def _write_android_surface_marks(
    master: Image.Image,
    dark_mark: Image.Image,
) -> list[Path]:
    outputs: list[Path] = []
    for density, scale in ANDROID_DENSITIES.items():
        widget = _compose(
            master,
            round(WIDGET_CANVAS_DP * scale),
            round(WIDGET_VISIBLE_DP * scale),
        )
        widget_path = (
            ANDROID_RES / f"drawable-{density}" / "perfect_widget_mark_raster.png"
        )
        widget_path.parent.mkdir(parents=True, exist_ok=True)
        widget.save(widget_path, optimize=True)
        outputs.append(widget_path)

        splash = _compose(
            master,
            round(SPLASH_CANVAS_DP * scale),
            round(SPLASH_VISIBLE_DP * scale),
        )
        splash_path = (
            ANDROID_RES / f"drawable-{density}" / "perfect_splash_mark_raster.png"
        )
        splash.save(splash_path, optimize=True)
        outputs.append(splash_path)

        dark_splash = _compose(
            dark_mark,
            round(SPLASH_CANVAS_DP * scale),
            round(SPLASH_VISIBLE_DP * scale),
        )
        dark_splash_path = (
            ANDROID_RES
            / f"drawable-night-{density}"
            / "perfect_splash_mark_raster.png"
        )
        dark_splash_path.parent.mkdir(parents=True, exist_ok=True)
        dark_splash.save(dark_splash_path, optimize=True)
        outputs.append(dark_splash_path)
    return outputs


def _write_windows_icon(master: Image.Image) -> list[Image.Image]:
    frames = [
        _compose(master, size, max(1, round(size * WINDOWS_VISIBLE_RATIOS[size])))
        for size in WINDOWS_VISIBLE_RATIOS
    ]
    WINDOWS_ICO.parent.mkdir(parents=True, exist_ok=True)
    frames[-1].save(
        WINDOWS_ICO,
        format="ICO",
        append_images=frames[:-1],
        sizes=[(size, size) for size in WINDOWS_VISIBLE_RATIOS],
    )
    frames[-1].save(WINDOWS_PNG, optimize=True)
    return frames


def _entry(path: Path, image: Image.Image, consumer: str) -> dict[str, object]:
    bounds = image.getchannel("A").getbbox()
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": _sha256(path),
        "pixels": list(image.size),
        "alpha_bounds": list(bounds) if bounds else None,
        "components_alpha_128": _component_count(image),
        "consumer": consumer,
    }


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    actual_source_hash = _sha256(SOURCE)
    if actual_source_hash != SOURCE_SHA256:
        raise ValueError(
            "The selected Day Compass source changed: "
            f"expected {SOURCE_SHA256}, got {actual_source_hash}."
        )

    source = Image.open(SOURCE)
    transparent = _remove_magenta(source)
    master = _compose(transparent, MASTER_SIZE, MASTER_SIZE - (MASTER_MARGIN * 2))
    _validate_master(master)
    master_1024 = _compose(transparent, 1024, 1024 - (MASTER_MARGIN * 4))
    monochrome = _silhouette(master, (255, 255, 255))
    dark_mark = _dark_surface_mark(master)
    high_contrast_light = _silhouette(master, (17, 18, 24))
    high_contrast_dark = _silhouette(master, (255, 253, 248))
    widget_preview = _compose(master, WIDGET_CANVAS_DP, WIDGET_VISIBLE_DP)
    splash_preview = _compose(master, SPLASH_CANVAS_DP, SPLASH_VISIBLE_DP)
    splash_dark_preview = _compose(
        dark_mark,
        SPLASH_CANVAS_DP,
        SPLASH_VISIBLE_DP,
    )

    BRAND_DIR.mkdir(parents=True, exist_ok=True)
    SELECTION_DIR.mkdir(parents=True, exist_ok=True)
    for image, destination in (
        (master_1024, MASTER_1024),
        (master, MASTER),
        (monochrome, MONOCHROME),
        (dark_mark, DARK_MARK),
        (high_contrast_light, HIGH_CONTRAST_LIGHT),
        (high_contrast_dark, HIGH_CONTRAST_DARK),
        (widget_preview, WIDGET_PREVIEW),
        (splash_preview, SPLASH_PREVIEW),
        (splash_dark_preview, SPLASH_DARK_PREVIEW),
        (master, SELECTION_PREVIEW),
    ):
        image.save(destination, optimize=True)

    windows_frames = _write_windows_icon(master)
    android_outputs = _write_android_surface_marks(master, dark_mark)

    entries = [
        _entry(MASTER_1024, master_1024, "archival high-resolution mark master"),
        _entry(MASTER, master, "Flutter and legacy Android launcher mark"),
        _entry(MONOCHROME, monochrome, "Android themed adaptive icon"),
        _entry(DARK_MARK, dark_mark, "Flutter dark surfaces"),
        _entry(HIGH_CONTRAST_LIGHT, high_contrast_light, "Flutter high-contrast light"),
        _entry(HIGH_CONTRAST_DARK, high_contrast_dark, "Flutter high-contrast dark"),
        _entry(WIDGET_PREVIEW, widget_preview, "Android native widget reference canvas"),
        _entry(SPLASH_PREVIEW, splash_preview, "Android system splash reference canvas"),
        _entry(
            SPLASH_DARK_PREVIEW,
            splash_dark_preview,
            "Android dark system splash reference canvas",
        ),
        _entry(WINDOWS_PNG, windows_frames[-1], "Windows packaging and MSIX logo source"),
    ]
    for path in android_outputs:
        with Image.open(path) as image:
            consumer = (
                "Android dark system splash"
                if "drawable-night" in path.as_posix()
                else "Android system splash"
                if "splash" in path.name
                else "Android native widget"
            )
            entries.append(_entry(path, image.convert("RGBA"), consumer))

    manifest = {
        "schema_version": 1,
        "identity": "Perfect! Day Compass",
        "selected_source": {
            "path": SOURCE.relative_to(ROOT).as_posix(),
            "sha256": actual_source_hash,
            "chroma_rgb": list(_sample_chroma(source)),
        },
        "geometry": {
            "modules": 6,
            "owner_core": 1,
            "master_canvas_px": MASTER_SIZE,
            "master_min_perimeter_px": MASTER_MARGIN - 2,
            "android_widget": {
                "canvas_dp": WIDGET_CANVAS_DP,
                "visible_dp": WIDGET_VISIBLE_DP,
            },
            "android_splash": {
                "canvas_dp": SPLASH_CANVAS_DP,
                "visible_dp": SPLASH_VISIBLE_DP,
                "system_no_background_safe_circle_dp": 192,
            },
            "windows_visible_ratios": {
                str(size): ratio for size, ratio in WINDOWS_VISIBLE_RATIOS.items()
            },
        },
        "platform_decisions": {
            "transparent_where_supported": True,
            "android_adaptive_quiet_plate": "#FFF3E8",
            "android_adaptive_plate_reason": (
                "Pixel Launcher normalizes a fully transparent adaptive background "
                "to an opaque black platform tile."
            ),
            "surface_specific_derivatives": True,
        },
        "outputs": sorted(entries, key=lambda item: str(item["path"])),
        "windows_ico": {
            "path": WINDOWS_ICO.relative_to(ROOT).as_posix(),
            "sha256": _sha256(WINDOWS_ICO),
            "frames": [
                {
                    "pixels": size,
                    "alpha_bounds": list(frame.getchannel("A").getbbox() or ()),
                    "components_alpha_128": _component_count(frame),
                }
                for size, frame in zip(WINDOWS_VISIBLE_RATIOS, windows_frames, strict=True)
            ],
        },
    }
    MANIFEST.write_bytes(
        (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8"),
    )

    print(f"source_sha256={actual_source_hash}")
    print(f"master={MASTER} alpha_bounds={master.getchannel('A').getbbox()}")
    print(f"manifest={MANIFEST}")
    print(f"windows_ico={WINDOWS_ICO}")
    print(f"android_surface_assets={len(android_outputs)}")


if __name__ == "__main__":
    main()
