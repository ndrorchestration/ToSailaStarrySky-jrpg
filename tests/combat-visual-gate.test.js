'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'combat-visual-stage.js'), 'utf8');
const battleBackdrop = fs.readFileSync(
  path.join(root, 'assets', 'preview', 'aetherwake-preview-battle-pixelart-v2.png')
);
assert.strictEqual(battleBackdrop.subarray(0, 8).toString('hex'), '89504e470d0a1a0a',
  'Sky Predator combat should ship its pixel-art battle vista');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'combat-visual-stage.js' });
const api = sandbox.window.AetherCombatVisual;

assert(api, 'combat visual stage API missing');
assert.strictEqual(api.VERSION, '0.6.0');
for (const fn of ['stage','drawBackdrop','drawPlayer','drawEnemy','drawTurnRail','enemySpriteId']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

const stage = api.stage(960, 640);
assert.strictEqual(stage.playerX, 374, 'combat player stage anchor drifted');
assert.strictEqual(stage.enemyX, 691, 'combat enemy stage anchor drifted');
assert.strictEqual(api.enemySpriteId({type:'skyPredator'}), 'skyPredator');
assert.strictEqual(api.enemySpriteId({type:'corporateSalvager'}), 'corporateSalvager');
assert.strictEqual(api.enemySpriteId({type:'engine_spirit'}), 'engineSpirit');

assert(!source.includes('applyDamage('), 'visual stage must not own damage resolution');
assert(!source.includes('changeResource('), 'visual stage must not own resources');
assert(!source.includes('eligibleAction'), 'visual stage must not own action eligibility');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.indexOf('modules/combat-visual-stage.js') >= 0, 'combat visual stage script missing');
assert(html.indexOf('modules/combat-visual-stage.js') < html.indexOf('aetherwake.js'),
  'combat visual stage must load before runtime');
assert(runtime.includes('visualStage.stage'),
  'combat renderer must use fixed cinematic stage anchors');
assert(runtime.includes('visualStage.drawBackdrop'),
  'combat renderer must use visual-stage backdrop');
assert(runtime.includes('visualStage.drawPlayer'),
  'combat renderer must use shared Ender visual');
assert(runtime.includes('visualStage.drawEnemy'),
  'combat renderer must use enemy visual stage');
assert(runtime.includes('visualStage.drawTurnRail'),
  'combat renderer must use turn hierarchy rail');
assert(source.includes('aetherwake-preview-battle-pixelart-v2.png'),
  'Sky Predator combat should use the authored pixel-art arena');
assert(source.includes('Grounded combat focus'),
  'combat player staging must use grounded contact-light treatment');
assert(source.includes('drawProvisionalFieldCharacter') && source.includes('scale: 2.45'),
  'combat Ender must prefer the reviewed provisional pixel field art before articulated fallback');
assert(source.includes('scale: 1.48') && source.includes('depth: 0.68'),
  'combat Ender must retain the bounded articulated fallback if provisional art is unavailable');
assert(!source.includes('rect(x - 58, y - 128, 116, 134)'),
  'combat player staging must not restore the old arena-obscuring glow rectangle');

const backdropCalls = { requested: [], images: [] };
const backdropSandbox = {
  window: {},
  globalThis: {},
  loadImage(asset, onLoad) {
    backdropCalls.requested.push(asset);
    const image = { width: 768, height: 512 };
    onLoad();
    return image;
  },
  image(...args) { backdropCalls.images.push(args); },
  noSmooth() {}, noStroke() {}, push() {}, pop() {}, fill() {}, rect() {},
};
vm.runInNewContext(source, backdropSandbox, { filename: 'combat-visual-stage-pixel-art.js' });
backdropSandbox.window.AetherCombatVisual.drawBackdrop({
  width: 960,
  height: 640,
  now: 0,
  domain: 'ground',
  enemy: { type: 'skyPredator' },
});
assert.deepStrictEqual(backdropCalls.requested, ['assets/preview/aetherwake-preview-battle-pixelart-v2.png'],
  'the battle vista should be requested once for the encounter');
assert.strictEqual(backdropCalls.images.length, 1,
  'the Sky Predator encounter should use the authored pixel-art battle vista');

const actorDraws = [];
const behaviorSandbox = {
  window: {
    AetherPixelSprites: {
      validate: () => true,
      drawShadow() {},
      drawPreview(id, x, y, options) { actorDraws.push({ mode: 'preview', id, frame: options.frame }); },
      drawBattleEnemy(id, x, y, options) { actorDraws.push({ mode: 'battle', id, frame: options.frame }); },
      draw() { actorDraws.push({ mode: 'fallback' }); },
    },
  },
  globalThis: {},
  noStroke() {}, stroke() {}, strokeWeight() {},
  fill() {},
  rect() {}, ellipse() {}, line() {},
};
vm.runInNewContext(source, behaviorSandbox, { filename: 'combat-visual-stage-behavior.js' });
const behaviorApi = behaviorSandbox.window.AetherCombatVisual;
behaviorApi.drawPlayer({ x: 326, y: 371, now: 440 });
behaviorApi.drawEnemy({
  x: 691,
  y: 320,
  now: 360,
  enemy: { type: 'skyPredator', hp: 100, maxHp: 100 },
});
assert.deepStrictEqual(actorDraws, [
  { mode: 'preview', id: 'ender', frame: 0 },
  { mode: 'battle', id: 'skyPredator', frame: 0 },
], 'combat should use the detailed Ender atlas and Sky Predator battle atlas');

console.log('Aetherwake representative combat visual gate: PASS');
