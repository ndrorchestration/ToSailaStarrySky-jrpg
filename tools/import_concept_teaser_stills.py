#!/usr/bin/env python3
"""Import the creator-reviewed trailer JPGs from a local ZIP into a repo checkout.

No network, git, publication, or mutation outside --destination.
"""
import argparse
import hashlib
import json
import pathlib
import zipfile

DEST_DEFAULT = "docs/media/concept-teaser-2026-10-27"

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("archive", type=pathlib.Path, help="starry_sky_github_teaser_gallery.zip")
    ap.add_argument("--destination", type=pathlib.Path, default=pathlib.Path(DEST_DEFAULT))
    ap.add_argument("--write", action="store_true", help="Actually copy images into checkout")
    args = ap.parse_args()
    with zipfile.ZipFile(args.archive) as z:
        corrupt = z.testzip()
        if corrupt:
            raise SystemExit(f"Corrupt archive entry: {corrupt}")
        names = set(z.namelist())
        if "manifest.json" not in names:
            raise SystemExit("Missing manifest.json")
        manifest = json.loads(z.read("manifest.json"))
        frames = manifest.get("frames", [])
        if len(frames) != 9:
            raise SystemExit(f"Expected nine frames, found {len(frames)}")
        if len({f["filename"] for f in frames}) != 9:
            raise SystemExit("Duplicate image names")
        for f in frames:
            name = f["filename"]
            if pathlib.PurePosixPath(name).name != name or not name.endswith(".jpg") or name not in names:
                raise SystemExit(f"Invalid or absent frame: {name}")
            digest = hashlib.sha256(z.read(name)).hexdigest()
            if digest != f["sha256"]:
                raise SystemExit(f"Hash mismatch: {name}")
        print("PASS: ZIP CRC and nine JPG hashes verified")
        if not args.write:
            print("Dry run only. Add --write to copy to", args.destination)
            return
        args.destination.mkdir(parents=True, exist_ok=True)
        for f in frames:
            path = args.destination / f["filename"]
            if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() != f["sha256"]:
                raise SystemExit(f"Refusing to replace differing file: {path}")
        for f in frames:
            (args.destination / f["filename"]).write_bytes(z.read(f["filename"]))
        (args.destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        print("Copied nine reviewed stills to", args.destination)
        print("Review and stage with git; this script does not commit or push.")

if __name__ == "__main__":
    main()
