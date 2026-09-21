#!/usr/bin/env python3
"""Generate the original deterministic Aurora Bloom wallpaper using stdlib only."""
from __future__ import annotations

import math
import pathlib
import struct
import zlib

WIDTH, HEIGHT = 1920, 1080
OUT = pathlib.Path(__file__).resolve().parents[1] / "wallpapers" / "aurora-bloom.png"


def chunk(kind: bytes, payload: bytes) -> bytes:
    body = kind + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def pixel(x: int, y: int) -> tuple[int, int, int]:
    u, v = x / (WIDTH - 1), y / (HEIGHT - 1)
    # Ink-blue base with a subtle vertical lift.
    r, g, b = 6 + 9 * (1 - v), 8 + 8 * (1 - v), 23 + 20 * (1 - v)

    # Broad, overlapping colored light fields.
    for cx, cy, radius, color, strength in (
        (0.78, 0.22, 0.42, (91, 48, 190), 0.92),
        (0.18, 0.78, 0.38, (10, 139, 176), 0.80),
        (0.48, 0.56, 0.32, (183, 42, 132), 0.58),
        (0.96, 0.92, 0.34, (33, 79, 170), 0.46),
    ):
        d2 = ((u - cx) / radius) ** 2 + ((v - cy) / radius) ** 2
        glow = math.exp(-2.8 * d2) * strength
        r += color[0] * glow
        g += color[1] * glow
        b += color[2] * glow

    # Three translucent aurora ribbons crossing the composition.
    for phase, center, width, color, energy in (
        (0.0, 0.42, 0.050, (121, 72, 255), 0.72),
        (1.7, 0.56, 0.036, (255, 75, 184), 0.46),
        (3.8, 0.70, 0.044, (36, 220, 224), 0.42),
    ):
        ridge = center + 0.115 * math.sin(u * 5.4 + phase) + 0.035 * math.sin(u * 14.0 - phase)
        ribbon = math.exp(-((v - ridge) / width) ** 2) * energy
        r += color[0] * ribbon
        g += color[1] * ribbon
        b += color[2] * ribbon

    # Sparse pin-light stars, generated from coordinates (no external assets).
    h = ((x * 73856093) ^ (y * 19349663) ^ 0xA17A5) & 0xFFFFFFFF
    star = 0
    if h % 12007 == 0:
        star = 125 + (h >> 8) % 105
    elif h % 4001 == 0:
        star = 45 + (h >> 10) % 50
    r += star * 0.72
    g += star * 0.80
    b += star

    # Fine deterministic grain and a cinematic vignette.
    grain = (((h >> 16) & 255) / 255.0 - 0.5) * 5.2
    vignette = max(0.56, 1.0 - 0.48 * ((u - 0.5) ** 2 + (v - 0.5) ** 2))
    return clamp((r + grain) * vignette), clamp((g + grain) * vignette), clamp((b + grain) * vignette)


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray()
    for y in range(HEIGHT):
        raw.append(0)  # PNG filter: None
        for x in range(WIDTH):
            raw.extend(pixel(x, y))
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0))
    png += chunk(b"tEXt", b"Title\x00Aurora Bloom - original procedural artwork")
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    OUT.write_bytes(png)
    print(f"generated {OUT} ({WIDTH}x{HEIGHT}, {len(png)} bytes)")


if __name__ == "__main__":
    main()
