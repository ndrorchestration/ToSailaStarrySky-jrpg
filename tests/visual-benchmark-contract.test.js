'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'visual-benchmark.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'visual-benchmark.js' });
const api = sandbox.window.AetherVisualBenchmark;

assert(api, 'visual benchmark API missing');
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['isActive','drawBackdrop','drawDragonfly','drawLighting','drawDockLights','drawForeground']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert.strictEqual(
  api.isActive({ tileX: 22, tileY: 16 }, { mooredLandmarkId: 'wake-dock' }),
  true,
  'wake-dock benchmark should activate in the eastern dock region'
);
assert.strictEqual(
  api.isActive({ tileX: 22, tileY: 16 }, { mooredLandmarkId: null }),
  false,
  'benchmark must follow real mooring state'
);
assert(!source.includes('groundLayer['), 'benchmark presentation must not mutate/read collision topology');
assert(!source.includes('quest.'), 'benchmark presentation must not mutate/read quest authority');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/visual-benchmark.js') >= 0, 'visual benchmark script missing');
assert(html.indexOf('modules/visual-benchmark.js') < html.indexOf('aetherwake.js'),
  'visual benchmark authority must load before runtime');
const renderStart = runtime.indexOf('function render() {');
const renderEnd = runtime.indexOf('\n// --- Ship Interior', renderStart);
assert(renderStart >= 0 && renderEnd > renderStart, 'world render function missing');
const renderFunction = runtime.slice(renderStart, renderEnd);
assert(renderFunction.includes('const benchmark = window.AetherVisualBenchmark;'),
  'runtime must acquire the benchmark visual authority');
assert(renderFunction.includes("typeof benchmark.isActive === 'function'"),
  'runtime must verify the benchmark activation method');
assert(renderFunction.includes('benchmark.isActive(player, airNavigationState)'),
  'runtime does not gate benchmark against real world/navigation state');
for (const method of ['drawBackdrop', 'drawDragonfly', 'drawLighting', 'drawForeground']) {
  assert(renderFunction.includes('benchmark.' + method + '('),
    'runtime benchmark ' + method + ' integration missing');
}

console.log('Aetherwake Dragonfly Dusk Dock benchmark contract: PASS');
