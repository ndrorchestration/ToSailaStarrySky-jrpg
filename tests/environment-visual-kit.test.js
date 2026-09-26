'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'environment-visual-kit.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'environment-visual-kit.js' });
const api = sandbox.window.AetherEnvironmentVisualKit;
assert(api, 'environment visual kit missing');
assert.strictEqual(api.VERSION, '0.2.0');
assert.strictEqual(api.SCALE.doorHeightAdultHeights, 1.35);
assert.strictEqual(api.SCALE.crateHeightAdultHeights, 0.38);
for (const fn of ['drawDockSurface','drawDockMidground','drawDockForeground','drawBollard','drawRopeCoil','drawPlanter','drawRepairBench','drawWindVane','drawRepairCanopy','drawCrane','drawCargoCrate','drawAetherStone','drawSkyPool','drawSignalCrystal']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}
for (const forbidden of ['quest.', 'gameState =', 'mooredLandmarkId =', 'groundLayer[']) {
  assert(!source.includes(forbidden), 'environment kit must remain presentation-only: ' + forbidden);
}
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.includes('modules/environment-visual-kit.js'), 'environment visual kit missing from embedded runtime');
assert(html.indexOf('modules/environment-visual-kit.js') < html.indexOf('modules/preview-world-presentation.js'),
  'environment kit must load before projected world presentation');
assert(html.indexOf('modules/environment-visual-kit.js') < html.indexOf('modules/visual-benchmark.js'),
  'environment kit must load before benchmark');
console.log('Aetherwake environment visual kit contract: PASS');
