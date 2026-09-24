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
assert(runtime.includes('function buildSavePayload()'),
  'runtime snapshot ownership must now be explicit');
assert(runtime.includes('function prepareSaveEnvelopeForApply(envelope)'),
  'restore must have a preflight phase');
assert(runtime.includes('function applySaveEnvelope(envelope)'),
  'runtime restore ownership must now be explicit');
assert(runtime.indexOf('const prepared = prepareSaveEnvelopeForApply(envelope);') <
       runtime.indexOf('prepared.preparedRoster.forEach'),
  'restore preflight must complete before party mutation');

console.log('Aetherwake Preview persistence runtime seam: PASS');
