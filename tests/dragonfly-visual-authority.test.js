'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'dragonfly-visual.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'dragonfly-visual.js' });

assert(sandbox.window.AetherDragonflyVisual, 'shared Dragonfly visual authority missing');
assert.strictEqual(sandbox.window.AetherDragonflyVisual.VERSION, '0.2.0');
assert.strictEqual(typeof sandbox.window.AetherDragonflyVisual.draw, 'function');
assert(source.includes('function drawWingPair'), 'Dragonfly must retain articulated paired-wing authority');
assert(source.includes('function drawHull'), 'Dragonfly must retain a dedicated tapered-hull renderer');
assert(source.includes('function drawWake'), 'Dragonfly must retain speed-responsive propulsion-wake rendering');
assert(source.includes('Warm cabin windows'), 'Dragonfly must retain inhabited warm-light detail');

const benchmark = fs.readFileSync(path.join(root, 'modules', 'visual-benchmark.js'), 'utf8');
const flight = fs.readFileSync(path.join(root, 'modules', 'flight-visual-stage.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');

assert(benchmark.includes("mode: 'dock'"), 'dock benchmark must delegate to shared Dragonfly authority');
assert(flight.includes("mode: 'flight'"), 'flight stage must delegate to shared Dragonfly authority');
assert(benchmark.includes('AetherDragonflyVisual'), 'benchmark shared authority binding missing');
assert(flight.includes('AetherDragonflyVisual'), 'flight shared authority binding missing');
assert(html.indexOf('modules/dragonfly-visual.js') >= 0, 'shared Dragonfly script missing');
assert(html.indexOf('modules/dragonfly-visual.js') < html.indexOf('modules/visual-benchmark.js'),
  'shared Dragonfly authority must load before benchmark');
assert(html.indexOf('modules/dragonfly-visual.js') < html.indexOf('modules/flight-visual-stage.js'),
  'shared Dragonfly authority must load before flight stage');

for (const forbidden of ['mooredLandmarkId =', 'encounterSteps =', 'gameState =', 'quest.']) {
  assert(!source.includes(forbidden), 'shared Dragonfly visual must remain presentation-only: ' + forbidden);
}

console.log('Aetherwake shared Dragonfly visual authority: PASS');
