'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'character-renderer.js'), 'utf8');

const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'character-renderer.js' });
const api = sandbox.window.AetherCharacterRenderer;

assert(api, 'articulated character renderer missing');
assert.strictEqual(api.VERSION, '0.2.0');
assert(api.validate(), 'articulated character profiles must validate');
for (const id of ['ender','reson','aepex','ionia','lyra']) {
  assert(api.PROFILES[id], id + ' articulated profile missing');
}
assert.strictEqual(typeof api.draw, 'function', 'character draw method missing');
assert.strictEqual(typeof api.drawPortrait, 'function', 'character portrait method missing');
assert(source.includes('const gait = Math.sin(m.phase)'), 'walk gait animation missing');
assert(source.includes('const breath = Math.sin(m.phase*0.5)'), 'breathing animation missing');
assert(source.includes('armSwing'), 'secondary arm motion missing');
assert(source.includes("action === 'run'"), 'run animation state missing');
assert(source.includes("action === 'talk'"), 'talk animation state missing');
assert(source.includes("action === 'attack'"), 'attack animation state missing');
assert(source.includes('profile.embroidery'), 'Ender embroidered vest cue missing');
assert(source.includes('profile.harness'), 'Aepex harness cue missing');
assert(source.includes('profile.tattoos'), 'Aepex tattoo silhouette cue missing');
assert(source.includes('profile.goggles'), 'Ender goggles silhouette cue missing');
assert(source.includes('profile.scarf'), 'Reson scarf secondary-motion cue missing');

const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.includes('modules/character-renderer.js'), 'character renderer script missing from packaged runtime');
assert(html.indexOf('modules/character-renderer.js') < html.indexOf('modules/preview-world-presentation.js'),
  'character renderer must load before world presentation');
assert(html.indexOf('modules/character-renderer.js') < html.indexOf('modules/first-wake-visual-stage.js'),
  'character renderer must load before First Wake visual stage');

const world = fs.readFileSync(path.join(root, 'modules', 'preview-world-presentation.js'), 'utf8');
const wake = fs.readFileSync(path.join(root, 'modules', 'first-wake-visual-stage.js'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(world.includes('AetherCharacterRenderer'), 'world must prefer articulated characters');
assert(wake.includes('AetherCharacterRenderer'), 'opening must prefer articulated characters');
assert(runtime.includes('AetherCharacterRenderer'), 'dialogue must prefer articulated characters');

console.log('Aetherwake articulated character renderer contract: PASS');
