#!/usr/bin/env python3
"""Generate readable card face PNGs (stdlib only)."""
import os
import struct
import zlib

WIDTH, HEIGHT = 192, 280
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
SUITS = ["hearts", "diamonds", "clubs", "spades"]
SUIT_COLORS = {
    "hearts": (0.82, 0.12, 0.14),
    "diamonds": (0.82, 0.12, 0.14),
    "clubs": (0.1, 0.1, 0.12),
    "spades": (0.1, 0.1, 0.12),
}
SUIT_GLYPH = {
    "hearts": "H",
    "diamonds": "D",
    "clubs": "C",
    "spades": "S",
}


def _png_chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def _write_png(path: str, pixels: list) -> None:
    raw = b""
    for row in pixels:
        raw += b"\x00"
        for r, g, b in row:
            raw += bytes((int(r * 255), int(g * 255), int(b * 255)))

    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += _png_chunk(b"IHDR", ihdr)
    png += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    png += _png_chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def _fill(color: tuple) -> list:
    return [[color for _ in range(WIDTH)] for _ in range(HEIGHT)]


def _rect(pixels: list, x0: int, y0: int, x1: int, y1: int, color: tuple) -> None:
    for y in range(max(0, y0), min(HEIGHT, y1)):
        for x in range(max(0, x0), min(WIDTH, x1)):
            pixels[y][x] = color


def _draw_text_block(pixels: list, text: str, cx: int, cy: int, color: tuple, scale: int = 5) -> None:
    glyphs = {
        "0": ["111", "101", "101", "101", "111"],
        "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"],
        "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"],
        "7": ["111", "001", "010", "010", "010"],
        "8": ["111", "101", "111", "101", "111"],
        "9": ["111", "101", "111", "001", "111"],
        "A": ["010", "101", "111", "101", "101"],
        "J": ["001", "001", "001", "001", "111"],
        "Q": ["111", "101", "101", "101", "111"],
        "K": ["101", "110", "100", "110", "101"],
        "H": ["101", "101", "111", "101", "101"],
        "D": ["110", "101", "101", "101", "110"],
        "C": ["011", "100", "100", "100", "011"],
        "S": ["011", "100", "010", "001", "110"],
    }
    lines = glyphs.get(text, glyphs["0"])
    h = len(lines)
    w = len(lines[0])
    total_w = w * scale
    total_h = h * scale
    ox = cx - total_w // 2
    oy = cy - total_h // 2
    for row_i, row in enumerate(lines):
        for col_i, ch in enumerate(row):
            if ch != "1":
                continue
            _rect(
                pixels,
                ox + col_i * scale,
                oy + row_i * scale,
                ox + col_i * scale + scale,
                oy + row_i * scale + scale,
                color,
            )


def make_face(rank: str, suit: str) -> list:
    bg = (0.98, 0.97, 0.94)
    border = (0.45, 0.42, 0.38)
    pixels = _fill(bg)
    _rect(pixels, 4, 4, WIDTH - 4, HEIGHT - 4, border)
    _rect(pixels, 8, 8, WIDTH - 8, HEIGHT - 8, bg)
    suit_color = SUIT_COLORS[suit]
    rank_label = rank if rank != "10" else "10"
    _draw_text_block(pixels, rank_label[0] if len(rank_label) == 1 else rank_label[0], 28, 32, suit_color, 5)
    if rank == "10":
        _draw_text_block(pixels, "0", 48, 32, suit_color, 5)
    _draw_text_block(pixels, SUIT_GLYPH[suit], WIDTH // 2, HEIGHT // 2, suit_color, 10)
    _draw_text_block(pixels, rank_label[-1], WIDTH - 28, HEIGHT - 32, suit_color, 5)
    return pixels


def make_back() -> list:
    bg = (0.16, 0.26, 0.52)
    accent = (0.26, 0.4, 0.68)
    pixels = _fill(bg)
    for y in range(12, HEIGHT - 12, 16):
        for x in range(12, WIDTH - 12, 16):
            _rect(pixels, x, y, x + 8, y + 8, accent)
    return pixels


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    for rank in RANKS:
        for suit in SUITS:
            name = f"{rank}_{suit}.png"
            _write_png(os.path.join(OUT_DIR, name), make_face(rank, suit))
    _write_png(os.path.join(OUT_DIR, "back.png"), make_back())
    print(f"Wrote {len(RANKS) * len(SUITS) + 1} card textures to {OUT_DIR}")


if __name__ == "__main__":
    main()
