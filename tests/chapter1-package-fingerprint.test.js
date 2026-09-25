'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { fingerprintDirectory } = require('../scripts/hash-chapter1-package.js');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'aetherwake-package-fingerprint-'));
try {
  fs.mkdirSync(path.join(root, 'www'), { recursive: true });
  fs.writeFileSync(path.join(root, 'Aetherwake.exe'), 'exe-bytes');
  fs.writeFileSync(path.join(root, 'www', 'index.html'), '<html></html>');

  const first = fingerprintDirectory(root);
  const second = fingerprintDirectory(root);
  assert.match(first, /^[0-9a-f]{64}$/);
  assert.strictEqual(second, first, 'same package tree must produce the same fingerprint');

  fs.writeFileSync(path.join(root, 'www', 'index.html'), '<html>changed</html>');
  const changed = fingerprintDirectory(root);
  assert.notStrictEqual(changed, first, 'content mutation must change package fingerprint');

  fs.writeFileSync(path.join(root, 'extra.bin'), 'extra');
  const expanded = fingerprintDirectory(root);
  assert.notStrictEqual(expanded, changed, 'added package files must change package fingerprint');

  fs.unlinkSync(path.join(root, 'extra.bin'));
  fs.writeFileSync(path.join(root, 'www', 'index.html'), '<html></html>');
  const restored = fingerprintDirectory(root);
  assert.strictEqual(restored, first, 'restored package content must restore the original fingerprint');

  console.log('CHAPTER1_PACKAGE_FINGERPRINT_CONTRACT=PASS');
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
