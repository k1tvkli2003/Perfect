"""Generate the fixed Perfect! header wordmark as transparent raster art.

The Flutter SVG renderer intentionally does not render SVG <text> nodes.  The
wordmark therefore ships as authored pixels instead of relying on a platform
font at runtime.  A large source keeps it sharp at every current header size.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "assets" / "fonts" / "PlusJakartaSans-Variable.ttf"
OUTPUT_DIR = ROOT / "assets" / "brand"


def _font(size: int, weight: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT_PATH), size=size)
    font.set_variation_by_axes([weight])
    return font


def render_wordmark(*, ink: str, accent: str, destination: Path) -> None:
    size = 420
    font = _font(size, 660)
    canvas = Image.new("RGBA", (2400, 720), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    bbox = font.getbbox("Perfect!")
    baseline_y = 30 - bbox[1]
    draw.text((30, baseline_y), "Perfect", font=font, fill=ink)
    accent_x = 30 + draw.textlength("Perfect", font=font) - 5
    draw.text((accent_x, baseline_y), "!", font=font, fill=accent)

    alpha_bounds = canvas.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise RuntimeError("Wordmark rendering produced no visible pixels.")
    left, top, right, bottom = alpha_bounds
    padding = 24
    cropped = canvas.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(canvas.width, right + padding),
            min(canvas.height, bottom + padding),
        )
    )
    cropped.save(destination, optimize=True)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    render_wordmark(
        ink="#1D2030",
        accent="#A99ADE",
        destination=OUTPUT_DIR / "perfect-wordmark.png",
    )
    render_wordmark(
        ink="#FFF9F1",
        accent="#B9AAEB",
        destination=OUTPUT_DIR / "perfect-wordmark-dark.png",
    )


if __name__ == "__main__":
    main()
