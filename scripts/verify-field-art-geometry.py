from __future__ import annotations

import argparse
import json
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

def frame_bbox(strip: Image.Image, index: int):
    frame = strip.crop((index * FRAME_W, 0, (index + 1) * FRAME_W, FRAME_H)).convert("RGBA")
    alpha = frame.getchannel("A")
    return alpha.getbbox()

def inspect_strip(path: Path, frames: int):
    if not path.exists():
        return {"exists": False, "valid": False, "path": path.as_posix()}

    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        expected = (FRAME_W * frames, FRAME_H)
        if rgba.size != expected:
            return {
                "exists": True,
                "valid": False,
                "path": path.as_posix(),
                "expected": expected,
                "actual": rgba.size,
                "reason": "dimensions",
            }

        boxes = [frame_bbox(rgba, i) for i in range(frames)]

    if any(box is None for box in boxes):
        return {
            "exists": True,
            "valid": False,
            "path": path.as_posix(),
            "reason": "empty-frame",
            "boxes": boxes,
        }

    foot_lines = [box[3] - 1 for box in boxes]
    top_lines = [box[1] for box in boxes]
    left_clear = [box[0] for box in boxes]
    right_clear = [FRAME_W - box[2] for box in boxes]
    heights = [box[3] - box[1] for box in boxes]

    reasons = []
    if max(foot_lines) - min(foot_lines) > 1:
        reasons.append("foot-line-drift")
    if min(left_clear) < 1 or min(right_clear) < 1:
        reasons.append("horizontal-cell-edge-contact")
    if min(top_lines) < 1:
        reasons.append("top-cell-edge-contact")
    if max(heights) > FRAME_H - 2:
        reasons.append("vertical-clearance")
    if min(heights) < 24:
        reasons.append("implausibly-small-silhouette")

    return {
        "exists": True,
        "valid": not reasons,
        "path": path.as_posix(),
        "footLines": foot_lines,
        "footLineRange": [min(foot_lines), max(foot_lines)],
        "topLineRange": [min(top_lines), max(top_lines)],
        "minLeftClearance": min(left_clear),
        "minRightClearance": min(right_clear),
        "heightRange": [min(heights), max(heights)],
        "reasons": reasons,
    }

def inspect_character(root: Path, character: str):
    strips = {}
    all_foot_lines = []
    for action, count in ACTIONS.items():
        result = inspect_strip(root / character / f"field-{action}.png", count)
        strips[action] = result
        if result.get("valid"):
            all_foot_lines.extend(result["footLines"])

    complete = all(result.get("exists") for result in strips.values())
    strip_valid = complete and all(result.get("valid") for result in strips.values())
    cross_action_footline = (
        bool(all_foot_lines) and max(all_foot_lines) - min(all_foot_lines) <= 1
    )
    valid = strip_valid and cross_action_footline

    return {
        "character": character,
        "complete": complete,
        "stripGeometryValid": strip_valid,
        "crossActionFootLineValid": cross_action_footline if complete else False,
        "valid": valid,
        "strips": strips,
    }

def main() -> int:
    parser = argparse.ArgumentParser(description="Verify Aetherwake field-strip geometry and grounding.")
    parser.add_argument("characters", nargs="*", default=["ender", "ionia"])
    parser.add_argument("--root", default="assets/characters/v1")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()

    root = Path(args.root)
    results = [inspect_character(root, character) for character in args.characters]
    for result in results:
        print(json.dumps(result, separators=(",", ":")))

    incomplete = any(not result["complete"] for result in results)
    invalid = any(result["complete"] and not result["valid"] for result in results)

    if invalid or (args.require_complete and incomplete):
        print("AETHERWAKE_FIELD_ART_GEOMETRY=BLOCKED")
        return 1

    if incomplete:
        print("AETHERWAKE_FIELD_ART_GEOMETRY=NOT_READY")
    else:
        print("AETHERWAKE_FIELD_ART_GEOMETRY=PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
