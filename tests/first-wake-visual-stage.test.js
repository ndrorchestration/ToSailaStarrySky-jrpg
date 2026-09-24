'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'first-wake-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'first-wake-visual-stage.js' });

const api = sandbox.window.AetherFirstWakeVisual;
assert(api, 'First Wake visual stage missing');
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['draw','drawDock','drawInterior','drawChapter']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'opening dock must reuse shared Dragonfly authority');
assert(source.includes('AetherPixelSprites'),
  'opening must reuse shared sprite authority');
assert(source.includes('drawScenicBackdrop'),
  'opening dock must reuse the Preview scenic sky backdrop');
assert(source.includes('scale: 3'),
  'opening character sprites must render at readable three-pixel scale');
assert(source.includes("sprites.draw('ender'"),
  'opening must use canonical Ender sprite');
assert(source.includes("sprites.draw('ionia'") || source.includes("['ionia'"),
  'opening must use canonical Ionia sprite');
assert(source.includes("['lyra'"),
  'opening must use canonical Lyra sprite');
assert(!source.includes('ellipse('),
  'opening visual stage must avoid smooth ellipse-based procedural art');
assert(!source.includes('triangle('),
  'opening must not reintroduce a separate procedural ship silhouette');

const dockSpriteCalls = [];
const behaviorSandbox = {
  window: {
    AetherPreviewWorldPresentation: { drawScenicBackdrop() {} },
    AetherDragonflyVisual: { draw() {} },
    AetherPixelSprites: {
      validate: () => true,
      drawShadow() {},
      draw(id, x, y, options) { dockSpriteCalls.push({ id, x, frame: options.frame }); },
    },
  },
  globalThis: {},
  width: 960,
  height: 640,
  noStroke() {}, fill() {}, rect() {}, stroke() {}, strokeWeight() {}, line() {},
};
vm.runInNewContext(source, behaviorSandbox, { filename: 'first-wake-visual-stage-behavior.js' });
const dockVisual = behaviorSandbox.window.AetherFirstWakeVisual;
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 1, max: 8 } }, 1000);
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 1, max: 8 } }, 1500);
assert.deepStrictEqual(dockSpriteCalls.filter(sprite => sprite.id === 'ender').map(sprite => sprite.frame), [0, 0],
  'stationary Ender must remain on the idle sprite frame');
assert(dockSpriteCalls.filter(sprite => sprite.id === 'ionia')
  .every(sprite => sprite.frame === 0),
  'stationary First Wake characters must not play the walk cycle in place');
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 2, max: 8 } }, 1600);
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 2, max: 8 } }, 1730);
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 3, max: 8 } }, 1760);
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 4, max: 8 } }, 1860);
dockVisual.drawDock({ id: 'dock_walk', sequence: 1 }, { dockWalk: { x: 4, max: 8 } }, 2380);
assert.notStrictEqual(dockSpriteCalls[0].x, dockSpriteCalls[4].x,
  'Ender should advance along the dock when the walk state advances');
assert.deepStrictEqual(dockSpriteCalls.filter(sprite => sprite.id === 'ender').slice(2)
  .map(sprite => sprite.frame), [0, 1, 1, 0, 0],
  'Ender should keep a steady walk cycle through repeated steps, then return to idle');
assert(dockSpriteCalls.filter(sprite => sprite.id === 'ionia').every(sprite => sprite.frame === 0),
  'Ionia must remain idle while Ender walks');


const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/first-wake-visual-stage.js') >= 0,
  'First Wake visual stage script missing');
assert(html.indexOf('modules/first-wake-visual-stage.js') < html.indexOf('aetherwake.js'),
  'First Wake visual authority must load before runtime');
const openingStart = runtime.indexOf('function drawFirstWakeOpening() {');
const openingEnd = runtime.indexOf('\n// ── Open-sky flight ──', openingStart);
assert(openingStart >= 0 && openingEnd > openingStart, 'First Wake opening renderer missing');
const openingFunction = runtime.slice(openingStart, openingEnd);
assert(openingFunction.includes('const visual = window.AetherFirstWakeVisual;'),
  'opening renderer must acquire the shared First Wake visual authority');
assert(openingFunction.includes("typeof visual.draw === 'function'"),
  'opening renderer must verify the shared draw method');
assert(openingFunction.includes('visual.draw(scene, state, { now: millis(), width, height });'),
  'opening runtime does not delegate to shared visual stage');

console.log('Aetherwake First Wake visual stage contract: PASS');
