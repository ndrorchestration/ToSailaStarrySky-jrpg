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
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['altitudeProfile','weatherPalette','drawBackdrop','drawDragonfly','drawRouteOverlay','drawLandmarkBeacons']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}
assert(api.altitudeProfile('high').cloudBase > api.altitudeProfile('low').cloudBase,
  'altitude must materially change cloud-plane composition');
assert.deepStrictEqual(Array.from(api.weatherPalette('aether-squall').accent), [124,200,232]);

assert(!source.includes('encounterSteps ='), 'flight visuals must not mutate encounter state');
assert(!source.includes('mooredLandmarkId ='), 'flight visuals must not mutate docking state');
assert(!source.includes('discovered.push'), 'flight visuals must not mutate discovery');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/flight-visual-stage.js') >= 0, 'flight visual stage script missing');
assert(html.indexOf('modules/flight-visual-stage.js') < html.indexOf('aetherwake.js'),
  'flight visual stage must load before runtime');
for (const binding of [
  'AetherFlightVisual.drawBackdrop',
  'AetherFlightVisual.drawDragonfly',
  'AetherFlightVisual.drawRouteOverlay',
  'AetherFlightVisual.drawLandmarkBeacons'
]) {
  assert(runtime.includes(binding), 'missing live flight visual binding: ' + binding);
}

console.log('Aetherwake Dragonfly flight visual gate: PASS');
