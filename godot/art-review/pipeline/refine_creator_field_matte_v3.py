#!/usr/bin/env python3
"""Private-source, reproducible alpha finishing for the *creator's* First Wake figures.

Read two user-owned original 1-pose PNG extractions from --input, verify SHA-256,
emit refined stills to --output. Never generates anatomy, alternate directions,
animation phases or uploads assets. Requires numpy + opencv-python-headless;
not a gameplay/runtime dependency. See the associated art review documentation.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import cv2
import numpy as np

SOURCES = {
    "ionia": ("ionia_field_static_review.png", "a37f1cde79fbee7b70d2f25ad9b1625fac1c8340f9c162b54f9333491d203f84", 205),
    "ender": ("ender_field_static_review.png", "7d95d72e6d8953b0db594511cb2705947925363025e737d2710bc247ee43ec4b", 199),
}
V3_SHA = {
    "ionia": "37d7cc3c852bbf5497e94e38502fb8aa35512f5492cf9a12abdf0eff49b11c49",
    "ender": "8127ec4b87086027887c145fbde72704c61ad1d20d44395b111b3145d98660ca",
}

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def refine_one(identity: str, source: Path) -> np.ndarray:
    name, expected, width = SOURCES[identity]
    if source.name != name or digest(source) != expected:
        raise ValueError("Source custody mismatch for " + identity)
    rgba = cv2.imread(str(source), cv2.IMREAD_UNCHANGED)
    if rgba is None or rgba.shape != (535, width, 4) or set(np.unique(rgba[:, :, 3])) != {0, 255}:
        raise ValueError("Unexpected original alpha or dimensions: " + identity)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    core = cv2.erode(rgba[:, :, 3], kernel, iterations=1)
    alpha2 = cv2.GaussianBlur(core, (3, 3), sigmaX=0.7)
    rgb2 = cv2.inpaint(rgba[:, :, :3], (core == 0).astype(np.uint8) * 255,
                       inpaintRadius=3, flags=cv2.INPAINT_TELEA)
    stage2 = np.dstack((rgb2, alpha2)).astype(np.uint8)

    bgr = stage2[:, :, :3].astype(np.float32)
    distance = np.sqrt(np.sum((bgr - np.array([224., 235., 240.])) ** 2, axis=2))
    paper = (distance < 29) & (bgr[:, :, 0] > 198) & (bgr[:, :, 1] > 209) & (bgr[:, :, 2] > 217)
    mask = np.zeros(stage2.shape[:2], np.uint8)
    if identity == "ender":
        regions = [
            [(78, 38), (107, 30), (105, 91), (78, 95)],
            [(38, 185), (75, 184), (76, 273), (42, 276)],
            [(75, 306), (153, 315), (153, 519), (63, 519)],
            [(0, 510), (width-1, 510), (width-1, 534), (0, 534)],
        ]
    else:
        regions = [
            [(36, 182), (67, 180), (72, 274), (34, 260)],
            [(123, 182), (167, 183), (174, 284), (129, 285)],
            [(88, 391), (165, 395), (169, 520), (80, 520)],
            [(0, 520), (width-1, 520), (width-1, 534), (0, 534)],
        ]
    for region in regions:
        cv2.fillPoly(mask, [np.array(region, np.int32)], 255)
    paper_to_erase = np.where(paper & (mask > 0) & (stage2[:, :, 3] > 0), 255, 0).astype(np.uint8)
    erase = cv2.dilate(paper_to_erase, np.ones((3, 3), np.uint8), iterations=1)
    clean_alpha = stage2[:, :, 3].copy()
    clean_alpha[erase > 0] = 0
    clean_alpha = cv2.GaussianBlur(clean_alpha, (3, 3), sigmaX=0.60)
    clean_rgb = cv2.inpaint(stage2[:, :, :3],
                           (clean_alpha < 245).astype(np.uint8) * 255,
                           inpaintRadius=2, flags=cv2.INPAINT_TELEA)
    result = np.dstack((clean_rgb, clean_alpha)).astype(np.uint8)
    if len(np.unique(result[:, :, 3])) < 11:
        raise ValueError("Refined source has no antialiased alpha: " + identity)
    return result

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True, help="Private v1 source directory")
    parser.add_argument("--output", type=Path, required=True, help="Private output directory")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for identity, (name, _, _) in SOURCES.items():
        original = args.input / name
        result = refine_one(identity, original)
        output = args.output / f"{identity}_field_matte_v3.png"
        if not cv2.imwrite(str(output), result):
            raise IOError("Could not write local PNG: " + str(output))
        got = digest(output)
        if got != V3_SHA[identity]:
            raise ValueError("Output not reproducible; check OpenCV/Numpy versions: " + identity + " " + got)
        print(f"TSTSS_MATTE_V3_SOURCE_PASS:{identity}:sha256={got}")
    print("TSTSS_MATTE_V3_BOTH_PASS:2_private_stills=true animated_frames=0")

if __name__ == "__main__":
    main()
