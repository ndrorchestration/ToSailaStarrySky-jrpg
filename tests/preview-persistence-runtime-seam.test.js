'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

for (const script of [
  'modules/save-system.js',
  'modules/save-payload-validator.js',
]) {
  assert(html.includes('<script src="' + script + '"></script>'),
    'Preview runtime must load ' + script);
  assert(html.indexOf(script) < html.indexOf('aetherwake.js'),
    script + ' must load before aetherwake.js');
}

assert(runtime.includes("throw new Error('AETHER_SAVE_SYSTEM_UNAVAILABLE')"),
  'setup must fail closed when the save system is unavailable');
assert(runtime.includes("throw new Error('AETHER_SAVE_PAYLOAD_VALIDATOR_UNAVAILABLE')"),
  'setup must fail closed when the semantic validator is unavailable');
assert(runtime.includes('window._saveSystem = window.AetherSaveSystem;'),
  'runtime must expose the bound save-system authority');
assert(runtime.includes('window._savePayloadValidator = window.AetherSavePayloadValidator;'),
  'runtime must expose the bound save validator authority');
assert(!runtime.includes('function buildSavePayload()'),
  'foundation seam must not silently claim live snapshot ownership');
assert(!runtime.includes('function applySaveEnvelope(envelope)'),
  'foundation seam must not silently claim live restore ownership');

console.log('Aetherwake Preview persistence runtime seam: PASS');
