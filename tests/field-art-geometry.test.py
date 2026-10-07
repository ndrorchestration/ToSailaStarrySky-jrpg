from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "verify-field-art-geometry.py"
spec = importlib.util.spec_from_file_location("field_geometry", SCRIPT)
geometry = importlib.util.module_from_spec(spec)
spec.loader.exec_module(geometry)

def make_strip(path: Path, frames: int, foot: int = 90, drift: bool = False, touch_edge: bool = False):
    strip = Image.new("RGBA", (64 * frames, 96), (0, 0, 0, 0))
    for i in range(frames):
        frame = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
        draw = ImageDraw.Draw(frame)
        local_foot = foot + (2 if drift and i == frames - 1 else 0)
        left = 0 if touch_edge and i == 0 else 20
        draw.rectangle((left, 28, 43, local_foot), fill=(120, 90, 70, 255))
        strip.alpha_composite(frame, (64 * i, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(path)

with TemporaryDirectory() as tmp:
    root = Path(tmp)

    for action, count in geometry.ACTIONS.items():
        make_strip(root / "ender" / f"field-{action}.png", count)
    result = geometry.inspect_character(root, "ender")
    assert result["valid"], result
    assert result["crossActionFootLineValid"]

    make_strip(root / "ender" / "field-walk.png", geometry.ACTIONS["walk"], drift=True)
    result = geometry.inspect_character(root, "ender")
    assert not result["valid"]
    assert "foot-line-drift" in result["strips"]["walk"]["reasons"]

    make_strip(root / "ender" / "field-walk.png", geometry.ACTIONS["walk"], touch_edge=True)
    result = geometry.inspect_character(root, "ender")
    assert not result["valid"]
    assert "horizontal-cell-edge-contact" in result["strips"]["walk"]["reasons"]

    # Cross-action drift can be individually stable but still violate the shared grounded foot line.
    for action, count in geometry.ACTIONS.items():
        make_strip(root / "ionia" / f"field-{action}.png", count, foot=90 if action != "attack" else 88)
    result = geometry.inspect_character(root, "ionia")
    assert result["stripGeometryValid"]
    assert not result["crossActionFootLineValid"]
    assert not result["valid"]

print("Aetherwake field-art geometry validator: PASS")
