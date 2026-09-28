from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ("ender","ionia","lyra","reson","aepex")
FRAME_W, FRAME_H = 64, 96
ACTIONS = {"idle":8,"walk":6,"talk":4,"focus":6,"attack":8}

def outlined(sprite: Image.Image) -> Image.Image:
    alpha = sprite.getchannel("A")
    dilated = alpha.filter(ImageFilter.MaxFilter(3))
    outline_alpha = ImageChops.subtract(dilated, alpha)
    outline = Image.new("RGBA", sprite.size, (19,24,27,0))
    outline.putalpha(outline_alpha.point(lambda v: min(210, v)))
    out = Image.new("RGBA", sprite.size, (0,0,0,0))
    out.alpha_composite(outline)
    out.alpha_composite(sprite)
    return out

def base_frames(character: str):
    src = ROOT / "assets" / "characters" / "v1" / character / "field-idle-walk-candidate.png"
    image = Image.open(src).convert("RGBA")
    if image.size != (56,36):
        raise ValueError(f"{src}: expected 56x36, got {image.size}")
    frames=[]
    for i in range(2):
        cell=image.crop((i*28,0,(i+1)*28,36))
        cell=cell.resize((56,72), Image.Resampling.NEAREST)
        frames.append(outlined(cell))
    return frames

def compose(base: Image.Image, xoff=0, yoff=0):
    frame=Image.new("RGBA",(FRAME_W,FRAME_H),(0,0,0,0))
    x=(FRAME_W-base.width)//2 + xoff
    y=FRAME_H-base.height-4 + yoff
    frame.alpha_composite(base,(x,y))
    return frame

def action_frames(character: str, action: str):
    a,b=base_frames(character)
    if action=="idle":
        seq=[(a,0,0),(a,0,0),(a,0,-1),(a,0,-1),(a,0,0),(a,0,0),(a,0,1),(a,0,0)]
    elif action=="walk":
        seq=[(a,0,0),(b,1,0),(a,0,-1),(b,-1,0),(a,0,0),(b,1,0)]
    elif action=="talk":
        seq=[(a,0,0),(a,0,-1),(a,1,0),(a,0,0)]
    elif action=="focus":
        seq=[(a,0,0),(a,1,0),(b,1,-1),(a,1,-1),(a,0,0),(a,0,0)]
    elif action=="attack":
        seq=[(a,0,0),(b,2,0),(b,4,-1),(b,7,-1),(b,5,0),(a,3,0),(a,1,0),(a,0,0)]
    else:
        raise KeyError(action)
    return [compose(*item) for item in seq]

def main():
    for character in CHARACTERS:
        outdir=ROOT/"assets"/"characters"/"v1"/character
        for action,count in ACTIONS.items():
            frames=action_frames(character,action)
            assert len(frames)==count
            strip=Image.new("RGBA",(FRAME_W*count,FRAME_H),(0,0,0,0))
            for i,frame in enumerate(frames):
                strip.alpha_composite(frame,(i*FRAME_W,0))
            target=outdir/f"provisional-{action}.png"
            strip.save(target,"PNG",optimize=True)
            print(target.relative_to(ROOT).as_posix(), strip.size)
    print("AETHERWAKE_PROVISIONAL_FIELD_PACK=BUILT")

if __name__=="__main__":
    main()
