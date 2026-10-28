#!/usr/bin/env python3
"""Build a PRIVATE review-only Godot creator motion manifest from genuine authored PNGs.

This does not create artwork, mirror directions, invent motion, or publish anything.
For Ender/Ionia, supply 4 independently drawn directions x 6 poses, each RGBA8
96x144 at <root>/<direction>/00.png through 05.png. Requires Pillow locally.
All SHA-256 hashes are written to root/manifest.json atomically *only after*
every image passes basic provenance-admission structural checks.

Usage: python build_private_creator_motion_manifest.py \
  --root "<private godot art folder>/creator-motion-private/ender" \
  --character ender \
  --source-reference "Creator-approved Five Lights art study, source file ID ..."
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
from tempfile import NamedTemporaryFile

from PIL import Image

DIRECTIONS = ("south", "north", "east", "west")
FRAME_COUNT = 6
FRAME_SIZE = (96, 144)
SAMPLE_STRIDE = 3
MIN_CHANGED_SAMPLES = 20


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def changed_samples(first: Image.Image, second: Image.Image) -> int:
    first_px = first.load()
    second_px = second.load()
    changed = 0
    for y in range(1, FRAME_SIZE[1]-1, SAMPLE_STRIDE):
        for x in range(1, FRAME_SIZE[0]-1, SAMPLE_STRIDE):
            a = first_px[x, y]
            b = second_px[x, y]
            if sum(abs(int(a[i]) - int(b[i])) for i in range(4)) > 31:
                changed += 1
    return changed


def check_image(img: Image.Image, label: str) -> None:
    if img.mode != "RGBA" or img.size != FRAME_SIZE:
        raise ValueError(f"{label}: must be PNG RGBA8, 96x144 pixels")
    alpha = img.getchannel("A")
    a = alpha.load()
    opaque = sum(a[x, y] > 127 for y in range(144) for x in range(96))
    transparent = sum(a[x, y] < 5 for y in range(144) for x in range(96))
    boot = sum(a[x, y] > 204 for y in range(136,144) for x in range(18,79))
    total = 96 * 144
    if not 0.08 * total <= opaque <= 0.74 * total:
        raise ValueError(f"{label}: implausible full-body opacity coverage")
    if transparent < 0.20 * total:
        raise ValueError(f"{label}: PNG must retain transparent background")
    if boot < 4:
        raise ValueError(f"{label}: ground-contact pixels near sole guide missing")


def build(root: Path, character: str, source_reference: str) -> dict:
    if character not in ("ender", "ionia"):
        raise ValueError("Only the creator-reviewed Ender and Ionia source contracts are supported")
    if len(source_reference.strip()) < 12:
        raise ValueError("Use a specific authored visual-bible/source-art reference")
    all_hashes: set[str] = set()
    directions: dict[str, list[str]] = {}
    firsts: dict[str, Image.Image] = {}
    for face in DIRECTIONS:
        hashes = []
        previous = None
        for index in range(FRAME_COUNT):
            path = root / face / f"{index:02d}.png"
            if not path.is_file():
                raise FileNotFoundError(f"Missing genuinely authored {face} frame: {path}")
            with Image.open(path) as source:
                source.load()
                image = source.copy()
            check_image(image, f"{face}/{index:02d}")
            source_hash = digest(path)
            if source_hash in all_hashes:
                raise ValueError(f"Duplicate exact frame detected at {face}/{index:02d}")
            if previous is not None and changed_samples(previous, image) < MIN_CHANGED_SAMPLES:
                raise ValueError(f"Near-identical adjacent poses {face}/{index:02d}; genuine gait required")
            if index == 0:
                for old_face, earlier in firsts.items():
                    if changed_samples(earlier, image) < MIN_CHANGED_SAMPLES:
                        raise ValueError(f"{face} is too similar to {old_face}; distinct authored views required")
                firsts[face] = image
            hashes.append(source_hash)
            all_hashes.add(source_hash)
            previous = image
        directions[face] = hashes
    if len(all_hashes) != 24:
        raise AssertionError("Incomplete 24-frame package")
    return {
        "schema_version": 1,
        "character": character,
        "intent": "review_only",
        "source_reference": source_reference.strip(),
        "directions": directions,
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True, type=Path, help="PRIVATE local motion asset root")
    p.add_argument("--character", choices=["ender","ionia"], required=True)
    p.add_argument("--source-reference", required=True)
    p.add_argument("--overwrite", action="store_true", help="Explicitly replace an old manifest")
    args = p.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        raise SystemExit("Private local frame directory does not exist")
    dest = root / "manifest.json"
    if dest.exists() and not args.overwrite:
        raise SystemExit("Manifest exists: use --overwrite after reviewing any changed frames")
    data = build(root, args.character, args.source_reference)
    serial = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    with NamedTemporaryFile("w", encoding="utf-8", dir=root, prefix=".motion-review-",
                            suffix=".tmp", delete=False) as temporary:
        temp = Path(temporary.name)
        temporary.write(serial)
        temporary.flush()
        os.fsync(temporary.fileno())
    try:
        temp.replace(dest)
    finally:
        temp.unlink(missing_ok=True)
    print(f"TSTSS_PRIVATE_CREATOR_MOTION_MANIFEST_PASS:{args.character}:24_frames=true review_only=true")
    print(f"Manifest: {dest}  SHA-256: {digest(dest)}")
    print("Structural verification only; author/creator quality approval is NOT implied.")


if __name__ == "__main__":
    main()
