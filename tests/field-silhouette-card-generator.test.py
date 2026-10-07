from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "build-field-silhouette-cards.py"
spec = importlib.util.spec_from_file_location("silhouette_cards", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def make_strip(path: Path, seed: int) -> None:
    strip = Image.new("RGBA", (512, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(strip)
    for frame in range(8):
        x = frame * 64
        draw.rectangle((x + 20, 18, x + 43, 90), fill=(50 + seed * 20, 90, 120, 255))
        draw.rectangle((x + 13 + seed, 30, x + 20, 56), fill=(50 + seed * 20, 90, 120, 255))
    strip.save(path)

with TemporaryDirectory() as tmp:
    base = Path(tmp)
    input_root = base / "input"
    output_root = base / "output"
    for index, character_id in enumerate(mod.IDS):
        folder = input_root / character_id
        folder.mkdir(parents=True, exist_ok=True)
        make_strip(folder / "field-idle.png", index)

    head = "a" * 40
    manifest = mod.build(input_root, output_root, head)
    assert manifest["schema"] == "AETHERWAKE_FIELD_SILHOUETTE_CARDS_V1"
    assert manifest["exactHead"] == head
    assert len(manifest["cards"]) == 5
    target = output_root / head
    assert (target / "manifest.json").exists()
    parsed = json.loads((target / "manifest.json").read_text(encoding="utf-8"))
    assert parsed["boundary"] == "HUMAN_RECOGNITION_INPUT_ONLY_NOT_ADMISSION"
    for character_id in mod.IDS:
        card = target / f"{character_id}.png"
        assert card.exists()
        with Image.open(card) as image:
            rgba = image.convert("RGBA")
            assert rgba.size == (64, 96)
            alpha = rgba.getchannel("A")
            assert alpha.getbbox() is not None
            visible = [pixel for pixel in rgba.getdata() if pixel[3] > 0]
            assert visible
            assert all(pixel[:3] == (0, 0, 0) for pixel in visible)

    try:
        mod.build(input_root, output_root, "short")
        raise AssertionError("short head must be rejected")
    except ValueError as exc:
        assert "40-character" in str(exc)

    opaque = input_root / "ender" / "field-idle.png"
    Image.new("RGBA", (512, 96), (50, 50, 50, 255)).save(opaque)
    try:
        mod.silhouette_from_idle_strip(opaque)
        raise AssertionError("opaque strip must be rejected")
    except ValueError as exc:
        assert "fully opaque" in str(exc)

print("Aetherwake field silhouette card generator: PASS")
