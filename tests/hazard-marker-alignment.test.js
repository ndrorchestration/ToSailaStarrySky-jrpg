'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes('const hazardMarkerCells = {'),
  'shared hazard marker coordinate authority missing');

const expected = {
  sky_predator: [[29,5],[30,6],[29,7]],
  wind_shear: [[13,10],[15,11],[17,12]],
  aether_leak: [[18,3],[20,4],[22,3]],
  corporate_intercept: [[7,11],[9,12],[10,14]],
};

for (const [id, cells] of Object.entries(expected)) {
  for (const [x,y] of cells) {
    assert(runtime.includes('[' + x + ', ' + y + ']'),
      id + ' marker missing expected cell ' + x + ',' + y);
  }
}

function inTrigger(id, x, y) {
  if (id === 'sky_predator') return x >= 28 && y >= 4 && y <= 8;
  if (id === 'wind_shear') return x >= 10 && x <= 20 && y >= 8 && y <= 14;
  if (id === 'aether_leak') return y <= 5 && x >= 15 && x <= 25;
  if (id === 'corporate_intercept') return x >= 4 && x <= 12 && y >= 9 && y <= 16;
  return false;
}

for (const [id, cells] of Object.entries(expected)) {
  for (const [x,y] of cells) {
    assert(inTrigger(id, x, y),
      id + ' marker is outside its live trigger zone at ' + x + ',' + y);
  }
}

assert(runtime.includes('Hazard markers are intentionally anchored inside the exact live trigger'),
  'hazard marker/trigger authority comment missing');

console.log('Aetherwake hazard marker alignment contract: PASS');
