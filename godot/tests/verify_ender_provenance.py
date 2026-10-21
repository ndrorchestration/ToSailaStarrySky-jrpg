#!/usr/bin/env python3
"""Fail-closed binary provenance check for approved Ender proof (no artistic judgment)."""
from __future__ import annotations

import hashlib
from pathlib import Path
import struct
import sys

HERE = Path(__file__).resolve().parents[1]
EXPECTED = (
    "ender-approved-reference.png",
    "619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd",
    1352358,
    (1024, 1536, 8, 6),
)
WALK = ("ender-walk-candidate.png", (384, 96, 8, 6))


def png_header(data: bytes) -> tuple[int, int, int, int]:
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Not a PNG IHDR")
    return struct.unpack(">IIBB", data[16:26])


def main() -> int:
    filename, sha, length, expected = EXPECTED
    path = HERE / "art-review" / filename
    if not path.is_file():
        print("ENDER_PROVENANCE_FAIL: approved source missing", file=sys.stderr)
        return 1
    data = path.read_bytes()
    actual_hash = hashlib.sha256(data).hexdigest()
    if actual_hash != sha or len(data) != length or png_header(data) != expected:
        print("ENDER_PROVENANCE_FAIL: approved source hash/size/format mismatch", file=sys.stderr)
        return 2
    walk_path = HERE / "art-review" / WALK[0]
    if not walk_path.is_file() or png_header(walk_path.read_bytes()) != WALK[1]:
        print("ENDER_PROVENANCE_FAIL: provisional side-walk sheet geometry mismatch", file=sys.stderr)
        return 3
    print("ENDER_PROVENANCE_PASS: approved appearance exact SHA-256, dimensions, RGBA")
    print("ENDER_DIRECTIONAL_POSES=NOT_AUTHORED; ENDER_FIELD_ART=NOT_READY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
