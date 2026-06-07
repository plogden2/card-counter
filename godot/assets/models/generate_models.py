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
        faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 4, 7, 3), (1, 5, 6, 2), (3, 2, 6, 7), (0, 1, 5, 4)]
        for f in faces:
            self.add_quad(*(corners[i] for i in f))

    def add_cylinder(
        self,
        cx: float,
        cy: float,
        cz: float,
        r: float,
        h: float,
        segments: int = 8,
        rx_scale: float = 1.0,
        rz_scale: float = 1.0,
    ) -> None:
        hy = h / 2
        top = [
            (cx + r * rx_scale * math.cos(a), cy + hy, cz + r * rz_scale * math.sin(a))
            for a in _ring_angles(segments)
        ]
        bot = [
            (cx + r * rx_scale * math.cos(a), cy - hy, cz + r * rz_scale * math.sin(a))
            for a in _ring_angles(segments)
        ]
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


def _chibi_base(m: FacetedMesh, hoodie: bool = True) -> None:
    """Shared chibi body: oversized head, chunky limbs."""
    m.add_box(0, 0.48, 0.04, 0.42, 0.38, 0.32)  # head
    m.add_box(0, 0.38, 0.16, 0.14, 0.1, 0.1)  # snout
    m.add_box(-0.16, 0.62, -0.04, 0.1, 0.14, 0.08)  # ear L
    m.add_box(0.16, 0.62, -0.04, 0.1, 0.14, 0.08)  # ear R
    m.add_box(-0.1, 0.54, 0.18, 0.05, 0.05, 0.03)  # eye L
    m.add_box(0.1, 0.54, 0.18, 0.05, 0.05, 0.03)  # eye R
    m.add_box(0, 0.44, 0.2, 0.05, 0.04, 0.03)  # nose
    m.add_box(0, 0.2, 0, 0.34, 0.26, 0.24)  # torso
    if hoodie:
        m.add_box(0, 0.22, -0.02, 0.38, 0.3, 0.28)  # hood back
        m.add_box(0, 0.34, -0.06, 0.36, 0.18, 0.22)  # hood top
    m.add_box(-0.14, 0.08, 0.06, 0.11, 0.16, 0.11)  # leg L
    m.add_box(0.14, 0.08, 0.06, 0.11, 0.16, 0.11)  # leg R
    m.add_box(-0.22, 0.28, 0, 0.1, 0.12, 0.1)  # arm L
    m.add_box(0.22, 0.28, 0, 0.1, 0.12, 0.1)  # arm R


def build_dealer_dog() -> FacetedMesh:
    """St Bernard dealer: tan/white blaze, vest + bowtie + shirt."""
    m = FacetedMesh()
    # Shirt torso.
    m.add_box(0, 0.28, -0.04, 0.34, 0.30, 0.24)
    # Vest panels.
    m.add_box(-0.12, 0.27, 0.0, 0.12, 0.26, 0.26)
    m.add_box(0.12, 0.27, 0.0, 0.12, 0.26, 0.26)
    # Bow tie + collar block.
    m.add_box(-0.05, 0.46, 0.12, 0.06, 0.04, 0.03)
    m.add_box(0.05, 0.46, 0.12, 0.06, 0.04, 0.03)
    m.add_box(0, 0.46, 0.11, 0.04, 0.04, 0.03)
    m.add_box(0, 0.44, 0.08, 0.18, 0.05, 0.06)
    # Sleeves and paws.
    m.add_box(-0.24, 0.20, -0.38, 0.10, 0.12, 0.32)
    m.add_box(0.24, 0.20, -0.38, 0.10, 0.12, 0.32)
    m.add_box(-0.24, 0.12, -0.78, 0.14, 0.06, 0.12)
    m.add_box(0.24, 0.12, -0.78, 0.14, 0.06, 0.12)
    # Head: tan cheeks, crown, white blaze, ears, patch, muzzle.
    m.add_box(-0.18, 0.68, 0.04, 0.12, 0.34, 0.28)
    m.add_box(0.18, 0.68, 0.04, 0.12, 0.34, 0.28)
    m.add_box(0, 0.70, 0.02, 0.18, 0.32, 0.30)
    m.add_box(0, 0.66, 0.16, 0.12, 0.34, 0.06)
    m.add_box(-0.24, 0.76, -0.02, 0.10, 0.20, 0.06)
    m.add_box(0.24, 0.76, -0.02, 0.10, 0.20, 0.06)
    m.add_box(-0.10, 0.72, 0.18, 0.08, 0.08, 0.03)
    m.add_box(0, 0.58, 0.22, 0.16, 0.12, 0.10)
    # Face details.
    m.add_box(-0.06, 0.72, 0.20, 0.04, 0.05, 0.02)
    m.add_box(0.06, 0.72, 0.20, 0.04, 0.05, 0.02)
    m.add_box(0, 0.60, 0.28, 0.06, 0.05, 0.04)
    m.add_box(-0.04, 0.54, 0.27, 0.03, 0.02, 0.02)
    m.add_box(0.04, 0.54, 0.27, 0.03, 0.02, 0.02)
    return m


def build_bear_player() -> FacetedMesh:
    """Tan bear in blue hoodie (Ref A bottom-left player)."""
    m = FacetedMesh()
    _chibi_base(m, hoodie=True)
    m.add_box(0, 0.5, 0.02, 0.08, 0.08, 0.06)  # round ear nubs
    return m


def build_husky_player() -> FacetedMesh:
    """Grey husky in red hoodie (Ref A bottom-right player)."""
    m = FacetedMesh()
    _chibi_base(m, hoodie=True)
    m.add_box(0, 0.52, -0.02, 0.32, 0.22, 0.24)  # dark grey head cap
    m.add_box(0, 0.48, 0.16, 0.2, 0.16, 0.12)  # white muzzle patch
    return m


def build_round_table() -> FacetedMesh:
    """Blackjack half-ellipse: flat dealer edge, curved player rail."""
    m = FacetedMesh()
    rx, dealer_z, rz = 1.35, -0.52, 1.55
    segments = 24
    top_y, rim_drop = 0.04, 0.12
    outline: list[tuple[float, float]] = []
    for i in range(segments + 1):
        angle = math.pi * i / segments
        outline.append((rx * math.cos(angle), dealer_z + rz * math.sin(angle)))
    cx = sum(p[0] for p in outline) / len(outline)
    cz = sum(p[1] for p in outline) / len(outline)
    for i in range(len(outline) - 1):
        x0, z0 = outline[i]
        x1, z1 = outline[i + 1]
        m.add_triangle((cx, top_y, cz), (x0, top_y, z0), (x1, top_y, z1))
    for i in range(len(outline) - 1):
        x0, z0 = outline[i]
        x1, z1 = outline[i + 1]
        dx, dz = x0 - cx, z0 - cz
        length = math.sqrt(dx * dx + dz * dz) or 1.0
        ox, oz = x0 + dx / length * 0.14, z0 + dz / length * 0.14
        ox1, oz1 = x1 + (x1 - cx) / (math.sqrt((x1 - cx) ** 2 + (z1 - cz) ** 2) or 1) * 0.14, z1 + (z1 - cz) / (math.sqrt((x1 - cx) ** 2 + (z1 - cz) ** 2) or 1) * 0.14
        m.add_quad(
            (x0, top_y, z0),
            (x1, top_y, z1),
            (x1, top_y - rim_drop, z1),
            (x0, top_y - rim_drop, z0),
        )
        m.add_quad(
            (ox, top_y, oz),
            (ox1, top_y, oz1),
            (ox1, top_y - rim_drop, oz1),
            (ox, top_y - rim_drop, oz),
        )
    return m


def build_chip() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 0.015, 0, 0.12, 0.028, 8)
    m.add_cylinder(0, 0.015, 0, 0.095, 0.032, 8)  # stripe ring
    return m


def build_shoe() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.1, 0, 0.38, 0.22, 0.58)
    m.add_box(0, 0.24, 0.06, 0.3, 0.14, 0.38)  # card stack
    m.add_box(0.14, 0.08, 0.22, 0.08, 0.06, 0.12)  # roller
    return m


def build_lamp() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 2.55, 0, 0.42, 0.18, 8)  # faceted shade
    m.add_box(0, 2.38, 0, 0.06, 0.24, 0.06)  # stem
    m.add_box(0, 2.72, 0, 0.1, 0.06, 0.1)  # ceiling mount
    return m


def build_discard_tray() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.04, 0, 0.55, 0.08, 0.38)
    m.add_box(0, 0.1, 0, 0.42, 0.12, 0.28)  # card stack
    return m


def build_plant() -> FacetedMesh:
    m = FacetedMesh()
    m.add_cylinder(0, 0.12, 0, 0.14, 0.26, 6)
    m.add_box(0, 0.38, 0, 0.26, 0.24, 0.26)  # foliage
    m.add_box(-0.08, 0.48, 0.04, 0.12, 0.14, 0.1)
    m.add_box(0.1, 0.44, -0.04, 0.1, 0.12, 0.1)
    return m


def build_sideboard() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.55, 0, 1.6, 1.1, 0.4)  # body
    m.add_box(0, 1.12, 0, 1.65, 0.06, 0.42)  # top
    m.add_box(-0.55, 0.72, 0.12, 0.35, 0.5, 0.2)  # book stack
    m.add_box(0.15, 0.68, 0.12, 0.25, 0.4, 0.18)
    m.add_box(0.55, 0.75, 0.12, 0.22, 0.35, 0.15)
    return m


def build_count_guide() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.12, 0, 0.28, 0.24, 0.06)  # wooden sign board
    m.add_box(0, 0.12, 0.04, 0.22, 0.16, 0.02)  # face
    m.add_box(0, 0.02, 0, 0.04, 0.04, 0.04)  # stand
    return m


def build_lantern() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 0.22, 0, 0.12, 0.28, 0.12)  # body
    m.add_cylinder(0, 0.38, 0, 0.08, 0.06, 6)  # top cap
    m.add_box(0, 0.06, 0, 0.14, 0.04, 0.14)  # base
    return m


def build_curtain() -> FacetedMesh:
    m = FacetedMesh()
    m.add_box(0, 1.0, 0, 0.5, 2.0, 0.06)
    m.add_box(0, 2.05, 0, 0.55, 0.08, 0.1)  # rod
    return m


def build_hand_total_display() -> FacetedMesh:
    """Small easel whiteboard: frame, dark face, rear kickstand."""
    m = FacetedMesh()
    m.add_box(0, 0.011, 0, 0.20, 0.022, 0.14)  # frame
    m.add_box(0, 0.013, 0.002, 0.164, 0.01, 0.109)  # dark face inset
    m.add_box(0, 0.018, -0.048, 0.144, 0.05, 0.048)  # kickstand
    return m


def main() -> None:
    specs = [
        ("dog_dealer.glb", build_dealer_dog, [0.82, 0.68, 0.52, 1.0]),
        ("dog_player_blue.glb", build_bear_player, [0.28, 0.45, 0.82, 1.0]),
        ("dog_player_red.glb", build_husky_player, [0.82, 0.22, 0.2, 1.0]),
        ("dog_player_green.glb", build_bear_player, [0.32, 0.72, 0.38, 1.0]),
        ("round_table.glb", build_round_table, [0.16, 0.42, 0.22, 1.0]),
        ("chip.glb", build_chip, [0.82, 0.18, 0.16, 1.0]),
        ("card_shoe.glb", build_shoe, [0.35, 0.28, 0.2, 1.0]),
        ("overhead_lamp.glb", build_lamp, [0.92, 0.78, 0.45, 1.0]),
        ("discard_tray.glb", build_discard_tray, [0.3, 0.3, 0.32, 1.0]),
        ("potted_plant.glb", build_plant, [0.22, 0.48, 0.24, 1.0]),
        ("sideboard.glb", build_sideboard, [0.45, 0.3, 0.18, 1.0]),
        ("count_guide.glb", build_count_guide, [0.55, 0.38, 0.22, 1.0]),
        ("lantern.glb", build_lantern, [0.85, 0.55, 0.25, 1.0]),
        ("curtain.glb", build_curtain, [0.72, 0.18, 0.18, 1.0]),
        ("hand_total_display.glb", build_hand_total_display, [0.32, 0.22, 0.14, 1.0]),
    ]
    for filename, builder, color in specs:
        mesh = builder()
        out = OUT_DIR / filename
        mesh.to_glb(out, color, filename.replace(".glb", ""))
        print(f"  {out.name}")
    manifest = {"models": [f[0] for f in specs], "style": "ref-a-faceted-low-poly"}
    (OUT_DIR / "models_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Generated {len(specs)} glTF models in {OUT_DIR}")


if __name__ == "__main__":
    main()
