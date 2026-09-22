'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'combat-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'combat-visual-stage.js' });
const api = sandbox.window.AetherCombatVisual;

assert(api, 'combat visual stage API missing');
assert.strictEqual(api.VERSION, '0.1.0');
for (const fn of ['stage','drawBackdrop','drawPlayer','drawEnemy','drawTurnRail','enemySpriteId']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

const stage = api.stage(960, 640);
assert.strictEqual(stage.playerX, 326, 'combat player stage anchor drifted');
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
assert(runtime.includes('AetherCombatVisual.stage'),
  'combat renderer must use fixed cinematic stage anchors');
assert(runtime.includes('AetherCombatVisual.drawBackdrop'),
  'combat renderer must use visual-stage backdrop');
assert(runtime.includes('AetherCombatVisual.drawPlayer'),
  'combat renderer must use shared Ender visual');
assert(runtime.includes('AetherCombatVisual.drawEnemy'),
  'combat renderer must use enemy visual stage');
assert(runtime.includes('AetherCombatVisual.drawTurnRail'),
  'combat renderer must use turn hierarchy rail');

console.log('Aetherwake representative combat visual gate: PASS');
