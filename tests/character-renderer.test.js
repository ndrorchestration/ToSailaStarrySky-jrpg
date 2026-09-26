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
assert.strictEqual(api.VERSION, '0.4.0');
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
assert(api.PROFILES.ender.freckles === true, 'Ender freckles cue missing');
assert(api.PROFILES.reson.mustache === true && api.PROFILES.reson.cap, 'Reson cap/mustache authority missing');
assert(api.PROFILES.aepex.eyebrowNotch === true, 'Aepex eyebrow-notch authority missing');
assert(api.PROFILES.ionia.hairMode === 'curlyShoulder', 'Ionia curly shoulder-length hair authority missing');
assert(api.PROFILES.lyra.hairMode === 'longRed', 'Lyra long red hair authority missing');
assert(api.PROFILES.ender.fieldVest && api.PROFILES.ender.embroidery,
  'Ender reference-backed embroidered field-vest silhouette missing');
assert(api.PROFILES.reson.heavyHarness && api.PROFILES.reson.utilityRig && api.PROFILES.reson.rolledSleeves,
  'Reson reference-backed protector harness/utility silhouette missing');
assert(api.PROFILES.aepex.techRig && api.PROFILES.aepex.neckGoggles && api.PROFILES.aepex.asymmetry,
  'Aepex reference-backed technical rig/asymmetry silhouette missing');
assert(api.PROFILES.ionia.tailoredLayer, 'Ionia tailored layered silhouette missing');
assert(api.PROFILES.lyra.layeredDrape, 'Lyra layered drape silhouette missing');
assert(api.PROFILES.reson.heightScale > api.PROFILES.aepex.heightScale,
  'Reson must remain taller than Aepex');
assert(api.PROFILES.aepex.heightScale > api.PROFILES.ender.heightScale,
  'Aepex must remain taller than Ender');
assert(api.PROFILES.ender.heightScale > api.PROFILES.ionia.heightScale &&
       api.PROFILES.ender.heightScale > api.PROFILES.lyra.heightScale,
  'Ender must remain taller than the Ionia/Lyra shortest tier');
assert.strictEqual(api.PROFILES.ionia.heightScale, api.PROFILES.lyra.heightScale,
  'Ionia/Lyra exact relative height remains unresolved and must stay tied');
assert(source.includes('Reference-backed costume silhouette cues'),
  'renderer must document reference-backed costume boundary');
assert(source.includes('Dialogue-scale identity'),
  'dialogue portraits must retain reference-backed costume identity cues');
assert(api.PROFILES.ionia.hair[0] > api.PROFILES.ionia.hair[2], 'Ionia hair must read blond/warm rather than brown');
assert(api.PROFILES.lyra.hair[0] > api.PROFILES.lyra.hair[1] * 2, 'Lyra hair must read red');

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
