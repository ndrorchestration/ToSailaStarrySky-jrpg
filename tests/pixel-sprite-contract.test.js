'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const spritePath = path.join(root, 'modules', 'pixel-sprites.js');
const source = fs.readFileSync(spritePath, 'utf8');

const sandbox = {
  window: {},
  globalThis: {},
};
vm.runInNewContext(source, sandbox, { filename: spritePath });

const api = sandbox.window.AetherPixelSprites;
assert(api, 'pixel sprite authority was not exposed');
assert.strictEqual(api.VERSION, '0.2.0');
assert.strictEqual(api.validate(), true, 'pixel sprite registry failed validation');

for (const id of ['ender', 'lyra', 'ionia', 'skyPredator', 'engineSpirit', 'corporateSalvager']) {
  const sprite = api.get(id);
  assert(sprite, id + ' sprite missing');
  assert.strictEqual(sprite.width, 16, id + ' width drifted');
  assert.strictEqual(sprite.height, 16, id + ' height drifted');
  assert(sprite.frames.length >= 2, id + ' needs at least idle/walk frames');
  assert(sprite.frames.every(frame =>
    frame.length === 16 && frame.every(row => row.length === 16)
  ), id + ' frame geometry is invalid');
}

for (const htmlName of ['index.html', 'index-embedded.html']) {
  const html = fs.readFileSync(path.join(root, htmlName), 'utf8');
  const spriteIndex = html.indexOf('modules/pixel-sprites.js');
  const runtimeIndex = html.indexOf('aetherwake.js');
  const charCreateIndex = html.indexOf('modules/char-create.js');
  assert(spriteIndex >= 0, htmlName + ' does not load pixel-sprites.js');
  assert(spriteIndex < runtimeIndex, htmlName + ' loads sprites after runtime authority');
  assert(spriteIndex < charCreateIndex, htmlName + ' loads sprites after char-create');
}

const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(runtime.includes("sprites.draw('ender'"),
  'overworld Ender is not bound to shared sprite authority');
assert(runtime.includes("sprites.draw('ionia'"),
  'Ionia world renderer is not bound to shared sprite authority');
assert(runtime.includes("sprites.draw('lyra'"),
  'Lyra world renderer is not bound to shared sprite authority');
assert(runtime.includes("battleSprites.draw('ender'"),
  'combat scene is not bound to Ender sprite authority');
assert(runtime.includes("battleSprites.draw('lyra'") &&
  runtime.includes("battleSprites.draw('ionia'"),
  'combat scene is not bound to companion sprite authority');
assert(runtime.includes("AetherPixelSprites.draw('skyPredator'"),
  'opening combat enemy is not bound to pixel sprite authority');
assert(runtime.includes("sprites.draw('engineSpirit'"),
  'engine spirit world renderer is not bound to pixel sprite authority');
assert(runtime.includes("sprites.draw('corporateSalvager'"),
  'corporate salvager world renderer is not bound to pixel sprite authority');

const onboarding = fs.readFileSync(path.join(root, 'modules', 'char-create.js'), 'utf8');
assert(onboarding.includes("sprites.draw('ender'"),
  'Ender onboarding preview does not use shared sprite authority');
assert(onboarding.includes("spriteId = isEnder ? 'ender'"),
  'party-review previews do not use crew sprite IDs');

console.log('Aetherwake pixel sprite foundation: PASS');
