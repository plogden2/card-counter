#!/usr/bin/env python3
"""Compare captured sidebar PNG against reference crop and write diff report."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "assets/reference/ref-sidebar-crop.png"
CAPTURE = ROOT / "tests/visual/output/sidebar_capture.png"
OUT_DIR = ROOT / "tests/visual/output"
THRESHOLD = 42  # per-channel tolerance for "close enough" pixels


def load_rgb(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def align_heights(ref: Image.Image, cap: Image.Image) -> tuple[Image.Image, Image.Image]:
    width = min(ref.width, cap.width)
    ref = ref.crop((0, 0, width, ref.height))
    cap = cap.resize((width, cap.height), Image.Resampling.LANCZOS)
    height = min(ref.height, cap.height)
    return ref.crop((0, 0, width, height)), cap.crop((0, 0, width, height))


def compare(ref: Image.Image, cap: Image.Image) -> dict:
    ref_arr = np.asarray(ref, dtype=np.int16)
    cap_arr = np.asarray(cap, dtype=np.int16)
    diff = np.abs(ref_arr - cap_arr)
    per_pixel = diff.max(axis=2)
    close = per_pixel <= THRESHOLD
    match_pct = float(close.mean() * 100.0)
    mae = float(diff.mean())
    diff_img = Image.fromarray(np.clip(diff * 4, 0, 255).astype(np.uint8))
    overlay = Image.blend(ref, cap, 0.5)
    side = Image.new("RGB", (ref.width * 3 + 20, ref.height), (32, 32, 32))
    side.paste(ref, (0, 0))
    side.paste(cap, (ref.width + 10, 0))
    side.paste(diff_img, (ref.width * 2 + 20, 0))
    return {
        "match_pct": round(match_pct, 2),
        "mae": round(mae, 2),
        "width": ref.width,
        "height": ref.height,
        "threshold": THRESHOLD,
        "side_by_side": side,
        "overlay": overlay,
        "diff": diff_img,
    }


def main() -> int:
    if not REF.exists():
        print(f"Missing reference: {REF}")
        return 1
    if not CAPTURE.exists():
        print(f"Missing capture: {CAPTURE}")
        return 1

    ref = load_rgb(REF)
    cap = load_rgb(CAPTURE)
    ref, cap = align_heights(ref, cap)
    result = compare(ref, cap)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    result["side_by_side"].save(OUT_DIR / "sidebar_compare.png")
    result["overlay"].save(OUT_DIR / "sidebar_overlay.png")
    result["diff"].save(OUT_DIR / "sidebar_diff.png")

    report = {k: v for k, v in result.items() if k not in ("side_by_side", "overlay", "diff")}
    (OUT_DIR / "sidebar_compare_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(json.dumps(report, indent=2))
    print(f"Wrote {OUT_DIR / 'sidebar_compare.png'}")
    # Pass if structural match is reasonable; exact pixel match is unlikely without same render pipeline.
    return 0 if report["match_pct"] >= 55.0 else 1


if __name__ == "__main__":
    sys.exit(main())
