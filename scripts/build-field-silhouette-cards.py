from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IDS = ("ender", "lyra", "ionia", "reson", "aepex")
FRAME_W, FRAME_H = 64, 96
IDLE_FRAMES = 8
IDLE_STRIP_W = FRAME_W * IDLE_FRAMES

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def silhouette_from_idle_strip(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    with Image.open(path) as source:
        if source.format != "PNG":
            raise ValueError(f"{path}: field idle strip must be PNG")
        rgba = source.convert("RGBA")
    if rgba.size != (IDLE_STRIP_W, FRAME_H):
        raise ValueError(f"{path}: expected {IDLE_STRIP_W}x{FRAME_H}, got {rgba.size[0]}x{rgba.size[1]}")
    frame = rgba.crop((0, 0, FRAME_W, FRAME_H))
    alpha = frame.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    if alpha_min == 255:
        raise ValueError(f"{path}: first idle frame is fully opaque")
    if alpha_max == 0 or alpha.getbbox() is None:
        raise ValueError(f"{path}: first idle frame is empty")
    silhouette = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    silhouette.putalpha(alpha.point(lambda value: 255 if value > 0 else 0))
    return silhouette

def build(input_root: Path, output_root: Path, exact_head: str) -> dict:
    if not exact_head or len(exact_head) != 40 or any(c not in "0123456789abcdefABCDEF" for c in exact_head):
        raise ValueError("exact_head must be a full 40-character commit SHA")
    target = output_root / exact_head.lower()
    target.mkdir(parents=True, exist_ok=True)
    records = []
    for character_id in IDS:
        source = input_root / character_id / "field-idle.png"
        silhouette = silhouette_from_idle_strip(source)
        out = target / f"{character_id}.png"
        silhouette.save(out, "PNG", optimize=True)
        records.append({
            "characterId": character_id,
            "source": source.as_posix(),
            "sourceSha256": sha256(source),
            "silhouette": out.as_posix(),
            "silhouetteSha256": sha256(out),
        })
    manifest = {
        "schema": "AETHERWAKE_FIELD_SILHOUETTE_CARDS_V1",
        "exactHead": exact_head.lower(),
        "frame": {"action": "idle", "index": 0, "width": FRAME_W, "height": FRAME_H},
        "cards": records,
        "boundary": "HUMAN_RECOGNITION_INPUT_ONLY_NOT_ADMISSION",
    }
    manifest_path = target / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest

def main() -> int:
    parser = argparse.ArgumentParser(description="Build immutable black-silhouette recognition cards from production field idle strips.")
    parser.add_argument("--exact-head", required=True)
    parser.add_argument("--input-root", default="assets/characters/v1")
    parser.add_argument("--output-root", default="art-staging/field-silhouette-review")
    args = parser.parse_args()
    try:
        manifest = build(Path(args.input_root), Path(args.output_root), args.exact_head)
    except (FileNotFoundError, ValueError) as exc:
        print(f"AETHERWAKE_FIELD_SILHOUETTE_CARDS=BLOCKED: {exc}")
        return 1
    print("AETHERWAKE_FIELD_SILHOUETTE_CARDS=BUILT")
    print(json.dumps(manifest, separators=(",", ":")))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
