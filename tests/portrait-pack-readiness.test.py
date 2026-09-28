from pathlib import Path
import importlib.util
import json
from tempfile import TemporaryDirectory
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "verify-portrait-pack-readiness.py"
spec = importlib.util.spec_from_file_location("portrait_readiness", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

manifest = json.loads((ROOT / "assets" / "characters" / "v1" / "manifest.json").read_text(encoding="utf-8"))
for character_id in mod.IDS:
    result = mod.inspect_character(manifest, character_id)
    assert result["valid"], result
for character_id in mod.HELD_IDS:
    result = mod.inspect_character(manifest, character_id)
    assert result["manifestStatus"] not in ("portrait-ready", "ready"), result
    assert not result["statusValid"], result

with TemporaryDirectory() as tmp:
    base = Path(tmp)
    good = base / "good.png"
    image = Image.new("RGBA", mod.ATLAS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for index in range(6):
        col = index % 3
        row = index // 3
        x0 = col * 256 + 48
        y0 = row * 256 + 36
        draw.rectangle((x0, y0, x0 + 150, y0 + 180), fill=(40 + index * 20, 80, 120, 255))
    image.save(good)
    good_result = mod.inspect_atlas(good)
    assert good_result["valid"], good_result

    opaque = base / "opaque.png"
    Image.new("RGBA", mod.ATLAS_SIZE, (90, 90, 90, 255)).save(opaque)
    opaque_result = mod.inspect_atlas(opaque)
    assert not opaque_result["valid"]
    assert not opaque_result["transparentBackground"]

    empty_cell = base / "empty-cell.png"
    image = Image.new("RGBA", mod.ATLAS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for index in range(5):
        col = index % 3
        row = index // 3
        draw.rectangle((col * 256 + 40, row * 256 + 40, col * 256 + 180, row * 256 + 190), fill=(120, 90, 70, 255))
    image.save(empty_cell)
    empty_result = mod.inspect_atlas(empty_cell)
    assert not empty_result["valid"]
    assert empty_result["cells"][-1]["visible"] is False

print("Aetherwake portrait-pack readiness verifier: PASS")
