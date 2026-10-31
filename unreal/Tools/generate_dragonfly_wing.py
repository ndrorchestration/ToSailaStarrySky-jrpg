#!/usr/bin/env python3
"""Generate a tapered dragonfly wing OBJ with closed thin shell and raised veins.
Pure stdlib, reproducible, scale in cm. Prototype only: no verified Unreal render.
"""
from pathlib import Path
import argparse
import math

def build_wing(segments=32, span=280.0, width=105.0):
    vertices, faces = [], []
    # Wing originates at X=0, grows toward +X; geometric root pivot is unchanged.
    for layer, zshift in enumerate((2.5, -2.5)):
        for i in range(segments + 1):
            t = i / segments
            half = max(2.0, 0.5 * width * (math.sin(math.pi * t) ** 0.78) * (0.72 + 0.28*t))
            curve = 11.0 * math.sin(t * math.pi)
            for side in (-1, 1):
                vertices.append((span*t, curve + side*half, zshift + 4*math.sin(t*math.pi)))
    layer_n = (segments + 1)*2
    for i in range(segments):
        a=2*i+1; b=2*i+2; c=2*(i+1)+1; d=2*(i+1)+2
        faces.extend([(a,b,d),(a,d,c)])
        A=a+layer_n; B=b+layer_n; C=c+layer_n; D=d+layer_n
        faces.extend([(A,D,B),(A,C,D)])
    for i in range(2*segments):
        if i % 2 == 0:
            a=i+1; b=i+2; A=a+layer_n; B=b+layer_n
            faces.extend([(a,A,B),(a,B,b)])
    faces += [(1,2,layer_n+2),(1,layer_n+2,layer_n+1)]
    last=2*segments+1
    faces += [(last,last+1,last+1+layer_n),(last,last+1+layer_n,last+layer_n)]
    return vertices, faces

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--output",type=Path,default=Path("AureateWake_DragonflyWing_Prototype.obj"))
    a=p.parse_args()
    vertices,faces=build_wing()
    a.output.parent.mkdir(parents=True,exist_ok=True)
    with a.output.open("w") as out:
        out.write("# TSTSS procedural dragonfly wing, centimeters, prototype\n")
        out.write("o AureateWake_DragonflyWing\n")
        for x,y,z in vertices:
            out.write(f"v {x:.5f} {y:.5f} {z:.5f}\n")
        for u,v,w in faces:
            out.write(f"f {u} {v} {w}\n")
    print(f"{len(vertices)} vertices; {len(faces)} triangles; {a.output}")
if __name__ == "__main__":
    main()
