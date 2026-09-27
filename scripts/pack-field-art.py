from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image

FRAME_W = 64
FRAME_H = 96
ACTIONS = {
    "idle": 8,
    "walk": 6,
    "talk": 4,
    "focus": 6,
    "attack": 8,
}

def load_frame(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    image = Image.open(path).convert("RGBA")
    if image.size != (FRAME_W, FRAME_H):
        raise ValueError(f"{path}: expected {FRAME_W}x{FRAME_H}, got {image.size[0]}x{image.size[1]}")
    return image

def pack_action(root: Path, character: str, action: str, count: int, output_root: Path) -> Path:
    frame_dir = root / character / action
    frames = [load_frame(frame_dir / f"frame-{i:02d}.png") for i in range(1, count + 1)]
    strip = Image.new("RGBA", (FRAME_W * count, FRAME_H), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (FRAME_W * index, 0))
    target_dir = output_root / character
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"field-{action}.png"
    strip.save(target, "PNG", optimize=True)
    return target

def pack_character(root: Path, character: str, output_root: Path) -> list[Path]:
    return [
        pack_action(root, character, action, count, output_root)
        for action, count in ACTIONS.items()
    ]

def main() -> int:
    parser = argparse.ArgumentParser(description="Pack Aetherwake 64x96 field frames into runtime strips.")
    parser.add_argument("character", choices=("ender", "ionia"))
    parser.add_argument("--staging", default="art-staging/field")
    parser.add_argument("--output", default="assets/characters/v1")
    args = parser.parse_args()

    root = Path(args.staging)
    output_root = Path(args.output)
    try:
        targets = pack_character(root, args.character, output_root)
    except (FileNotFoundError, ValueError) as exc:
        print(f"AETHERWAKE_FIELD_PACK=BLOCKED: {exc}")
        return 1

    for target in targets:
        print(target.as_posix())
    print(f"AETHERWAKE_FIELD_PACK=PACKED:{args.character}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
