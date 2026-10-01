'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

for (const required of [
  'function validateSavePayloadBeforeWrite(payload)',
  'function loadSemanticallyValidSaveCandidate(slot)',
  'function captureLiveRuntimeForLoadRollback()',
  'function restoreLiveRuntimeAfterFailedLoad(snapshot)',
  "runLoadTestHook('after-party')",
  "runLoadTestHook('after-world')",
  "runLoadTestHook('after-air-navigation')",
  "runLoadTestHook('before-commit')",
  'LOAD_APPLY_AND_ROLLBACK_FAILED:',
  '{ candidateResolver: loadSemanticallyValidSaveCandidate }',
  'preserveBackup = Boolean(priorCandidate && priorCandidate.semanticBackupRecovery)',
  'semanticBackupRecovery: true',
  'window.AetherSaveSystem.loadBackup(slot)',
  'window._lastLoadRollback',
  'window._lastLoadRecovery',
]) {
  assert(runtime.includes(required), 'missing persistence coordinator contract: ' + required);
}

const buildAt = runtime.indexOf('function buildSavePayload()');
const preflightAt = runtime.indexOf('function validateSavePayloadBeforeWrite(payload)');
const saveAt = runtime.indexOf('function saveToSlot(slot)');
const rotateAt = runtime.indexOf('window.AetherSaveSystem.rotateAutosave(');
const directSaveAt = runtime.indexOf('window.AetherSaveSystem.save(\n      slot,');
const applyAt = runtime.indexOf('function applySaveEnvelope(envelope)');
const rollbackCaptureAt = runtime.indexOf('const rollbackSnapshot = captureLiveRuntimeForLoadRollback();', applyAt);

assert(buildAt >= 0 && preflightAt > buildAt, 'semantic preflight must be defined after payload composition authority');
assert(saveAt >= 0, 'manual save coordinator missing');
assert(runtime.indexOf('validateSavePayloadBeforeWrite(payload);', saveAt) < directSaveAt,
  'manual save must semantic-preflight before persistent write');
assert(runtime.indexOf('validateSavePayloadBeforeWrite(payload);', rotateAt - 1200) < rotateAt,
  'autosave must semantic-preflight before rotation');
assert(rollbackCaptureAt > applyAt,
  'load apply must capture rollback state before mutating canonical runtime');
assert(runtime.indexOf('restoreLiveRuntimeAfterFailedLoad(rollbackSnapshot);', applyAt) > rollbackCaptureAt,
  'failed load apply must restore captured runtime state');
assert(runtime.indexOf('window._lastLoadResult = loaded;', runtime.indexOf('function loadFromSlot(slot)')) >
       runtime.indexOf('const applied = applySaveEnvelope(loaded.envelope);', runtime.indexOf('function loadFromSlot(slot)')),
  'successful-load evidence must be written only after apply commits');

console.log('Aetherwake persistence coordinator recovery contract: PASS');
