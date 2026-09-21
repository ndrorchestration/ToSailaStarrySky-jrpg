'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const tilePath = path.join(root, 'modules', 'pixel-tiles.js');
const source = fs.readFileSync(tilePath, 'utf8');

const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: tilePath });

const api = sandbox.window.AetherPixelTiles;
assert(api, 'pixel tile authority was not exposed');
assert.strictEqual(api.VERSION, '0.3.0');
assert.strictEqual(api.TILE_SIZE, 16);
assert.strictEqual(api.validate(), true, 'pixel tile registry failed validation');

const ids = [
  'hull', 'grass', 'crate', 'float', 'water',
  'loreUnknown', 'loreKnown', 'cloud', 'astro',
  'forest', 'cliff', 'shore', 'mountain', 'path', 'flowers', 'ruins', 'bridge', 'village',
];

for (const id of ids) {
  const tile = api.get(id);
  assert(tile, id + ' tile missing');
  assert(Array.isArray(tile.frames) && tile.frames.length >= 1,
    id + ' has no frames');
  assert(tile.frames.every(frame =>
    frame.length === 16 &&
    frame.every(row => typeof row === 'string' && row.length === 16)
  ), id + ' tile geometry is invalid');
}

assert(api.get('grass').frames.length >= 3,
  'grass must retain deterministic visual variation');
assert(api.get('water').frames.length >= 2,
  'water must retain animation frames');

for (const htmlName of ['index.html', 'index-embedded.html']) {
  const html = fs.readFileSync(path.join(root, htmlName), 'utf8');
  const tileIndex = html.indexOf('modules/pixel-tiles.js');
  const runtimeIndex = html.indexOf('aetherwake.js');
  assert(tileIndex >= 0, htmlName + ' does not load pixel-tiles.js');
  assert(tileIndex < runtimeIndex,
    htmlName + ' loads pixel tiles after the runtime authority');
}

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
for (const id of ['hull', 'grass', 'crate', 'float', 'water',
                  'loreKnown', 'loreUnknown', 'cloud', 'astro']) {
  assert(runtime.includes("'" + id + "'"),
    'runtime does not reference pixel tile ' + id);
}
assert(runtime.includes("window.AetherPixelTiles"),
  'world renderer is not bound to pixel tile authority');

console.log('Aetherwake pixel tile foundation: PASS');
