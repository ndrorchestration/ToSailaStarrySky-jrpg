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
assert.strictEqual(sandbox.window.AetherDragonflyVisual.VERSION, '0.6.0');
assert.strictEqual(typeof sandbox.window.AetherDragonflyVisual.draw, 'function');
assert(source.includes('function drawWingPair'), 'Dragonfly must retain articulated paired-wing authority');
assert(source.includes('function drawHull'), 'Dragonfly must retain a dedicated tapered-hull renderer');
assert(source.includes('function drawWake'), 'Dragonfly must retain speed-responsive propulsion-wake rendering');
assert(source.includes('Warm lower-deck lamps'), 'Dragonfly must retain inhabited warm-light detail');
assert(sandbox.window.AetherDragonflyVisual.PROPORTIONS, 'Dragonfly proportion contract missing');
assert.strictEqual(sandbox.window.AetherDragonflyVisual.PROPORTIONS.bodyLengthAdultHeights, 3.0);
assert.strictEqual(sandbox.window.AetherDragonflyVisual.PROPORTIONS.wingSpanBodyLengths, 2.4);
assert(sandbox.window.AetherDragonflyVisual.PROPORTIONS.normalFlightMaxScreenWidthRatio <= 0.28,
  'normal-flight Dragonfly width budget drifted above 28%');
assert(sandbox.window.AetherDragonflyVisual.PROPORTIONS.combatMaxScreenWidthRatio <= 0.25,
  'combat Dragonfly width budget drifted above 25%');
assert(source.includes('Four swept translucent sail-wings'), 'Dragonfly four-sail recognition cue missing');
assert(source.includes('Tapered stern replaces bead-like segmentation'), 'Dragonfly clean tapered-stern cue missing');
assert(source.includes('Deep lower hull establishes the long nautical profile'), 'Dragonfly elongated hull-volume cue missing');
assert(source.includes('Pointed prow / helm glazing'), 'Dragonfly pointed-prow cue missing');
assert(source.includes('engineered sailcloth'), 'Dragonfly engineered sail-wing cue missing');
assert(source.includes('Dorsal service deck'), 'Dragonfly handcrafted dorsal deck cue missing');
assert(source.includes('Continuous Scioto-blue window band'), 'Dragonfly continuous window-band cue missing');
assert(source.includes('Four shield nodes'), 'Dragonfly four-node shield cue missing');
assert(source.includes('function drawPixelHeroShip') && source.includes('function drawPixelWing'),
  'Dragonfly must expose the pixel-built JRPG hero presentation');
assert(source.includes('drawPixelHeroShip(now,mode,speed,pulse)'),
  'production-facing Dragonfly draw path must use the pixel-built hero presentation');
assert(source.includes('Stepped dock shadow keeps the hero object inside the pixel-art grammar'),
  'docked Dragonfly must avoid a smooth placeholder shadow language');
assert(source.includes('Broad translucent membrane establishes the unmistakable four-wing Dragonfly silhouette') && source.includes('vertex(-91'),
  'pixel hero path must preserve clearly separated fore/aft Dragonfly wing geometry');

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
