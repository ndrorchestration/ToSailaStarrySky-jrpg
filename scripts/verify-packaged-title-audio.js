'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const packageDirArg = process.argv[2];
assert(packageDirArg, 'Usage: node scripts/verify-packaged-title-audio.js <package-dir>');

const packageDir = path.resolve(packageDirArg);
const manifest = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'audio-assets.json'),
  'utf8'
));
const title = manifest.titleTheme;

assert(title && title.repositoryStatus === 'admitted',
  'packaged title-audio verification requires admitted source authority');
assert.strictEqual(title.runtimeRegistration, true,
  'packaged title-audio verification requires runtime registration');

const sourcePath = path.join(repo, title.canonicalPath);
const packagedPath = path.join(packageDir, 'www', title.canonicalPath);

assert(fs.existsSync(sourcePath),
  'canonical title MP3 missing from source checkout');
assert(fs.existsSync(packagedPath),
  'canonical title MP3 missing from packaged www payload');

function fingerprint(filePath) {
  const bytes = fs.readFileSync(filePath);
  return {
    bytes: bytes.length,
    sha256: crypto.createHash('sha256').update(bytes).digest('hex')
  };
}

const source = fingerprint(sourcePath);
const packaged = fingerprint(packagedPath);

assert.strictEqual(
  source.bytes,
  title.sourceVerification.bytes,
  'source title MP3 byte count drifted before packaging'
);
assert.strictEqual(
  source.sha256,
  title.sourceVerification.sha256,
  'source title MP3 hash drifted before packaging'
);
assert.deepStrictEqual(
  packaged,
  source,
  'packaged title MP3 does not exactly match admitted source'
);

console.log(JSON.stringify({
  status: 'PASS',
  sourcePath: title.canonicalPath,
  packagedPath: path.relative(packageDir, packagedPath).replace(/\\/g, '/'),
  bytes: packaged.bytes,
  sha256: packaged.sha256
}));
