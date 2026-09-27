from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "pack-field-art.py"
spec = importlib.util.spec_from_file_location("packer", SCRIPT)
packer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packer)

with TemporaryDirectory() as tmp:
    base = Path(tmp)
    staging = base / "staging"
    output = base / "output"
    for action, count in packer.ACTIONS.items():
        folder = staging / "ender" / action
        folder.mkdir(parents=True, exist_ok=True)
        for i in range(1, count + 1):
            img = Image.new("RGBA", (64, 96), (i * 10 % 255, 80, 120, 255))
            img.save(folder / f"frame-{i:02d}.png")

    targets = packer.pack_character(staging, "ender", output)
    assert len(targets) == 5
    for action, count in packer.ACTIONS.items():
        target = output / "ender" / f"field-{action}.png"
        assert target.exists(), target
        with Image.open(target) as image:
            assert image.size == (64 * count, 96), (action, image.size)
            assert image.mode == "RGBA"

print("Aetherwake field-art packer: PASS")
