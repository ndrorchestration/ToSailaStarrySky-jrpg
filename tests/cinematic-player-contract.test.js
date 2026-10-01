'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'cinematic-player.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'cinematic-player.js' });

const api = sandbox.window.AetherCinematicPlayer;
assert(api, 'cinematic player API missing');
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['validateManifest','preload','play','skip','state']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

const manifest = {
  id: 'first-dragonfly-reveal',
  file: 'airship/first-dragonfly-reveal.mp4',
  skippable: true,
  replayable: true,
  blocksProgression: false,
  fallback: { type: 'still-or-in-engine', asset: null },
  audio: { mode: 'hybrid', duckRuntimeMusic: true },
  subtitles: { required: false, track: null },
  nextState: 'opening',
};
assert.strictEqual(api.validateManifest(manifest), true);

assert.throws(() => api.validateManifest({...manifest, blocksProgression: true}),
  /CINEMATIC_PROGRESS_AUTHORITY_FORBIDDEN/);
assert(source.includes("status: 'fallback'"),
  'cinematic player must expose fallback completion state');
assert(source.includes("finalize('skipped', 'USER_SKIP')"),
  'cinematic player must expose skip completion state');
assert(source.includes("finalize('played', 'ENDED')"),
  'cinematic player must expose normal completion state');
assert(source.includes("aetherwake:cinematic-fallback"),
  'cinematic player must emit a fallback event');
assert(source.includes("event.key === 'Escape'") && source.includes("event.key === 'Enter'"),
  'cinematic player skip controls missing');

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/cinematic-player.js') >= 0,
  'cinematic player script missing from embedded runtime');
assert(html.indexOf('modules/cinematic-player.js') < html.indexOf('aetherwake.js'),
  'cinematic player must load before main runtime');

console.log('Aetherwake cinematic player contract: PASS');
