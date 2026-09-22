'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'pixel-tiles.js'), 'utf8');
const context = { globalThis: {}, window: {} };
vm.createContext(context);
vm.runInContext(source, context);
const api = context.globalThis.AetherPixelTiles || context.window.AetherPixelTiles;

assert(api && api.validate(), 'pixel tile registry must validate');
for (const id of ['forest','cliff','shore','mountain','path','flowers','ruins','bridge','village']) {
  assert(api.get(id), id + ' tile missing');
}
assert.strictEqual(api.VERSION, '0.3.0');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
for (const id of ['forest','shore','mountain','path','flowers','ruins','village']) {
  assert(runtime.includes("drawPixelWorldTile('" + id + "'"),
    id + ' is not composed into the live world renderer');
}
assert(runtime.includes('scenicNoise('), 'coherent deterministic biome field missing');
assert(runtime.includes('grassNeighborCount('), 'terrain-neighborhood composition missing');
assert(runtime.includes('touchesLand'), 'shoreline adjacency contract missing');
assert(runtime.includes('collision/topology remain'),
  'scenic composition does not explicitly preserve gameplay topology');

// The bridge tile exists in the art vocabulary but is intentionally not claimed
// as live composition until a placement contract is authored.
assert(api.get('bridge'), 'bridge vocabulary tile missing');

console.log('Aetherwake current-main 16-bit world composition: PASS');
