'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(repo, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(repo, 'aetherwake.js'), 'utf8');
const manifest = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'audio-assets.json'),
  'utf8'
));

assert(html.includes('modules/music-bus.js'),
  'music bus must load in embedded runtime');
assert(html.includes('modules/audio-assets-runtime.js'),
  'governed audio asset runtime registry must load in embedded runtime');
assert(
  html.indexOf('modules/music-bus.js') <
  html.indexOf('modules/audio-assets-runtime.js') &&
  html.indexOf('modules/audio-assets-runtime.js') <
  html.indexOf('aetherwake.js'),
  'governed audio registry must load after music bus and before main runtime'
);

assert(runtime.includes('function initializeGovernedAudioAssets()'),
  'runtime governed audio initializer is missing');
assert(runtime.includes(
  'window.AetherAudioAssets.registerAdmittedTracks(window.AetherMusicBus)'
), 'runtime must register only governed admitted audio assets');
assert(runtime.includes('function requestTitleMusic(force)'),
  'title music playback request helper is missing');
assert(runtime.includes("reason: 'TITLE_THEME_NOT_ADMITTED'"),
  'missing/unadmitted title theme must fail closed');
assert(runtime.includes('requestTitleMusic(false);'),
  'title screen must request admitted theme playback');
assert(runtime.includes('requestTitleMusic(true);'),
  'user gesture must retry admitted title playback after audio resume');
assert(runtime.includes('function stopTitleMusic()'),
  'title music stop helper is missing');
assert(runtime.includes('stopTitleMusic();') &&
       runtime.includes('startFirstWakeOpening();'),
  'New Game must stop title music before authored opening');

assert.strictEqual(
  manifest.titleTheme.sourceRecovery.status,
  'exact-source-recovered-and-reverified'
);
assert.strictEqual(
  manifest.titleTheme.sourceRecovery.sha256,
  manifest.titleTheme.sourceVerification.sha256
);
assert.strictEqual(
  manifest.titleTheme.sourceRecovery.bytes,
  manifest.titleTheme.sourceVerification.bytes
);

console.log('Aetherwake governed title-audio runtime contract: PASS');
