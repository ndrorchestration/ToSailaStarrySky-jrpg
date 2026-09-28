'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'title-visual-stage.js'), 'utf8');
const titleBackground = fs.readFileSync(
  path.join(root, 'assets', 'preview', 'aetherwake-preview-world-pixelart-v2.png')
);
assert.strictEqual(titleBackground.subarray(0, 8).toString('hex'), '89504e470d0a1a0a',
  'title should reuse the shipped pixel-art world scenery');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'title-visual-stage.js' });

const api = sandbox.window.AetherTitleVisual;
assert(api, 'title visual stage missing');
assert.strictEqual(api.VERSION, '0.4.0');
for (const fn of ['draw','drawSky','drawHero','drawTitleCopy']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'title must reuse shared Dragonfly visual authority');
assert(source.includes('aetherwake-preview-world-pixelart-v2.png'),
  'title should show the authored pixel-art sky-island landscape');
assert(source.includes("scale: 1.45"),
  'title must present Dragonfly as a hero-scale object');
assert(!source.includes('ellipse('),
  'title visual stage must avoid old smooth ellipse island treatment');
assert(source.includes("text('NEW GAME', cx, menuY)"),
  'title New Game affordance missing');
assert(source.includes("text('ENTER', cx, menuY + 21)"),
  'title must keep input hint minimal');
assert(!source.includes('WASD / ARROWS') && !source.includes('A small ship. A broken world.'),
  'title must not lead with tutorial or pitch copy');
assert(!source.includes('AetherUIVisualSystem') && !source.includes('layoutTitle'),
  'title must behave as key art rather than a framed application panel');

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
