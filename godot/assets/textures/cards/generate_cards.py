#!/usr/bin/env python3
"""Generate readable card face PNGs."""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 256, 374
OUT_DIR = Path(__file__).resolve().parent

RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
SUITS = ["hearts", "diamonds", "clubs", "spades"]
SUIT_COLORS = {
    "hearts": (214, 30, 41),
    "diamonds": (214, 30, 41),
    "clubs": (20, 20, 26),
    "spades": (20, 20, 26),
}


def _load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/arialbd.ttf"),
        Path("C:/Windows/Fonts/segoeuib.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def _draw_centered(
    draw: ImageDraw.ImageDraw,
    text: str,
    center: tuple[int, int],
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int],
) -> None:
    bbox = draw.textbbox((0, 0), text, font=font)
    x = center[0] - (bbox[2] + bbox[0]) // 2
    y = center[1] - (bbox[3] + bbox[1]) // 2
    draw.text((x, y), text, font=font, fill=fill)


def _draw_heart(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int, fill) -> None:
    r = size * 0.24
    draw.ellipse((cx - r * 2, cy - r, cx, cy + r), fill=fill)
    draw.ellipse((cx, cy - r, cx + r * 2, cy + r), fill=fill)
    draw.polygon([(cx - r * 2, cy), (cx + r * 2, cy), cx, cy + r * 2.2], fill=fill)


def _draw_diamond(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int, fill) -> None:
    w = size * 0.34
    h = size * 0.46
    draw.polygon([(cx, cy - h), (cx + w, cy), (cx, cy + h), (cx - w, cy)], fill=fill)


def _draw_club(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int, fill) -> None:
    r = size * 0.15
    draw.ellipse((cx - r, cy - r * 2.2, cx + r, cy), fill=fill)
    draw.ellipse((cx - r * 2, cy - r * 0.8, cx, cy + r * 1.1), fill=fill)
    draw.ellipse((cx, cy - r * 0.8, cx + r * 2, cy + r * 1.1), fill=fill)
    draw.rectangle((cx - r * 0.35, cy + r * 0.4, cx + r * 0.35, cy + r * 2.4), fill=fill)


def _draw_spade(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int, fill) -> None:
    r = size * 0.15
    draw.ellipse((cx - r, cy - r * 2.2, cx + r, cy), fill=fill)
    draw.ellipse((cx - r * 2, cy - r * 0.8, cx, cy + r * 1.1), fill=fill)
    draw.ellipse((cx, cy - r * 0.8, cx + r * 2, cy + r * 1.1), fill=fill)
    draw.polygon([(cx - r * 1.6, cy + r * 0.2), (cx + r * 1.6, cy + r * 0.2), cx, cy + r * 2.2], fill=fill)
    draw.rectangle((cx - r * 0.35, cy + r * 1.8, cx + r * 0.35, cy + r * 2.5), fill=fill)


def _draw_suit(draw: ImageDraw.ImageDraw, suit: str, center: tuple[int, int], size: int, fill) -> None:
    if suit == "hearts":
        _draw_heart(draw, center[0], center[1], size, fill)
    elif suit == "diamonds":
        _draw_diamond(draw, center[0], center[1], size, fill)
    elif suit == "clubs":
        _draw_club(draw, center[0], center[1], size, fill)
    else:
        _draw_spade(draw, center[0], center[1], size, fill)


def make_face(rank: str, suit: str) -> Image.Image:
    img = Image.new("RGB", (WIDTH, HEIGHT), (252, 250, 245))
    draw = ImageDraw.Draw(img)
    border = (108, 102, 92)
    inner = (238, 236, 230)
    draw.rectangle((0, 0, WIDTH - 1, HEIGHT - 1), outline=border, width=6)
    draw.rectangle((10, 10, WIDTH - 11, HEIGHT - 11), outline=inner, width=3)
    draw.rectangle((18, 18, WIDTH - 19, HEIGHT - 19), outline=border, width=2)

    color = SUIT_COLORS[suit]
    rank_font = _load_font(40 if rank != "10" else 34)
    _draw_centered(draw, rank, (44, 44), rank_font, color)
    _draw_suit(draw, suit, (44, 86), 34, color)
    _draw_suit(draw, suit, (WIDTH // 2, HEIGHT // 2), 120, color)
    _draw_suit(draw, suit, (WIDTH - 44, HEIGHT - 86), 34, color)
    _draw_centered(draw, rank, (WIDTH - 44, HEIGHT - 44), rank_font, color)
    return img


def make_back() -> Image.Image:
    img = Image.new("RGB", (WIDTH, HEIGHT), (41, 66, 132))
    draw = ImageDraw.Draw(img)
    accent = (66, 102, 173)
    for y in range(16, HEIGHT - 16, 24):
        for x in range(16, WIDTH - 16, 24):
            draw.rectangle((x, y, x + 12, y + 12), fill=accent)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for rank in RANKS:
        for suit in SUITS:
            out = OUT_DIR / f"{rank}_{suit}.png"
            make_face(rank, suit).save(out, optimize=True)
    make_back().save(OUT_DIR / "back.png", optimize=True)
    print(f"Wrote {len(RANKS) * len(SUITS) + 1} card textures to {OUT_DIR}")


if __name__ == "__main__":
    main()
