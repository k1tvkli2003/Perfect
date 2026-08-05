"""Generate production Perfect! brand assets from the selected Day Compass art.

The selected ImageGen source deliberately uses a flat magenta chroma canvas.
This script turns that comparison asset into one transparent 512px source of
truth, then derives the Windows multi-resolution ICO and the density-aware
Android widget/splash mark. Android launcher resources are generated from the
same master by `flutter_launcher_icons`.

Run from the repository root:

    python -m pip install -r tool/requirements.txt
    python tool/generate_day_compass_assets.py
"""

from __future__ import annotations

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
MASTER = ROOT / "assets" / "brand" / "perfect-launcher.png"
MONOCHROME = ROOT / "assets" / "brand" / "perfect-launcher-monochrome.png"
PREVIEW = SELECTION_DIR / "day-compass-transparent-512.png"
WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

MASTER_SIZE = 512
MASTER_MARGIN = 8
WIDGET_MARK_DP = 36
ANDROID_DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}


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
    """Create a clean alpha matte without retaining a magenta fringe.

    ImageGen's edge pixels are already a composite of the real mark and the
    chroma canvas. For those pixels, a nearby interior colour supplies the
    foreground term and a least-squares inverse composite recovers alpha.
    """

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
        if (
            magenta_brightness > 170
            and magenta_dominance > 25
            and green < 155
        ):
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
                    if (
                        abs(sample_x - x) != radius
                        and abs(sample_y - y) != radius
                    ):
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
            # A conservative fallback for an isolated antialias pixel.
            dominance = min(pixel[0], pixel[2]) - pixel[1]
            alpha = 1.0 - _smoothstep(60.0, 150.0, float(dominance))
            foreground = pixel
        else:
            delta = tuple(
                foreground[channel] - chroma[channel] for channel in range(3)
            )
            observed = tuple(
                pixel[channel] - chroma[channel] for channel in range(3)
            )
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


def _resize_rgba_premultiplied(
    image: Image.Image,
    target: tuple[int, int],
) -> Image.Image:
    """Resize RGBA data without pulling transparent RGB into the edge."""

    red, green, blue, alpha = image.convert("RGBA").split()
    premultiplied = [
        ImageChops.multiply(channel, alpha).resize(target, Image.Resampling.LANCZOS)
        for channel in (red, green, blue)
    ]
    resized_alpha = alpha.resize(target, Image.Resampling.LANCZOS)
    raw_channels = [
        list(channel.get_flattened_data()) for channel in premultiplied
    ]
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
    channels = [
        Image.new("L", target),
        Image.new("L", target),
        Image.new("L", target),
    ]
    for channel, values in zip(channels, restored, strict=True):
        channel.putdata(values)
    return Image.merge("RGBA", (*channels, resized_alpha))


def _fit_master(mark: Image.Image) -> Image.Image:
    alpha = mark.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("The chroma-keyed source contains no visible mark.")

    cropped = mark.crop(bounds)
    available = MASTER_SIZE - (MASTER_MARGIN * 2)
    scale = min(available / cropped.width, available / cropped.height)
    target = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = _resize_rgba_premultiplied(cropped, target)

    canvas = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    origin = (
        (MASTER_SIZE - target[0]) // 2,
        (MASTER_SIZE - target[1]) // 2,
    )
    canvas.alpha_composite(resized, origin)
    return _decontaminate_resized_edge(canvas)


def _decontaminate_resized_edge(image: Image.Image) -> Image.Image:
    """Borrow colour from the opaque interior for antialiased boundary pixels."""

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
                    if (
                        abs(sample_x - x) != radius
                        and abs(sample_y - y) != radius
                    ):
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


def _validate_master(master: Image.Image) -> None:
    if master.size != (MASTER_SIZE, MASTER_SIZE) or master.mode != "RGBA":
        raise ValueError("Master must be a 512x512 RGBA image.")
    alpha = master.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Master must contain visible pixels.")
    corners = (
        alpha.getpixel((0, 0)),
        alpha.getpixel((MASTER_SIZE - 1, 0)),
        alpha.getpixel((0, MASTER_SIZE - 1)),
        alpha.getpixel((MASTER_SIZE - 1, MASTER_SIZE - 1)),
    )
    if any(corners):
        raise ValueError(f"Master corners must be transparent; got {corners}.")
    if max(bounds[2] - bounds[0], bounds[3] - bounds[1]) < 490:
        raise ValueError(f"Selected mark is too small inside its master: {bounds}.")


def _write_android_widget_marks(master: Image.Image) -> list[Path]:
    """Export one exact Day Compass raster at a stable 36dp intrinsic size.

    The widget header displays this drawable inside a 24dp ImageView while the
    quick-add and splash surfaces use the full 36dp intrinsic size. Supplying a
    raster per Android density keeps those hosts from treating a 512px nodpi
    bitmap as a giant intrinsic drawable, and preserves the selected gradients
    that the former flat VectorDrawable could only approximate.
    """

    outputs: list[Path] = []
    for density, scale in ANDROID_DENSITIES.items():
        pixels = round(WIDGET_MARK_DP * scale)
        output = (
            ANDROID_RES
            / f"drawable-{density}"
            / "perfect_widget_mark_raster.png"
        )
        output.parent.mkdir(parents=True, exist_ok=True)
        _resize_rgba_premultiplied(master, (pixels, pixels)).save(
            output,
            optimize=True,
        )
        outputs.append(output)
    return outputs


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)

    source = Image.open(SOURCE)
    master = _fit_master(_remove_magenta(source))
    _validate_master(master)

    MASTER.parent.mkdir(parents=True, exist_ok=True)
    SELECTION_DIR.mkdir(parents=True, exist_ok=True)
    WINDOWS_ICO.parent.mkdir(parents=True, exist_ok=True)

    master.save(MASTER, optimize=True)
    monochrome = Image.new("RGBA", master.size, (255, 255, 255, 0))
    monochrome.putalpha(master.getchannel("A"))
    monochrome.save(MONOCHROME, optimize=True)
    master.save(PREVIEW, optimize=True)
    master.save(
        WINDOWS_ICO,
        format="ICO",
        sizes=[
            (16, 16),
            (20, 20),
            (24, 24),
            (32, 32),
            (40, 40),
            (48, 48),
            (64, 64),
            (128, 128),
            (256, 256),
        ],
    )
    android_widget_marks = _write_android_widget_marks(master)

    bounds = master.getchannel("A").getbbox()
    print(f"source_chroma={_sample_chroma(source)}")
    print(f"master={MASTER} size={master.size} alpha_bounds={bounds}")
    print(f"monochrome={MONOCHROME}")
    print(f"preview={PREVIEW}")
    print(f"windows_ico={WINDOWS_ICO}")
    for widget_mark in android_widget_marks:
        print(f"android_widget_mark={widget_mark}")


if __name__ == "__main__":
    main()
