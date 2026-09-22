'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');

const uiSource = fs.readFileSync(path.join(root, 'modules', 'aether-ui-system.js'), 'utf8');
const uiSandbox = { window: {}, globalThis: {} };
vm.runInNewContext(uiSource, uiSandbox, { filename: 'aether-ui-system.js' });
const ui = uiSandbox.window.AetherUI;
assert(ui, 'AetherUI system missing');
assert.strictEqual(ui.VERSION, '0.2.0');
for (const fn of ['panel','primaryButton','sectionLabel','divider','keyHint','meter','statRow']) {
  assert.strictEqual(typeof ui[fn], 'function', 'AetherUI.' + fn + ' missing');
}
assert(ui.motion, 'AetherUI motion helpers missing');
for (const fn of ['clamp01','easeOutCubic','easeInOutCubic','enter','pulse']) {
  assert.strictEqual(typeof ui.motion[fn], 'function', 'AetherUI.motion.' + fn + ' missing');
}
assert.strictEqual(ui.motion.clamp01(-1), 0);
assert.strictEqual(ui.motion.clamp01(2), 1);
assert.strictEqual(ui.motion.enter(0, 240), 0);
assert.strictEqual(ui.motion.enter(240, 240), 1);

const source = fs.readFileSync(path.join(root, 'modules', 'title-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'title-visual-stage.js' });

const api = sandbox.window.AetherTitleVisual;
assert(api, 'title visual stage missing');
assert.strictEqual(api.VERSION, '0.3.0');
for (const fn of ['draw','drawSky','drawHero','drawTitleCopy','drawAmbientFrame']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'title must reuse shared Dragonfly visual authority');
assert(source.includes("scale: 1.58"),
  'title must present Dragonfly as a hero-scale object');
assert(!source.includes('ellipse('),
  'title visual stage must avoid old smooth ellipse island treatment');
assert(source.includes("ui.primaryButton('NEW GAME'"),
  'title New Game premium command affordance missing');
assert(source.includes("ui.keyHint('ENTER'"),
  'title confirmation hint must use shared key-hint primitive');
assert(source.includes('ui.motion.enter'),
  'title entrance motion must use shared motion authority');
assert(source.includes('A SOLARPUNK SKY-FANTASY JRPG'),
  'title identity lockup missing');
assert(source.includes('DRAGONFLY SYSTEMS // READY'),
  'title operational status footer missing');

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/aether-ui-system.js') >= 0,
  'Aetherwake UI system script missing');
assert(html.indexOf('modules/aether-ui-system.js') < html.indexOf('modules/title-visual-stage.js'),
  'Aetherwake UI system must load before title visual stage');
assert(html.indexOf('modules/title-visual-stage.js') >= 0,
  'title visual stage script missing');
assert(html.indexOf('modules/title-visual-stage.js') < html.indexOf('aetherwake.js'),
  'title visual stage must load before runtime');
assert(runtime.includes('AetherTitleVisual.draw'),
  'runtime title screen does not delegate to title visual stage');

console.log('Aetherwake premium UI + title visual contracts: PASS');
