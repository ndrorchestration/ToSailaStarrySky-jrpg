from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "pack-field-art.py"
spec = importlib.util.spec_from_file_location("packer", SCRIPT)
packer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packer)

def transparent_frame(seed: int) -> Image.Image:
    image = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle((20, 18, 43, 91), fill=(seed * 10 % 255, 80, 120, 255))
    return image

with TemporaryDirectory() as tmp:
    base = Path(tmp)
    staging = base / "staging"
    output = base / "output"
    for action, count in packer.ACTIONS.items():
        folder = staging / "ender" / action
        folder.mkdir(parents=True, exist_ok=True)
        for i in range(1, count + 1):
            transparent_frame(i).save(folder / f"frame-{i:02d}.png")

    targets = packer.pack_character(staging, "ender", output)
    assert len(targets) == 5
    for action, count in packer.ACTIONS.items():
        target = output / "ender" / f"field-{action}.png"
        assert target.exists(), target
        with Image.open(target) as image:
            assert image.size == (64 * count, 96), (action, image.size)
            assert image.mode == "RGBA"
            alpha_min, alpha_max = image.getchannel("A").getextrema()
            assert alpha_min < 255 and alpha_max > 0, (action, alpha_min, alpha_max)

    opaque = base / "opaque.png"
    Image.new("RGBA", (64, 96), (80, 80, 80, 255)).save(opaque)
    try:
        packer.load_frame(opaque)
        raise AssertionError("fully opaque production frame must be rejected")
    except ValueError as exc:
        assert "fully opaque" in str(exc)

    invisible = base / "invisible.png"
    Image.new("RGBA", (64, 96), (0, 0, 0, 0)).save(invisible)
    try:
        packer.load_frame(invisible)
        raise AssertionError("fully transparent production frame must be rejected")
    except ValueError as exc:
        assert "fully transparent" in str(exc)

print("Aetherwake field-art packer: PASS")
