"""Generate Ref B sidebar icons and color manifest from reference sampling."""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
REF = Path(__file__).resolve().parents[4] / "specs/002-2-5d-visual-audio/references/ref-2d-tutorial-sidebar-ui.png"

# Sampled from ref-2d-tutorial-sidebar-ui.png
COLORS = {
    "sidebar_outer": (36, 35, 30),
    "header_green": (44, 68, 42),
    "panel_cream": (242, 221, 190),
    "stat_brown": (84, 63, 36),
    "stat_border": (65, 48, 28),
    "text_cream": (243, 222, 193),
    "text_muted": (216, 182, 134),
    "text_dark": (88, 64, 38),
    "count_pos": (122, 176, 80),
    "count_neu": (122, 110, 96),
    "count_neg": (198, 96, 72),
    "badge_pos": (98, 154, 72),
    "badge_neu": (122, 110, 96),
    "badge_neg": (198, 96, 72),
    "tip_yellow": (252, 189, 73),
    "tip_green": (44, 68, 42),
    "chip_red": (196, 58, 48),
    "chip_white": (245, 240, 230),
    "deck_blue": (58, 92, 168),
    "paw_fill": (233, 206, 161),
    "help_circle": (88, 64, 38),
}


def _save(img: Image.Image, name: str) -> None:
    path = OUT / name
    img.save(path, optimize=True)
    print(f"  {path.name} {img.size}")


def _circle(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill) -> None:
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)


def icon_paw(size: int = 24) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = (*COLORS["paw_fill"], 255)
    pad = size * 0.12
    toe_r = size * 0.11
    heel_r = size * 0.17
    toes = [(pad + toe_r, pad + toe_r), (size * 0.35, pad * 0.6), (size * 0.65, pad * 0.6), (size - pad - toe_r, pad + toe_r)]
    for tx, ty in toes:
        _circle(d, tx, ty, toe_r, fill)
    _circle(d, size * 0.5, size * 0.62, heel_r, fill)
    return img


def icon_deck(size: int = 28) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w, h = size * 0.42, size * 0.58
    offsets = [(0, 4), (4, 2), (8, 0)]
    for i, (ox, oy) in enumerate(offsets):
        x0, y0 = ox + 2, oy + 4
        x1, y1 = x0 + w, y0 + h
        d.rounded_rectangle((x0, y0, x1, y1), radius=3, fill=(*COLORS["deck_blue"], 255))
        d.rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), fill=(72, 108, 188, 255))
    return img


def icon_chip(size: int = 28) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r = size * 0.44
    _circle(d, cx, cy, r, (*COLORS["chip_red"], 255))
    _circle(d, cx, cy, r * 0.72, (*COLORS["chip_white"], 255))
    _circle(d, cx, cy, r * 0.48, (*COLORS["chip_red"], 255))
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x = cx + math.cos(rad) * r * 0.86
        y = cy + math.sin(rad) * r * 0.86
        _circle(d, x, y, size * 0.045, (*COLORS["chip_white"], 255))
    return img


def icon_bulb(size: int = 20) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = (*COLORS["tip_yellow"], 255)
    cx = size / 2
    d.ellipse((cx - size * 0.28, 2, cx + size * 0.28, size * 0.58), fill=fill)
    d.rectangle((cx - size * 0.12, size * 0.54, cx + size * 0.12, size * 0.72), fill=fill)
    d.rectangle((cx - size * 0.18, size * 0.72, cx + size * 0.18, size * 0.84), fill=(180, 140, 60, 255))
    return img


def icon_help(size: int = 20) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    _circle(d, cx, cy, size * 0.46, (*COLORS["help_circle"], 255))
    try:
        font = ImageFont.truetype("arialbd.ttf", int(size * 0.62))
    except OSError:
        font = ImageFont.load_default()
    d.text((cx, cy), "?", fill=(*COLORS["text_cream"], 255), font=font, anchor="mm")
    return img


def icon_star(size: int = 18) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r_outer = size * 0.46
    r_inner = size * 0.2
    pts = []
    for i in range(10):
        ang = math.radians(-90 + i * 36)
        r = r_outer if i % 2 == 0 else r_inner
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    d.polygon(pts, fill=(*COLORS["tip_yellow"], 255))
    return img


def icon_paw_dark(size: int = 16) -> Image.Image:
    img = icon_paw(size)
    # tint to darker green-brown for header
    px = img.load()
    tint = COLORS["paw_fill"]
    for y in range(size):
        for x in range(size):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (*tint, a)
    return img


def write_manifest() -> None:
    manifest = {"colors": {k: list(v) for k, v in COLORS.items()}, "source": str(REF.name)}
    (OUT / "sidebar_colors.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def icon_pill(text: str, color: tuple[int, int, int], size: tuple[int, int] = (52, 24)) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=h // 2, fill=(*color, 255))
    try:
        font = ImageFont.truetype("arialbd.ttf", 12)
    except OSError:
        font = ImageFont.load_default()
    d.text((w / 2, h / 2), text, fill=(255, 255, 255, 255), font=font, anchor="mm")
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    print("Generating sidebar UI assets...")
    _save(icon_paw(24), "icon_paw.png")
    _save(icon_paw_dark(16), "icon_paw_header.png")
    _save(icon_deck(28), "icon_deck.png")
    _save(icon_chip(28), "icon_chip.png")
    _save(icon_bulb(20), "icon_bulb.png")
    _save(icon_help(20), "icon_help.png")
    _save(icon_star(18), "icon_star.png")
    _save(icon_pill("+1", COLORS["badge_pos"]), "badge_pos.png")
    _save(icon_pill("0", COLORS["badge_neu"]), "badge_neu.png")
    _save(icon_pill("-1", COLORS["badge_neg"]), "badge_neg.png")
    write_manifest()
    print("Done.")


if __name__ == "__main__":
    main()
