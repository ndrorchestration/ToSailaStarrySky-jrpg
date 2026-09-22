'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const live = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const mirror = fs.readFileSync(path.join(__dirname, '..', 'modules', 'world.js'), 'utf8');

assert(mirror.startsWith('// MIRROR NOTICE: This file is not the runtime authority.'),
  'modules/world.js must identify itself as a non-runtime mirror');

const liveStart = live.indexOf('// === modules/world.js ===');
const liveEnd = live.indexOf('// === modules/combat.js ===', liveStart);
assert(liveStart >= 0 && liveEnd > liveStart, 'live bundled WORLD section missing');
const liveWorld = live.slice(liveStart, liveEnd);

for (const id of ['sky_predator','wind_shear','aether_leak','corporate_intercept']) {
  assert(liveWorld.includes("id: '" + id + "'"), 'live WORLD missing hazard ' + id);
  assert(mirror.includes("id: '" + id + "'"), 'WORLD mirror missing hazard ' + id);
}
assert(liveWorld.includes('quest.hazardsCompleted >= 4'),
  'live WORLD must require all four Crossing hazards');
assert(mirror.includes('quest.hazardsCompleted >= 4'),
  'WORLD mirror must preserve four-hazard threshold');
assert(liveWorld.includes('quest.crossingHazards[3]'),
  'live WORLD must include fourth hazard trigger');
assert(mirror.includes('quest.crossingHazards[3]'),
  'WORLD mirror must include fourth hazard trigger');

console.log('Aetherwake WORLD authority/four-hazard mirror contract: PASS');
