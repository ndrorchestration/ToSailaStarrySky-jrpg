'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const spritePath = path.join(root, 'modules', 'pixel-sprites.js');
const source = fs.readFileSync(spritePath, 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: spritePath });

const api = sandbox.window.AetherPixelSprites;
assert(api, 'pixel sprite authority was not exposed');
assert.strictEqual(api.VERSION, '0.3.0');
assert.strictEqual(api.validate(), true, 'pixel sprite registry failed validation');

assert.deepStrictEqual(Array.from(api.PALETTES.ender.H), [168, 82, 48],
  'Ender sprite hair must preserve canonical copper/auburn appearance');
assert.deepStrictEqual(Array.from(api.PALETTES.ender.G), [164, 119, 61],
  'Ender goggles must read brass/bronze');
assert.deepStrictEqual(Array.from(api.PALETTES.lyra.H), [162, 61, 46],
  'Lyra sprite must preserve canonical red hair');
assert.deepStrictEqual(Array.from(api.PALETTES.ionia.H), [218, 186, 118],
  'Ionia sprite must preserve canonical blond hair');

for (const id of ['ender','lyra','ionia','skyPredator','engineSpirit','corporateSalvager','settler']) {
  const sprite = api.get(id);
  assert(sprite, id + ' sprite missing');
  assert.strictEqual(sprite.width, 16);
  assert.strictEqual(sprite.height, 16);
  assert(sprite.frames.length >= 2, id + ' needs idle/walk frames');
}

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const spriteIndex = html.indexOf('modules/pixel-sprites.js');
const runtimeIndex = html.indexOf('aetherwake.js');
assert(spriteIndex >= 0 && spriteIndex < runtimeIndex,
  'pixel sprite authority must load before the integrated runtime');

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
for (const binding of [
  "sprites.draw('ender'",
  "sprites.draw('lyra'",
  "sprites.draw('engineSpirit'",
  "sprites.draw('corporateSalvager'",
  "sprites.draw('settler'"
]) {
  assert(runtime.includes(binding), 'missing current-main sprite binding: ' + binding);
}
assert(runtime.includes("throw new Error('AETHER_PIXEL_SPRITES_UNAVAILABLE')"),
  'sprite authority failure must remain visible/fail-closed');

console.log('Aetherwake current-main pixel sprite foundation: PASS');

const runtimeVisual = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(runtimeVisual.includes("sprites.draw('ionia'"), 'Ionia must use shared pixel sprite authority');
const npcStart = runtimeVisual.indexOf('function drawNPC(npc)');
const npcEnd = runtimeVisual.indexOf('function drawNPCElder', npcStart);
const npcDispatch = runtimeVisual.slice(npcStart, npcEnd);
for (const legacyRoutine of ['drawNPCElderRoutine','drawNPCSpiritRoutine','drawNPCChildRoutine','drawNPCSavagerRoutine']) {
  assert(!npcDispatch.includes(legacyRoutine + '('), 'legacy body routine still active: ' + legacyRoutine);
}
