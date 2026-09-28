from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ACTIONS = {"idle":8,"walk":6,"talk":4,"focus":6,"attack":8}
for character in ("ender","ionia","lyra","reson","aepex"):
    for action,count in ACTIONS.items():
        path = ROOT / "assets" / "characters" / "v1" / character / f"provisional-{action}.png"
        assert path.exists(), f"missing {path}"
        image = Image.open(path).convert("RGBA")
        assert image.size == (64*count,96), f"{path}: {image.size}"
        alpha = image.getchannel("A")
        assert alpha.getbbox() is not None, f"{path}: fully transparent"
print("Aetherwake provisional 64x96 field-strip contract: PASS")
