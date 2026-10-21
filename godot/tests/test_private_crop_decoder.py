"""Offline fail-closed tests for private Actions-log crop recovery."""
import base64
import hashlib
from pathlib import Path
import tempfile
from recover_private_native_crops import recover

# Static tiny 1x1 PNG test bytes, NOT a native scene capture.
PNG = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9QX6gAAAAASUVORK5CYII=')
SHA = hashlib.sha256(PNG).hexdigest()
encoded = base64.b64encode(PNG).decode('ascii')

def verify():
    start = f'AW_NATIVE_CROP_BEGIN:test-crop:1x1:{SHA}:{SHA}:{len(PNG)}\n'
    payload = f'AW_NATIVE_CROP_DATA:test-crop:0:{encoded}\n'
    stop = 'AW_NATIVE_CROP_END:test-crop\n'
    with tempfile.TemporaryDirectory() as directory:
        dest = Path(directory)
        recovered = recover(start + payload + stop, dest)
        assert recovered['test-crop']['sha256'] == SHA
        assert (dest / 'test-crop.png').read_bytes() == PNG
        for bad in (
            start + stop,
            start + payload,
            start + payload.replace(':0:', ':2:') + stop,
            start + payload.replace('test-crop:0:', 'invalid-name:0:') + stop,
            start.replace(SHA, '0' * 64, 1) + payload + stop,
        ):
            try:
                recover(bad, dest)
            except ValueError:
                continue
            raise AssertionError('corrupted/truncated/reordered log was accepted')
    print('PRIVATE_CROP_DECODER_CONTRACT_PASS: valid reconstruction; five invalid cases rejected')

if __name__ == '__main__':
    verify()
