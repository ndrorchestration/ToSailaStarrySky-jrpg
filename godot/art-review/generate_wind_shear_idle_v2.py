#!/usr/bin/env python3
"""Editable, hand-authored Wind Shear idle animation source (Pillow dev tool).

Four 80x92 RGBA sprites, left to right: held / inhale / crest / release.
Source is the original v1 still frame plus individually drawn facet,
fin and light shapes. No raster-slice displacement or inferred gameplay.
Not imported into Godot or installed in production.
"""
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "wind_shear_elemental_v1_atlas.png"
OUTPUT = HERE / "wind_shear_elemental_idle_v2_atlas.png"
W, H = 80, 92
SEA = "#3e8497"
MID = "#26627b"
TEAL = "#57a2b0"
PALE = "#93c8c7"
LIGHT = "#d1e5d7"
MIST = "#39748a"

# Artist-defined local coordinates; none are generated from a transformation
# of the sprite's upper/middle/lower horizontal image bands.
AUTHORED_POSES = [
    {"facet": [], "ribbons": [], "light": [], "motifs": []},
    {"facet": [
        ([(31,15),(36,8),(39,15),(36,22),(31,27)], TEAL),
        ([(50,18),(55,15),(54,26),(47,35),(46,31)], SEA),
        ([(8,57),(15,47),(20,44),(17,51),(13,62)], MID),
        ([(62,21),(68,18),(70,22),(65,27)], SEA),
     ], "ribbons": [
        ([(7,43),(1,43),(4,47),(11,47)], MIST),
        ([(66,50),(73,45),(78,44),(74,48)], TEAL),
     ], "light": [
        ([(32,14),(36,10),(36,15),(33,20)], PALE),
        ([(45,23),(49,20),(47,28),(43,32)], TEAL),
        ([(36,42),(41,36),(44,37),(40,43)], LIGHT),
     ], "motifs": [
        ([(14,80),(16,78),(19,77)], MIST),
        ([(57,65),(61,62)], MID),
     ]},
    {"facet": [
        ([(29,16),(35,6),(40,13),(37,25),(32,28)], SEA),
        ([(45,21),(52,13),(57,18),(53,29),(46,37)], TEAL),
        ([(7,61),(14,49),(18,46),(19,51),(11,68)], SEA),
        ([(59,20),(68,13),(73,20),(68,25),(64,32)], MID),
     ], "ribbons": [
        ([(1,40),(0,43),(6,46),(14,46)], TEAL),
        ([(67,50),(73,45),(79,42),(76,48)], SEA),
     ], "light": [
        ([(32,13),(36,7),(38,14),(34,22)], LIGHT),
        ([(46,21),(52,17),(51,27),(45,33)], PALE),
        ([(36,38),(41,34),(46,36),(42,41)], PALE),
     ], "motifs": [
        ([(10,78),(13,75),(15,72)], MIST),
        ([(62,61),(66,56)], MIST),
     ]},
    {"facet": [
        ([(27,20),(34,9),(38,12),(37,24),(33,27)], MID),
        ([(45,22),(52,13),(59,19),(55,29),(48,38)], SEA),
        ([(6,60),(12,49),(21,43),(19,53),(11,68)], TEAL),
        ([(61,19),(69,16),(72,23),(66,30)], SEA),
     ], "ribbons": [
        ([(7,45),(1,48),(8,50),(17,45)], SEA),
        ([(64,51),(71,49),(76,46),(74,51)], MID),
     ], "light": [
        ([(33,14),(36,11),(35,20),(31,24)], PALE),
        ([(44,22),(50,19),(50,26),(46,33)], TEAL),
        ([(35,41),(40,36),(45,38),(41,44)], PALE),
     ], "motifs": [
        ([(10,73),(13,69),(16,66)], MIST),
        ([(62,64),(67,59)], MID),
     ]},
]

def render() -> Image.Image:
    with Image.open(SOURCE) as file:
        still = file.convert("RGBA").crop((0, 0, W, H))
    atlas = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for index, pose in enumerate(AUTHORED_POSES):
        frame = still.copy()
        painter = ImageDraw.Draw(frame, "RGBA")
        for family in ("facet", "ribbons", "light"):
            for points, color in pose[family]:
                painter.polygon(points, fill=color)
        for points, color in pose["motifs"]:
            painter.line(points, fill=color, width=1)
        atlas.alpha_composite(frame, (index * W, 0))
    return atlas

def main() -> None:
    atlas = render()
    atlas.save(OUTPUT, optimize=True)
    print("Authored Wind Shear idle atlas:", OUTPUT)

if __name__ == "__main__":
    main()
