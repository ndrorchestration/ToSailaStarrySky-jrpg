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
assert.strictEqual(api.VERSION, '0.2.0');
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

console.log('Aetherwake title visual stage contract: PASS');
