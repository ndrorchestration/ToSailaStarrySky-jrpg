'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const world = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const validator = fs.readFileSync(path.join(root, 'modules', 'save-payload-validator.js'), 'utf8');

for (const name of [
  'snapshotPersistentState',
  'preparePersistentState',
  'restorePersistentState',
]) {
  assert(world.includes(name), 'world persistence authority missing: ' + name);
}

assert(runtime.includes('function buildSavePayload()'),
  'Preview runtime must own payload composition');
assert(runtime.includes('world.snapshotPersistentState()'),
  'payload composition must use world-owned snapshot authority');
assert(runtime.includes('window.AetherAirNavigation.exportPersistentState(airNavigationState)'),
  'payload must use air-navigation persistence authority');
assert(runtime.includes('window.AetherSavePayloadValidator.validatePayload(payload'),
  'snapshot and restore must use semantic payload validation');
assert(runtime.includes('function prepareSaveEnvelopeForApply(envelope)'),
  'restore preflight function missing');
assert(runtime.includes('world.preparePersistentState(payload.world, payload.quest)'),
  'restore preflight must delegate world rehydration planning');
assert(runtime.includes('window.AetherAirNavigation.restorePersistentState(payload.airNavigation)'),
  'restore preflight must rehydrate air navigation before mutation');
assert(runtime.includes('const prepared = prepareSaveEnvelopeForApply(envelope);'),
  'apply must require successful preflight');
assert(runtime.indexOf('const prepared = prepareSaveEnvelopeForApply(envelope);') <
       runtime.indexOf('prepared.preparedRoster.forEach'),
  'party mutation must happen only after complete preflight');
assert(runtime.indexOf('const prepared = prepareSaveEnvelopeForApply(envelope);') <
       runtime.indexOf('world.restorePersistentState(prepared.preparedWorld, payload.runtime);'),
  'world mutation must happen only after complete preflight');
assert(validator.includes("['sky_predator','wind_shear','corporate_intercept']"),
  'validator must encode the current Preview crossing layout');
assert(validator.includes("['sky_predator','wind_shear','aether_leak','corporate_intercept']"),
  'validator must retain historical four-hazard compatibility');

console.log('Aetherwake Preview persistence snapshot/restore contract: PASS');
