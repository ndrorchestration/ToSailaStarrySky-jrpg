'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const source = fs.readFileSync(path.join(__dirname, '..', 'modules', 'audio.js'), 'utf8');
const context = {
  window: {},
  console: { log() {}, warn() {} },
  Map,
  Math
};
context.window.window = context.window;
vm.createContext(context);
vm.runInContext(source, context);

assert.strictEqual(context.window.AUDIO_VOLUME, 0.35,
  'legacy authored SFX loudness must remain the default at Effects 80%');

assert.strictEqual(typeof context.window.setEffectsVolumePercent, 'function',
  'player-facing Effects percentage control is missing');

const eighty = context.window.setEffectsVolumePercent(80);
assert(Math.abs(eighty - 0.35) < 1e-9,
  'Effects 80% must preserve the historical 0.35 master gain');

const hundred = context.window.setEffectsVolumePercent(100);
assert(Math.abs(hundred - 0.4375) < 1e-9,
  'Effects 100% must map to the authored maximum gain');

const zero = context.window.setEffectsVolumePercent(0);
assert.strictEqual(zero, 0, 'Effects 0% must mute synthesized SFX');

console.log('Aetherwake audio settings contract: PASS');
