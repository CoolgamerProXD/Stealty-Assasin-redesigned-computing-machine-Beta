#!/usr/bin/env python3
"""Generate small deterministic, original, seamless Tung Chung material maps.

Uses only Python's standard library. These are deliberately subtle albedo maps;
roughness/metallic response is set per material in the Godot scene code.
"""
from __future__ import annotations

import math
import random
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "procedural"
SIZE = 256


def write_png(path: Path, pixels: bytearray) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    rows = bytearray()
    stride = SIZE * 4
    for y in range(SIZE):
        rows.append(0)  # PNG filter: None
        rows.extend(pixels[y * stride : (y + 1) * stride])
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
    payload += chunk(b"IEND", b"")
    path.write_bytes(payload)


def put(pixels: bytearray, x: int, y: int, rgb: tuple[int, int, int]) -> None:
    i = ((y % SIZE) * SIZE + (x % SIZE)) * 4
    pixels[i : i + 4] = bytes((*rgb, 255))


def texture(name: str, painter) -> None:
    pixels = bytearray(SIZE * SIZE * 4)
    painter(pixels)
    # Duplicate the opposing edge texels so filtering across repeated UVs has
    # an exact wrap seam. The generators themselves remain periodic too.
    for y in range(SIZE):
        pixels[(y * SIZE + SIZE - 1) * 4 : (y * SIZE + SIZE) * 4] = pixels[(y * SIZE) * 4 : (y * SIZE + 1) * 4]
    pixels[(SIZE - 1) * SIZE * 4 :] = pixels[: SIZE * 4]
    write_png(ROOT / name, pixels)


def tile_map(pixels: bytearray) -> None:
    tile = 32
    base_set = [(91, 111, 111), (101, 118, 116), (83, 101, 104), (108, 119, 114)]
    for y in range(SIZE):
        for x in range(SIZE):
            gx, gy = x % tile, y % tile
            if gx < 2 or gy < 2:
                base = (34, 45, 48)
            else:
                cell = (x // tile + 3 * (y // tile)) % len(base_set)
                c = base_set[cell]
                grain = math.sin((gx + gy * 0.37) * 0.47) * 1.7 + math.sin((gy - gx * 0.21) * 0.73) * 1.1
                fine = 1.2 * math.sin(2 * math.pi * (x * 17 + y * 31) / SIZE)
                base = tuple(max(0, min(255, int(v + grain + fine))) for v in c)
            put(pixels, x, y, base)


def terrazzo(pixels: bytearray) -> None:
    rng = random.Random(60217)
    specks = [(rng.randrange(SIZE), rng.randrange(SIZE), rng.randrange(1, 4), rng.choice([(-24, -21, -16), (13, 11, 8), (-9, -4, 2)])) for _ in range(360)]
    for y in range(SIZE):
        for x in range(SIZE):
            wave = 2.0 * math.sin(2 * math.pi * x / SIZE) + 1.7 * math.cos(2 * math.pi * y / SIZE) + 1.2 * math.sin(2 * math.pi * (x + y) / SIZE)
            noise = 1.8 * math.sin(2 * math.pi * (x * 19 + y * 13) / SIZE) + 1.2 * math.cos(2 * math.pi * (x * 11 - y * 23) / SIZE)
            c = [int(v + wave + noise) for v in (123, 126, 119)]
            for sx, sy, radius, delta in specks:
                dx = min((x - sx) % SIZE, (sx - x) % SIZE)
                dy = min((y - sy) % SIZE, (sy - y) % SIZE)
                if dx * dx + dy * dy <= radius * radius:
                    c = [v + d for v, d in zip(c, delta)]
            put(pixels, x, y, tuple(max(0, min(255, v)) for v in c))


def brushed_metal(pixels: bytearray) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            row_noise = 3.4 * math.sin(2 * math.pi * y / SIZE * 17) + 1.5 * math.cos(2 * math.pi * y / SIZE * 31)
            grain = 1.6 * math.sin(2 * math.pi * (x * 43 + y * 7) / SIZE)
            n = row_noise + grain + 1.7 * math.sin(2 * math.pi * x / SIZE * 11)
            put(pixels, x, y, tuple(max(0, min(255, int(v + n))) for v in (104, 117, 118)))


def concrete(pixels: bytearray) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            broad = 3.0 * math.sin(2 * math.pi * x / SIZE * 2) + 2.0 * math.cos(2 * math.pi * y / SIZE * 3)
            fine = 2.1 * math.sin(2 * math.pi * (x * 37 + y * 29) / SIZE) + 1.2 * math.cos(2 * math.pi * (x * 13 - y * 47) / SIZE)
            put(pixels, x, y, tuple(max(0, min(255, int(v + broad + fine))) for v in (77, 91, 94)))


def rubber(pixels: bytearray) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            rib = 7 if x % 8 in (0, 1) else 0
            noise = 1.7 * math.sin(2 * math.pi * (x * 19 + y * 23) / SIZE)
            v = max(0, min(255, int(43 + rib + noise)))
            put(pixels, x, y, (v, v + 3, v + 3))


def fabric(pixels: bytearray) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            weave = 9 if (x + y) % 4 == 0 else (-3 if x % 4 == 0 or y % 4 == 0 else 0)
            noise = 1.4 * math.sin(2 * math.pi * (x * 41 + y * 37) / SIZE)
            put(pixels, x, y, tuple(max(0, min(255, int(v + weave + noise))) for v in (43, 75, 78)))


def warm_wood(pixels: bytearray) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            grain = 7 * math.sin(2 * math.pi * x / SIZE * 9 + 1.7 * math.sin(2 * math.pi * y / SIZE * 3))
            fine = 2 * math.sin(2 * math.pi * (x * 35 + y * 9) / SIZE)
            put(pixels, x, y, tuple(max(0, min(255, int(v + grain + fine))) for v in (92, 62, 41)))


if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    texture("tung_chung_tile.png", tile_map)
    texture("tung_chung_terrazzo.png", terrazzo)
    texture("tung_chung_brushed_metal.png", brushed_metal)
    texture("tung_chung_concrete.png", concrete)
    texture("tung_chung_rubber.png", rubber)
    texture("tung_chung_train_fabric.png", fabric)
    texture("tung_chung_warm_wood.png", warm_wood)
    print(f"Generated 7 deterministic seamless material maps in {ROOT}")
