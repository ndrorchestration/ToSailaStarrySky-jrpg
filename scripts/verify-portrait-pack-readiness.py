from __future__ import annotations
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assets" / "characters" / "v1" / "manifest.json"
IDS = ("ender", "lyra", "ionia")
HELD_IDS = ("reson", "aepex")
EXPRESSIONS = ("neutral", "talk", "concern", "focus", "hurt", "smile")
ATLAS_SIZE = (768, 512)
CELL_SIZE = (256, 256)

def inspect_atlas(path: Path) -> dict:
    if not path.exists():
        return {"exists": False, "valid": False}
    try:
        with Image.open(path) as source:
            source_format = source.format
            source_size = source.size
            rgba = source.convert("RGBA")
    except Exception:
        return {"exists": True, "valid": False, "readable": False}

    alpha = rgba.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    transparent_background = alpha_min < 255 and alpha_max > 0
    cells = []
    for index, expression in enumerate(EXPRESSIONS):
        col = index % 3
        row = index // 3
        crop = rgba.crop((
            col * CELL_SIZE[0],
            row * CELL_SIZE[1],
            (col + 1) * CELL_SIZE[0],
            (row + 1) * CELL_SIZE[1],
        ))
        visible = crop.getchannel("A").getbbox() is not None
        cells.append({"expression": expression, "visible": visible})

    valid = bool(
        source_format == "PNG"
        and source_size == ATLAS_SIZE
        and transparent_background
        and all(cell["visible"] for cell in cells)
    )
    return {
        "exists": True,
        "readable": True,
        "format": source_format,
        "size": list(source_size),
        "alphaExtrema": [alpha_min, alpha_max],
        "transparentBackground": transparent_background,
        "cells": cells,
        "valid": valid,
    }

def inspect_character(manifest: dict, character_id: str) -> dict:
    record = manifest.get("characters", {}).get(character_id)
    if not record:
        return {"id": character_id, "valid": False, "error": "missing manifest record"}
    portrait = record.get("portraitAtlas") or {}
    expressions = tuple(portrait.get("expressions") or ())
    status_ok = record.get("status") in ("portrait-ready", "ready")
    contract_ok = bool(
        portrait.get("width") == ATLAS_SIZE[0]
        and portrait.get("height") == ATLAS_SIZE[1]
        and portrait.get("cellWidth") == CELL_SIZE[0]
        and portrait.get("cellHeight") == CELL_SIZE[1]
        and expressions == EXPRESSIONS
        and isinstance(portrait.get("path"), str)
        and portrait.get("path")
    )
    info = inspect_atlas(ROOT / portrait.get("path", "")) if portrait.get("path") else {"exists": False, "valid": False}
    return {
        "id": character_id,
        "manifestStatus": record.get("status"),
        "statusValid": status_ok,
        "contractValid": contract_ok,
        "path": portrait.get("path"),
        "atlas": info,
        "valid": bool(status_ok and contract_ok and info.get("valid")),
    }

def main() -> int:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    results = [inspect_character(manifest, character_id) for character_id in IDS]
    held = [inspect_character(manifest, character_id) for character_id in HELD_IDS]
    for result in results + held:
        print(json.dumps(result, separators=(",", ":")))
    held_violation = any(result.get("manifestStatus") in ("portrait-ready", "ready") for result in held)
    if any(not result["valid"] for result in results) or held_violation:
        print("AETHERWAKE_PORTRAIT_PACK_READINESS=BLOCKED")
        return 1
    print("AETHERWAKE_PORTRAIT_PACK_READINESS=READY_SCOPED")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
