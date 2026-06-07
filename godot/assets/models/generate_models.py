#!/usr/bin/env python3
"""Generate faceted low-poly glTF models matching Ref A (papercraft chibi dogs, cozy room props)."""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent


def _flat_normal(v0, v1, v2):
    ax, ay, az = v1[0] - v0[0], v1[1] - v0[1], v1[2] - v0[2]
    bx, by, bz = v2[0] - v0[0], v2[1] - v0[1], v2[2] - v0[2]
    nx = ay * bz - az * by
    ny = az * bx - ax * bz
    nz = ax * by - ay * bx
    length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return (nx / length, ny / length, nz / length)


class FacetedMesh:
    def __init__(self) -> None:
        self.positions: list[tuple[float, float, float]] = []
        self.normals: list[tuple[float, float, float]] = []
        self.indices: list[int] = []

    def add_quad(self, v0, v1, v2, v3) -> None:
        n = _flat_normal(v0, v1, v2)
        base = len(self.positions)
        for v in (v0, v1, v2, v3):
            self.positions.append(v)
            self.normals.append(n)
        self.indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])

    def add_triangle(self, v0, v1, v2) -> None:
        n = _flat_normal(v0, v1, v2)
        base = len(self.positions)
        for v in (v0, v1, v2):
            self.positions.append(v)
            self.normals.append(n)
        self.indices.extend([base, base + 1, base + 2])

    def add_box(self, cx: float, cy: float, cz: float, sx: float, sy: float, sz: float) -> None:
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        corners = [
            (cx - hx, cy - hy, cz - hz),
            (cx + hx, cy - hy, cz - hz),
            (cx + hx, cy + hy, cz - hz),
            (cx - hx, cy + hy, cz - hz),
            (cx - hx, cy - hy, cz + hz),
            (cx + hx, cy - hy, cz + hz),
            (cx + hx, cy + hy, cz + hz),
            (cx - hx, cy + hy, cz + hz),
        ]
        faces = [
            (0, 1, 2, 3),
            (4, 5, 6, 7),
            (0, 4, 7, 3),
            (1, 5, 6, 2),
            (3, 2, 6, 7),
            (0, 1, 5, 4),
        ]
        for f in faces:
            self.add_quad(*(corners[i] for i in f))

    def add_cylinder(self, cx: float, cy: float, cz: float, r: float, h: float, segments: int = 8) -> None:
        hy = h / 2
        top = [(cx + r * math.cos(a), cy + hy, cz + r * math.sin(a)) for a in _ring_angles(segments)]
        bot = [(cx + r * math.cos(a), cy - hy, cz + r * math.sin(a)) for a in _ring_angles(segments)]
        center_top = (cx, cy + hy, cz)
        center_bot = (cx, cy - hy, cz)
        for i in range(segments):
            j = (i + 1) % segments
            self.add_quad(bot[i], bot[j], top[j], top[i])
            self.add_triangle(center_top, top[i], top[j])
            self.add_triangle(center_bot, bot[j], bot[i])

    def to_glb(self, path: Path, color: list[float], name: str = "mesh") -> None:
        pos_flat = [c for p in self.positions for c in p]
        nrm_flat = [c for n in self.normals for c in n]
        indices = self.indices

        bin_blob = bytearray()
        pos_off = 0
        bin_blob.extend(struct.pack(f"<{len(pos_flat)}f", *pos_flat))
        nrm_off = len(bin_blob)
        bin_blob.extend(struct.pack(f"<{len(nrm_flat)}f", *nrm_flat))
        idx_off = len(bin_blob)
        bin_blob.extend(struct.pack(f"<{len(indices)}H", *indices))

        gltf = {
            "asset": {"version": "2.0", "generator": "card-counter-generate_models"},
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "nodes": [{"mesh": 0, "name": name}],
            "meshes": [
                {
                    "primitives": [
                        {
                            "attributes": {"POSITION": 0, "NORMAL": 1},
                            "indices": 2,
                            "mode": 4,
                            "material": 0,
                        }
                    ],
                    "name": name,
                }
            ],
            "materials": [
                {
                    "name": "faceted_matte",
                    "pbrMetallicRoughness": {
                        "baseColorFactor": color,
                        "metallicFactor": 0.0,
                        "roughnessFactor": 0.92,
                    },
                    "doubleSided": True,
                }
            ],
            "accessors": [
                {
                    "bufferView": 0,
                    "componentType": 5126,
                    "count": len(self.positions),
                    "type": "VEC3",
                    "max": _vec_max(self.positions),
                    "min": _vec_min(self.positions),
                },
                {
                    "bufferView": 1,
                    "componentType": 5126,
                    "count": len(self.normals),
                    "type": "VEC3",
                },
                {
                    "bufferView": 2,
                    "componentType": 5123,
                    "count": len(indices),
                    "type": "SCALAR",
                },
            ],
            "bufferViews": [
                {"buffer": 0, "byteOffset": pos_off, "byteLength": len(pos_flat) * 4},
                {"buffer": 0, "byteOffset": nrm_off, "byteLength": len(nrm_flat) * 4},
                {"buffer": 0, "byteOffset": idx_off, "byteLength": len(indices) * 2},
            ],
            "buffers": [{"byteLength": len(bin_blob)}],
        }

        json_chunk = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
        json_pad = (4 - len(json_chunk) % 4) % 4
        json_chunk += b" " * json_pad
        bin_pad = (4 - len(bin_blob) % 4) % 4
        bin_blob.extend(b"\x00" * bin_pad)

        total = 12 + 8 + len(json_chunk) + 8 + len(bin_blob)
        header = struct.pack("<4sII", b"glTF", 2, total)
        json_header = struct.pack("<I4s", len(json_chunk), b"JSON") + json_chunk
        bin_header = struct.pack("<I4s", len(bin_blob), b"BIN\x00") + bin_blob
        path.write_bytes(header + json_header + bin_header)


def _ring_angles(segments: int):
    return [2 * math.pi * i / segments for i in range(segments)]


def _vec_max(positions):
    return [max(p[i] for p in positions) for i in range(3)]


def _vec_min(positions):
    return [min(p[i] for p in positions) for i in range(3)]


def build_chibi_dog(hoodie_color: list[float], dealer: bool = False) -> FacetedMesh:
    m = FacetedMesh()
    # Chibi: oversized head, chunky body, minimal limbs
    m.add_box(0, 0.42, 0, 0.32, 0.28, 0.22)  # head
    m.add_box(0, 0.18, 0, 0.28, 0.22, 0.2)  # torso
    if dealer:
        m.add_box(0, 0.2, 0.02, 0.3, 0.24, 0.22)  # vest (dark)
    else:
        m.add_box(0, 0.2, 0, 0.32, 0.26, 0.24)  # hoodie
    m.add_box(-0.12, 0.08, 0.05, 0.1, 0.14, 0.1)  # leg L
    m.add_box(0.12, 0.08, 0.05, 0.1, 0.14, 0.1)  # leg R
    m.add_box(-0.18, 0.28, 0, 0.08, 0.1, 0.08)  # arm L
    m.add_box(0.18, 0.28, 0, 0.08, 0.1, 0.08)  # arm R
    m.add_box(0, 0.38, 0.14, 0.1, 0.08, 0.08)  # snout
    m.add_box(-0.14, 0.52, -0.02, 0.08, 0.1, 0.06)  # ear L
    m.add_box(0.14, 0.52, -0.02, 0.08, 0.1, 0.06)  # ear R
    return m


def build_round_table() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 0.03, 0, 1.35, 0.06, 10)  # felt
    m.add_cylinder(0, 0.09, 0, 1.5, 0.12, 10)  # wooden rim
    return m


def build_chip() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 0.015, 0, 0.12, 0.03, 8)
    return m


def build_shoe() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.1, 0, 0.35, 0.2, 0.55)
    m.add_box(0, 0.22, 0.05, 0.28, 0.12, 0.35)  # card stack
    return m


def build_lamp() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 2.5, 0, 0.35, 0.15, 6)  # shade (faceted)
    m.add_box(0, 2.35, 0, 0.08, 0.2, 0.08)  # stem
    return m


def build_discard_tray() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.04, 0, 0.5, 0.08, 0.35)
    return m


def build_plant() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 0.12, 0, 0.12, 0.24, 6)  # pot
    m.add_box(0, 0.35, 0, 0.22, 0.2, 0.22)  # foliage
    return m


def main() -> None:
    specs = [
        ("dog_player_red.glb", lambda: build_chibi_dog([0.85, 0.35, 0.28, 1.0])),
        ("dog_player_blue.glb", lambda: build_chibi_dog([0.28, 0.45, 0.82, 1.0])),
        ("dog_player_green.glb", lambda: build_chibi_dog([0.32, 0.72, 0.38, 1.0])),
        ("dog_dealer.glb", lambda: build_chibi_dog([0.92, 0.9, 0.85, 1.0], dealer=True)),
        ("round_table.glb", lambda: build_round_table()),
        ("chip.glb", lambda: build_chip()),
        ("card_shoe.glb", lambda: build_shoe()),
        ("overhead_lamp.glb", lambda: build_lamp()),
        ("discard_tray.glb", lambda: build_discard_tray()),
        ("potted_plant.glb", lambda: build_plant()),
    ]
    for filename, builder in specs:
        mesh = builder()
        color = [0.7, 0.7, 0.7, 1.0]
        out = OUT_DIR / filename
        mesh.to_glb(out, color, filename.replace(".glb", ""))
        print(f"  {out.name}")
    manifest = {"models": [f[0] for f in specs], "style": "ref-a-faceted-low-poly"}
    (OUT_DIR / "models_manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print(f"Generated {len(specs)} glTF models in {OUT_DIR}")


if __name__ == "__main__":
    main()
