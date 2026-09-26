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
assert.strictEqual(api.VERSION, '0.7.0');
for (const fn of ['draw','drawDock','drawInterior','drawChapter']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'opening dock must reuse shared Dragonfly authority');
assert(source.includes('AetherCharacterRenderer'),
  'opening must prefer the articulated character authority');
assert(source.includes('AetherEnvironmentVisualKit'),
  'v0.5 opening dock must reuse the shared environment-kit prop language');
assert(source.includes('AetherPixelSprites'),
  'opening must retain pixel sprites only as a compatibility fallback');
assert(source.includes('aetherwake-preview-world-pixelart-v2.png'),
  'v0.5 opening dock must bind the admitted painted-world authority');
assert(source.includes('drawPaintedDockBackdrop') && source.includes('openingWorldReady'),
  'v0.5 opening dock must retain painted-backdrop readiness and procedural fallback');
assert(source.includes('Presentation-only scene handoff') && source.includes('state.sceneTicks'),
  'opening visual stage must provide bounded scene-transition polish from presentation ticks');
assert(!source.includes('state.sceneTicks ='),
  'visual transition must not mutate opening scene timing state');
assert(source.includes('bandedSky(') && source.includes('cloudBands('),
  'opening dock must retain layered atmospheric fallback depth');
assert(source.includes('continuous trapezoid planes'),
  'opening dock must use continuous perspective deck geometry rather than horizontal bands');
assert(source.includes('Cloud drop below the deck'),
  'v0.3 dock must continuously communicate altitude');
assert(source.includes('cinematicRatio') && source.includes('const settle ='),
  'v0.4 opening must preserve authored cinematic settle timing');
assert(source.includes('scene.sequence >= 1'),
  'v0.4 Sequence 00 must remain a ship-and-sky establishing shot before sprite reveal');
assert(source.includes('1.55 + settle * 0.55'),
  'opening must preserve the Dragonfly reveal scale transition without oversized foreground figures');
assert(source.includes('scale: cinematic ? 2.45 : 1.85'),
  'opening must keep Ender readable while preserving JRPG scene scale and environmental composition');
assert(source.includes("characters.draw('ender'") && source.includes("characters.draw('ionia'"),
  'opening must draw canonical Ender and Ionia through articulated character authority');
assert(source.includes("sprites.draw('ender'") && source.includes("sprites.draw('ionia'"),
  'opening must retain the old sprite path only as fallback');
assert(source.includes('function drawWakeExploration'),
  'v0.2 opening must expose the authored Wake exploration renderer');
assert(source.includes("['ionia'"),
  'opening must use canonical Ionia sprite');
assert(source.includes("['lyra'"),
  'opening must use canonical Lyra sprite');
assert(source.includes('ellipse(') && source.includes('smooth()'),
  'opening visual stage must support smooth atmospheric/cinematic geometry');
assert(!source.includes('function drawShip(') && source.includes('AetherDragonflyVisual'),
  'opening must keep the Dragonfly under the shared ship authority while allowing environmental polygon geometry');

const dockSpriteCalls = [];
const behaviorSandbox = {
  window: {
    AetherPreviewWorldPresentation: { drawScenicBackdrop() {} },
    AetherDragonflyVisual: { draw() {} },
    AetherPixelSprites: {
      validate: () => true,
      drawShadow() {},
      draw(id, x, y, options) { dockSpriteCalls.push({ id, x, frame: options.frame }); },
      drawPreview(id, x, y, options) { dockSpriteCalls.push({ id, x, frame: options.frame }); },
    },
  },
  globalThis: {},
  width: 960,
  height: 640,
  noStroke() {}, fill() {}, rect() {}, ellipse() {}, quad() {}, triangle() {}, beginShape() {}, vertex() {}, endShape() {}, smooth() {}, stroke() {}, strokeWeight() {}, line() {}, CLOSE: 'close',
};
vm.runInNewContext(source, behaviorSandbox, { filename: 'first-wake-visual-stage-behavior.js' });
const dockVisual = behaviorSandbox.window.AetherFirstWakeVisual;
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 1, max: 8 } }, 1000);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 1, max: 8 } }, 1500);
assert(dockSpriteCalls.some(sprite => sprite.id === 'ender'),
  'dock renderer must draw Ender');
assert(dockSpriteCalls.some(sprite => sprite.id === 'ionia'),
  'dock renderer must draw Ionia');
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 2, max: 8 } }, 1600);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 2, max: 8 } }, 1730);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 3, max: 8 } }, 1760);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 4, max: 8 } }, 1860);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 4, max: 8 } }, 2380);
assert.notStrictEqual(dockSpriteCalls[0].x, dockSpriteCalls[4].x,
  'Ender should advance along the dock when the walk state advances');
const enderCalls = dockSpriteCalls.filter(sprite => sprite.id === 'ender');
assert(enderCalls.length >= 4, 'dock walk must keep rendering Ender across progression');
assert(new Set(enderCalls.map(sprite => sprite.x)).size > 1,
  'Ender dock position must advance with authored walk progression');


const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/first-wake-visual-stage.js') >= 0,
  'First Wake visual stage script missing');
assert(html.indexOf('modules/first-wake-visual-stage.js') < html.indexOf('aetherwake.js'),
  'First Wake visual authority must load before runtime');
const openingStart = runtime.indexOf('function drawFirstWakeOpening() {');
const openingEnd = runtime.indexOf('\nfunction ensureAirNavigationState()', openingStart);
assert(openingStart >= 0 && openingEnd > openingStart, 'First Wake opening renderer missing');
const openingFunction = runtime.slice(openingStart, openingEnd);
assert(openingFunction.includes('const visual = window.AetherFirstWakeVisual;'),
  'opening renderer must acquire the shared First Wake visual authority');
assert(openingFunction.includes("typeof visual.draw === 'function'"),
  'opening renderer must verify the shared draw method');
assert(openingFunction.includes('visual.draw(scene, state, { now: millis(), width, height });'),
  'opening runtime does not delegate to shared visual stage');

console.log('Aetherwake First Wake visual stage contract: PASS');

assert(source.includes('const narrativePanelH = Math.min(90, 28 + visibleLines.length * 21)'));
