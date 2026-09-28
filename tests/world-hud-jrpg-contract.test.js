'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes('Chapter objective HUD should read like a JRPG quest cue'),
  'world quest HUD must use the JRPG quest-cue treatment');
assert(runtime.includes("fill(color(8, 14, 24, 118))"),
  'world HUD panels must stay translucent over authored scenery');
assert(!runtime.includes("text('SOLAR ' + player.solarCharge.toFixed(2) + 'kWh'"),
  'field HUD must not expose engineering-unit solar telemetry');
assert(!runtime.includes("text('⚡ FIRE ' + player.staffCharges + '/2'"),
  'field HUD must not expose the old paired FIRE telemetry bar');
assert(runtime.includes("text('AETHER', x, y - 3)") && runtime.includes("text('STAFF', x, y + 7)"),
  'field resources must use compact JRPG-style pip cues');
assert(runtime.includes('const solarPips = 4'),
  'Aether resource cue must remain compact and discrete');

console.log('Aetherwake world HUD JRPG presentation contract: PASS');
