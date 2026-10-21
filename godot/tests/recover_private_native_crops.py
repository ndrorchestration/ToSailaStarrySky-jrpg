#!/usr/bin/env python3
"""Recover lossless 1x native Godot character crops from private Actions job logs.

Also recovers original whole-scene 960x640 PNGs when the workflow emits -full labels.
SHA-256 and PNG byte dimensions are verified independently on replay.
Requires read access to private repo logs. No network transmission occurs here.
"""
import argparse
import base64
import hashlib
from pathlib import Path
import re
import sys

START = re.compile(r'AW_NATIVE_CROP_BEGIN:([a-z0-9-]+):(\d+)x(\d+):([a-f0-9]{64}):([a-f0-9]{64}):(\d+)')
DATA = re.compile(r'AW_NATIVE_CROP_DATA:([a-z0-9-]+):(\d+):([A-Za-z0-9+/=]+)')
END = re.compile(r'AW_NATIVE_CROP_END:([a-z0-9-]+)')


def recover(logs: str, destination: Path) -> dict:
    groups: dict[str, dict] = {}
    active = None
    for line in logs.splitlines():
        m = START.search(line)
        if m:
            label, width, height, sha, source_sha, length = m.groups()
            if active is not None or label in groups:
                raise ValueError('nested or duplicate crop ' + label)
            active = label
            groups[label] = dict(width=int(width), height=int(height), sha=sha,
                                 source_sha=source_sha, length=int(length), parts=[], done=False)
            continue
        m = DATA.search(line)
        if m:
            label, idx, chunk = m.groups()
            if active != label:
                raise ValueError('orphan/cross-crop chunk: ' + label)
            chunks = groups[label]['parts']
            if int(idx) != len(chunks):
                raise ValueError('missing/reordered data chunks in ' + label)
            chunks.append(chunk)
            continue
        m = END.search(line)
        if m:
            label = m.group(1)
            if active != label or groups[label]['done']:
                raise ValueError('unexpected crop end: ' + label)
            groups[label]['done'] = True
            active = None
    if active or not groups or any(not x['done'] for x in groups.values()):
        raise ValueError('no complete native crops present')
    destination.mkdir(parents=True, exist_ok=True)
    receipts = {}
    for label, m in groups.items():
        raw = base64.b64decode(''.join(m['parts']), validate=True)
        if len(raw) != m['length'] or hashlib.sha256(raw).hexdigest() != m['sha']:
            raise ValueError('crop length/hash mismatch: ' + label)
        if raw[:16] != b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR':
            raise ValueError('not a PNG IHDR: ' + label)
        width = int.from_bytes(raw[16:20], 'big')
        height = int.from_bytes(raw[20:24], 'big')
        if (width, height) != (m['width'], m['height']):
            raise ValueError('crop dimensions mismatch: ' + label)
        path = destination / (label + '.png')
        path.write_bytes(raw)
        receipts[label] = dict(path=str(path), sha256=m['sha'], original_960x640_sha256=m['source_sha'], size_bytes=len(raw), crop_pixels=[width, height])
    return receipts


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('job_log', type=Path)
    p.add_argument('--out', type=Path, default=Path('private-native-crops'))
    a = p.parse_args()
    try:
        receipt = recover(a.job_log.read_text(encoding='utf-8', errors='replace'), a.out)
    except (ValueError, OSError) as exc:
        print('NATIVE_CROP_RECOVERY_FAIL: ' + str(exc), file=sys.stderr)
        return 1
    import json
    (a.out / 'crop-receipt.json').write_text(json.dumps({'kind': 'genuine-native-1x-lossless-crops-only', 'images': receipt, 'whole_scene_custody': 'NOT_ESTABLISHED', 'visual_acceptance': 'PENDING'}, indent=2))
    print(f'NATIVE_CROP_RECOVERY_PASS: {len(receipt)} lossless native-scale crops, recipient hashes verified')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
