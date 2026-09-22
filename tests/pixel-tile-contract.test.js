'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'pixel-tiles.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'pixel-tiles.js' });
const api = sandbox.window.AetherPixelTiles;

assert(api, 'pixel tile authority was not exposed');
assert.strictEqual(api.VERSION, '0.3.0');
assert.strictEqual(api.TILE_SIZE, 16);
assert.strictEqual(api.validate(), true);

for (const id of [
  'hull','grass','crate','float','water','loreUnknown','loreKnown','cloud','astro',
  'forest','cliff','shore','mountain','path','flowers','ruins','bridge','village'
]) {
  assert(api.get(id), id + ' tile missing');
}

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/pixel-tiles.js') >= 0, 'pixel tile script missing');
assert(html.indexOf('modules/pixel-tiles.js') < html.indexOf('aetherwake.js'),
  'pixel tile authority must load before runtime');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
for (const binding of [
  "drawPixelWorldTile('hull'",
  "drawPixelWorldTile('grass'",
  "drawPixelWorldTile('crate'",
  "drawPixelWorldTile('float'",
  "drawPixelWorldTile('water'",
  "drawPixelWorldTile(discovered ? 'loreKnown' : 'loreUnknown'",
  "drawPixelWorldTile('cloud'",
  "drawPixelWorldTile('astro'"
]) {
  assert(runtime.includes(binding), 'missing tile binding: ' + binding);
}
assert(runtime.includes("throw new Error('AETHER_PIXEL_TILES_UNAVAILABLE')"),
  'tile authority must fail visibly if unavailable');

console.log('Aetherwake current-main pixel tile foundation: PASS');
