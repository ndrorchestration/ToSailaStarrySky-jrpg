#!/usr/bin/env python3
"""Regenerate original pixel-authored Harmonic Shear Elemental atlas.

Development-only art-source tool (Pillow required). Does not execute as part
of the game. Produces four 80x92 RGBA poses in this directory, 320x92 total.
Avoid regenerating while reviewing an exact-head screenshot without recording
a new asset hash and admitting it through native Godot import QA.
"""
from pathlib import Path
from PIL import Image, ImageDraw

FRAME_W, FRAME_H = 80, 92
OUT = Path(__file__).resolve().parent / "wind_shear_elemental_v1_atlas.png"
P = {
    "void":"#10283f", "ink":"#1d3448", "deep":"#27415b",
    "mid":"#26627b", "sea":"#3e8497", "teal":"#57a2b0",
    "pale":"#93c8c7", "light":"#d1e5d7", "shine":"#f5eac1",
    "amber":"#f2b76d", "hot":"#e87d59", "shade":"#193147",
    "mist":"#39748a",
}

def frame(mode):
    im = Image.new("RGBA", (FRAME_W, FRAME_H))
    d = ImageDraw.Draw(im)
    def poly(coords, color): d.polygon(coords, fill=P[color])
    def line(coords, color, width=1): d.line(coords, fill=P[color], width=width)
    def rect(bounds, color): d.rectangle(bounds, fill=P[color])

    if mode == 3:
        fragments = [
            ([(7,27),(15,12),(20,20),(16,28)],"mid"),
            ([(28,7),(41,2),(40,15),(33,22)],"sea"),
            ([(57,20),(70,10),(66,29),(59,32)],"teal"),
            ([(14,62),(26,55),(22,70),(9,76)],"sea"),
            ([(47,66),(55,52),(68,69),(54,80)],"mid"),
            ([(34,47),(40,42),(42,54),(32,57)],"light"),
            ([(70,50),(77,47),(72,58)],"pale"),
        ]
        for pts,c in fragments: poly(pts,c)
        for x,y in [(5,44),(18,7),(72,37),(27,82),(53,9),(39,80),(62,86),(13,88)]:
            rect((x,y,x+2,y+2),"mist")
        return im

    poly([(7,62),(0,59),(4,49),(15,43),(17,31),(25,29),(21,46),(26,53),(20,68),(12,73)],"shade")
    poly([(9,60),(5,57),(9,49),(21,40),(20,48),(23,53),(15,64)],"mid")
    poly([(10,50),(19,42),(18,49),(12,54)],"teal")
    poly([(57,16),(68,11),(76,19),(72,30),(64,32),(65,42),(58,47),(52,39),(60,28)],"ink")
    poly([(60,19),(68,15),(72,21),(67,30),(62,29),(62,38),(56,38)],"sea")
    poly([(65,18),(70,19),(69,23),(65,27)],"pale")
    poly([(22,22),(27,13),(37,2),(44,8),(45,23),(39,33),(29,36)],"void")
    poly([(25,24),(31,13),(36,7),(42,12),(41,26),(33,32)],"mid")
    poly([(30,18),(36,10),(38,14),(36,25),(31,28)],"pale")
    poly([(37,25),(51,9),(60,14),(60,26),(54,35),(61,47),(52,60),(50,72),(43,88),(34,80),(30,65),(25,51),(27,37)],"ink")
    poly([(38,28),(52,14),(57,18),(55,30),(50,39),(56,47),(47,58),(46,70),(41,79),(34,70),(29,52),(32,40)],"mid")
    poly([(45,19),(52,16),(50,29),(42,37),(38,35)],"teal")
    poly([(33,43),(41,32),(52,36),(56,47),(47,53),(42,63),(35,57),(28,53)],"sea")
    poly([(37,39),(43,34),(48,35),(43,43),(40,48),(34,47)],"pale")
    poly([(31,59),(40,66),(44,79),(42,86),(35,79)],"sea")
    poly([(39,69),(43,76),(42,81)],"light")
    poly([(37,44),(44,38),(49,43),(48,54),(40,62),(35,56)],"void")
    if mode == 1:
        poly([(40,43),(45,40),(46,45),(43,50),(39,51)],"shine")
        poly([(39,53),(43,52),(40,58),(37,56)],"amber")
        line([(32,39),(28,40),(27,53),(31,54)],"amber",2)
        line([(53,40),(57,41),(57,54),(52,55)],"amber",2)
    else:
        poly([(40,43),(44,41),(44,47),(41,50),(39,51)],"light")
        poly([(42,52),(45,50),(42,55),(39,57)],"pale")
    line([(28,37),(31,31),(37,27)],"teal")
    line([(53,32),(50,37),(54,45)],"pale")
    rect((34,15,36,16),"light")
    rect((13,53,14,57),"sea")
    for x,y in [(9,26),(15,31),(8,76),(64,52),(70,48),(20,82),(58,68),(25,8)]:
        rect((x,y,x+1,y+1),"mist")
    if mode == 2:
        poly([(13,45),(4,40),(0,32),(13,35),(27,35),(35,39),(23,43)],"sea")
        poly([(10,43),(1,42),(4,47),(17,50),(30,45)],"pale")
        poly([(56,45),(71,33),(79,31),(73,40),(62,52),(58,57)],"mid")
        line([(2,24),(18,20),(35,19)],"amber",2)
        line([(5,67),(20,61),(28,58)],"hot",2)
        line([(63,61),(77,56)],"amber",2)
        rect((76,54,79,55),"shine")
        rect((3,20,6,22),"amber")
    return im

def main():
    atlas = Image.new("RGBA", (FRAME_W * 4, FRAME_H))
    for n in range(4):
        atlas.alpha_composite(frame(n), (FRAME_W * n, 0))
    atlas.save(OUT, optimize=True)
    print("Original Wind Shear atlas:", OUT)

if __name__ == "__main__":
    main()
