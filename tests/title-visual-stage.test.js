'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'title-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'title-visual-stage.js' });

const api = sandbox.window.AetherTitleVisual;
assert(api, 'title visual stage missing');
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['draw','drawSky','drawHero','drawTitleCopy']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'title must reuse shared Dragonfly visual authority');
assert(source.includes("scale: 1.45"),
  'title must present Dragonfly as a hero-scale object');
assert(!source.includes('ellipse('),
  'title visual stage must avoid old smooth ellipse island treatment');
assert(source.includes('NEW GAME  //  N OR ENTER'),
  'title New Game affordance missing');

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/title-visual-stage.js') >= 0,
  'title visual stage script missing');
assert(html.indexOf('modules/title-visual-stage.js') < html.indexOf('aetherwake.js'),
  'title visual stage must load before runtime');
const titleStart = runtime.indexOf('function drawTitleScreen() {');
const titleEnd = runtime.indexOf('\nfunction getDialogueSpriteId', titleStart);
assert(titleStart >= 0 && titleEnd > titleStart, 'title screen renderer missing');
const titleFunction = runtime.slice(titleStart, titleEnd);
assert(titleFunction.includes('const visual = window.AetherTitleVisual;'),
  'title renderer must acquire the shared title visual authority');
assert(titleFunction.includes("typeof visual.draw === 'function'"),
  'title renderer must verify the shared draw method');
assert(titleFunction.includes('visual.draw({ now: millis(), width, height });'),
  'runtime title screen does not delegate to title visual stage');

console.log('Aetherwake title visual stage contract: PASS');
