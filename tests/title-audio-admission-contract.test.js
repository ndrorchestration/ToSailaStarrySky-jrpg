'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'audio-assets.json'),
  'utf8'
));
const runtimeAssets = require('../modules/audio-assets-runtime.js');
const admission = require('../scripts/admit-title-audio.js');

assert.deepStrictEqual(
  runtimeAssets.MANIFEST,
  admission.runtimeManifest(manifest),
  'runtime audio-asset registry must exactly mirror governed manifest registration fields'
);

const calls = [];
const fakeBus = {
  registerTrack(track) {
    calls.push(track);
    return track;
  }
};

const result = runtimeAssets.registerAdmittedTracks(fakeBus);
if (manifest.titleTheme.runtimeRegistration) {
  assert.strictEqual(result.ok, true);
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(calls[0].id, manifest.titleTheme.musicBusTrackId);
  assert.strictEqual(calls[0].src, manifest.titleTheme.canonicalPath);
} else {
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.reason, 'TITLE_THEME_NOT_ADMITTED');
  assert.strictEqual(calls.length, 0,
    'unadmitted title asset must not register a playback path');
}

assert.strictEqual(
  manifest.titleTheme.sourceRecovery.sha256,
  manifest.titleTheme.sourceVerification.sha256,
  'recovered source fingerprint must match governed verification'
);
assert.strictEqual(
  manifest.titleTheme.sourceRecovery.bytes,
  manifest.titleTheme.sourceVerification.bytes,
  'recovered source byte count must match governed verification'
);

assert.throws(
  () => admission.verifySourceFile(
    path.join(repo, 'tests', 'fixtures', '__definitely_missing_title.mp3'),
    manifest.titleTheme
  ),
  /TITLE_AUDIO_SOURCE_MISSING/
);

console.log('Aetherwake title-audio admission pipeline: PASS');
