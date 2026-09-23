'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');

const repo = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'audio-assets.json'), 'utf8'
));
const title = manifest.titleTheme;
assert.strictEqual(manifest.version, 1);
assert(title && title.id === 'title-main', 'canonical title-theme record missing');
assert.strictEqual(
  title.canonicalPath,
  'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3',
  'title theme canonical repository path drifted'
);
assert(/^[a-f0-9]{64}$/.test(title.sourceVerification.sha256),
  'title theme source SHA-256 is malformed');
assert.strictEqual(title.sourceVerification.bytes, 4233081,
  'title theme verified source byte size drifted');
assert.strictEqual(title.musicBusTrackId, 'title',
  'title theme must retain canonical music-bus id');

assert(title.sourceRecovery &&
       title.sourceRecovery.status === 'exact-source-recovered-and-reverified',
  'governed manifest must record recovered exact source evidence');
assert.strictEqual(
  title.sourceRecovery.sha256,
  title.sourceVerification.sha256,
  'recovered title source fingerprint must match original verification'
);
assert.strictEqual(
  title.sourceRecovery.bytes,
  title.sourceVerification.bytes,
  'recovered title source byte count must match original verification'
);

const assetPath = path.join(repo, title.canonicalPath);
if (!fs.existsSync(assetPath)) {
  assert.strictEqual(
    title.repositoryStatus,
    'source-verified-repository-missing',
    'missing title asset must fail closed in manifest authority'
  );
  assert.strictEqual(title.runtimeRegistration, false,
    'missing title asset must not claim runtime registration');
} else {
  assert.strictEqual(title.repositoryStatus, 'admitted',
    'present title asset requires explicit admitted status');
  assert.strictEqual(title.runtimeRegistration, true,
    'present title asset requires explicit runtime registration');
  assert(title.sourceRecovery &&
         title.sourceRecovery.repositoryTransfer === 'completed',
    'admitted title asset must record completed repository transfer');
  let tracked = false;
  try {
    childProcess.execFileSync(
      'git',
      ['ls-files', '--error-unmatch', '--', title.canonicalPath],
      { cwd: repo, stdio: 'ignore' }
    );
    tracked = true;
  } catch (_error) {
    tracked = false;
  }
  assert.strictEqual(tracked, true,
    'admitted title asset must be tracked by Git at its canonical path');
  const bytes = fs.readFileSync(assetPath);
  assert.strictEqual(bytes.length, title.sourceVerification.bytes,
    'admitted title asset byte size does not match verified source');
  assert.strictEqual(
    crypto.createHash('sha256').update(bytes).digest('hex'),
    title.sourceVerification.sha256,
    'admitted title asset hash does not match verified source'
  );
}

const stage = fs.readFileSync(
  path.join(repo, 'scripts', 'stage-memories-desktop.js'), 'utf8'
);
assert(stage.includes("path.join(repo, 'assets')") &&
       stage.includes("path.join(www, 'assets')"),
  'desktop staging does not preserve governed audio assets');

console.log('Aetherwake governed audio asset contract: PASS');
