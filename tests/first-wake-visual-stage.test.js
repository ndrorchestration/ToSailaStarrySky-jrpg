'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'first-wake-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'first-wake-visual-stage.js' });

const api = sandbox.window.AetherFirstWakeVisual;
assert(api, 'First Wake visual stage missing');
assert.strictEqual(api.VERSION, '0.2.0');
for (const fn of ['draw','drawDock','drawInterior','drawWakeExploration','drawChapter']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'opening dock must reuse shared Dragonfly authority');
assert(source.includes('AetherPixelSprites'),
  'opening must reuse shared sprite authority');
assert(source.includes("sprites.draw('ender'"),
  'opening must use canonical Ender sprite');
assert(source.includes("sprites.draw('ionia'") || source.includes("['ionia'"),
  'opening must use canonical Ionia sprite');
assert(source.includes("sprites.draw('lyra'"),
  'explorable Wake must use canonical Lyra sprite');
assert(source.includes('wakeExplorationView'),
  'Sequences 05-08 must render from live exploration state');
assert(source.includes('CLUES '),
  'investigation HUD must expose collected-clue state');
assert(!source.includes('ellipse('),
  'opening visual stage must avoid smooth ellipse-based procedural art');
assert(!source.includes('triangle('),
  'opening must not reintroduce a separate procedural ship silhouette');

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/first-wake-visual-stage.js') >= 0,
  'First Wake visual stage script missing');
assert(html.indexOf('modules/first-wake-visual-stage.js') < html.indexOf('aetherwake.js'),
  'First Wake visual authority must load before runtime');
assert(runtime.includes('AetherFirstWakeVisual.draw'),
  'opening runtime does not delegate to shared visual stage');

console.log('Aetherwake First Wake visual stage contract: PASS');
