'use strict';
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const source = fs.readFileSync(path.join(__dirname, '..', 'modules', 'pixel-tiles.js'), 'utf8');
const context = { globalThis: {} };
vm.createContext(context);
vm.runInContext(source, context);
const api = context.globalThis.AetherPixelTiles;
assert(api && api.validate(), 'pixel tile registry must validate');
['forest','cliff','shore','mountain','path','flowers','ruins','village'].forEach(id => assert(api.get(id), id + ' tile missing'));
assert.strictEqual(api.VERSION, '0.3.0');
const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
['forest','cliff','shore','mountain','path'].forEach(id =>
  assert(runtime.includes("'" + id + "'"), id + ' is not composed into the live world renderer')
);
assert(runtime.includes('collision/topology remain owned by groundLayer'),
  'scenic composition does not explicitly preserve gameplay topology');
console.log('Aetherwake 16-bit world art vocabulary: PASS');
