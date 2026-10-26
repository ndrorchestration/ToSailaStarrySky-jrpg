'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'flight-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'flight-visual-stage.js' });
const api = sandbox.window.AetherFlightVisual;

assert(api, 'flight visual API missing');
assert.strictEqual(api.VERSION, '0.6.2');
for (const fn of ['altitudeProfile','weatherPalette','drawBackdrop','drawDragonfly','drawForeground','drawRouteOverlay','drawLandmarkBeacons']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}
assert(api.altitudeProfile('high').cloudBase > api.altitudeProfile('low').cloudBase,
  'altitude must materially change cloud-plane composition');
assert.deepStrictEqual(Array.from(api.weatherPalette('aether-squall').accent), [124,200,232]);

assert(!source.includes('encounterSteps ='), 'flight visuals must not mutate encounter state');
assert(!source.includes('mooredLandmarkId ='), 'flight visuals must not mutate docking state');
assert(!source.includes('discovered.push'), 'flight visuals must not mutate discovery');
assert(source.includes('aetherwake-preview-world-pixelart-v2.png'),
  'flight stage must bind the painted world backdrop authority when available');
assert(source.includes('paintedBackdrop'),
  'flight stage must distinguish painted-backdrop and procedural fallback composition');
assert(source.includes('function drawFarLandmarks'), 'flight stage must retain dimensional far-landmark staging');
assert(source.includes('function drawForeground'), 'flight stage must retain a near-camera occlusion pass');
assert(source.includes('Speed streaks live in the foreground'), 'flight stage must retain speed-responsive foreground motion');
assert(source.includes('controlsHint'), 'flight stage must retain the shared controls-hint layout hook');
assert(source.includes('progressW = statusW - 20') && source.includes('Keeping the center-top clear'),
  'flight route progress must stay inside the compact navigation plaque and leave center-top clear');
assert(source.includes("text('Q / E  altitude     D  dock'"),
  'flight controls must stay minimal and subordinate to the world');
assert(source.includes("'R  engage lane'") && source.includes("'R  release lane'"),
  'Rootline lane control must explain both the available action and the active release action');
assert(source.includes("'F  chart upper trace'"),
  'in-range Rootline evidence must expose a direct chart action');
assert(source.includes('const contextualHintH = 20') &&
       source.includes('textSize(10)') &&
       source.includes('rect(contextualHintX, contextualHintY, contextualHintW, contextualHintH, 6)'),
  'contextual route action must have a dedicated high-salience pill instead of bare 8px text');
assert(!source.includes("text('OPEN-SKY FLIGHT'") && !source.includes("'  ?  SPD '") && !source.includes("'  ?  P '"),
  'flight HUD must not expose dashboard/debug-style labels or raw telemetry');
assert(source.includes('const heroScale = 1.55'),
  'flight Dragonfly must retain a readable hero-object scale');
assert(source.includes('const cameraAnchorX = w * 0.42') &&
       source.includes('const cameraAnchorY = h * 0.56') &&
       source.includes('const cameraFollow = 0.18') &&
       source.includes('const horizontalReserve = Math.min(w * 0.34, 226)') &&
       source.includes('x: presentationX') && source.includes('y: presentationY'),
  'flight Dragonfly must use camera-follow composition inside a presentation-safe viewport envelope');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/flight-visual-stage.js') >= 0, 'flight visual stage script missing');
assert(html.indexOf('modules/flight-visual-stage.js') < html.indexOf('aetherwake.js'),
  'flight visual stage must load before runtime');
const flightStart = runtime.indexOf('function drawAirNavigationScene()');
const flightEnd = runtime.indexOf('function startCombat(', flightStart);
assert(flightStart >= 0 && flightEnd > flightStart,
  'live flight renderer boundary missing');
const flightRuntime = runtime.slice(flightStart, flightEnd);
assert(flightRuntime.includes('const visual = window.AetherFlightVisual;'),
  'live flight renderer must acquire shared visual authority');
assert(flightRuntime.includes('width,') && flightRuntime.includes('height,'),
  'live flight renderer must pass viewport dimensions for safe hero-object framing');
for (const binding of [
  'visual.drawBackdrop(',
  'visual.drawDragonfly(',
  'visual.drawForeground(',
  'visual.drawRouteOverlay(',
  'visual.drawLandmarkBeacons('
]) {
  assert(flightRuntime.includes(binding), 'missing live flight visual binding: ' + binding);
}
assert(flightRuntime.includes('const modernFlightVisual = Boolean('),
  'runtime must detect when the modern flight visual owns navigation presentation');
assert(flightRuntime.includes("if (!visual || typeof visual.drawRouteOverlay !== 'function')"),
  'legacy flight telemetry must be a fallback, not stacked over the modern HUD');
assert(flightRuntime.includes('if (!modernFlightVisual) {'),
  'legacy route grid/landmark labels must be suppressed when modern flight presentation is active');

console.log('Aetherwake Dragonfly flight visual gate: PASS');
