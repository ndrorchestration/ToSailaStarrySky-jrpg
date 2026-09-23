'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');

const repo = path.resolve(__dirname, '..');
const manifestPath = path.join(repo, 'docs', 'audio-assets.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const title = manifest.titleTheme;

assert(title, 'M0 title-theme authority missing');
assert.strictEqual(
  title.canonicalPath,
  'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3',
  'M0 title theme canonical path drifted'
);
assert.strictEqual(
  title.repositoryStatus,
  'admitted',
  'M0 candidate requires title theme repositoryStatus=admitted'
);
assert.strictEqual(
  title.runtimeRegistration,
  true,
  'M0 candidate requires governed title runtime registration'
);
assert(title.sourceRecovery &&
       title.sourceRecovery.status === 'exact-source-recovered-and-reverified',
  'M0 candidate requires exact recovered source identity');
assert.strictEqual(
  title.sourceRecovery.repositoryTransfer,
  'completed',
  'M0 candidate requires completed binary repository transfer'
);

const assetPath = path.join(repo, title.canonicalPath);
assert(fs.existsSync(assetPath),
  'M0 candidate requires canonical title MP3 in repository checkout');

childProcess.execFileSync(
  'git',
  ['ls-files', '--error-unmatch', '--', title.canonicalPath],
  { cwd: repo, stdio: 'ignore' }
);

const bytes = fs.readFileSync(assetPath);
assert.strictEqual(
  bytes.length,
  title.sourceVerification.bytes,
  'M0 title MP3 byte count does not match governed source'
);
assert.strictEqual(
  crypto.createHash('sha256').update(bytes).digest('hex'),
  title.sourceVerification.sha256,
  'M0 title MP3 SHA-256 does not match governed source'
);

const runtimeAssets = require('../modules/audio-assets-runtime.js');
assert(runtimeAssets &&
       runtimeAssets.MANIFEST &&
       runtimeAssets.MANIFEST.titleTheme,
  'M0 runtime title-theme registry missing');
assert.strictEqual(
  runtimeAssets.MANIFEST.titleTheme.runtimeRegistration,
  true,
  'M0 runtime registry must expose admitted title theme'
);
assert.strictEqual(
  runtimeAssets.MANIFEST.titleTheme.repositoryStatus,
  'admitted',
  'M0 runtime registry must mirror admitted title status'
);

console.log('Aetherwake M0 title-audio readiness: PASS');
