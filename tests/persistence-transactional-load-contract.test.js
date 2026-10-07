'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

for (const marker of [
  'function runLoadTestHook(stage, context)',
  'function captureLiveRuntimeForLoadRollback()',
  'function restoreLiveRuntimeAfterFailedLoad(snapshot)',
  "runLoadTestHook('after-party'",
  "runLoadTestHook('after-world'",
  "runLoadTestHook('before-commit'",
  "runLoadTestHook('rollback-start'",
  'const rollbackSnapshot = captureLiveRuntimeForLoadRollback();',
  'restoreLiveRuntimeAfterFailedLoad(rollbackSnapshot);',
  'LOAD_APPLY_AND_ROLLBACK_FAILED:',
  'window._lastLoadRollback = {',
  'restored: true',
  'restored: false',
]) {
  assert(runtime.includes(marker), 'transactional load contract missing: ' + marker);
}

const preparePos = runtime.indexOf('const prepared = prepareSaveEnvelopeForApply(envelope);');
const rollbackPos = runtime.indexOf('const rollbackSnapshot = captureLiveRuntimeForLoadRollback();');
const partyMutationPos = runtime.indexOf('Object.assign(window.ROSTER[index]', rollbackPos);
assert(preparePos >= 0 && rollbackPos > preparePos,
  'semantic preparation must complete before rollback snapshot capture');
assert(partyMutationPos > rollbackPos,
  'rollback snapshot must be captured before canonical roster mutation');

const applyStart = runtime.indexOf('function applySaveEnvelope(envelope)');
const applyEnd = runtime.indexOf('window._persistenceRuntime = Object.freeze', applyStart);
const apply = runtime.slice(applyStart, applyEnd);
assert(apply.includes("runLoadTestHook('after-party'"),
  'apply transaction lacks post-party fault boundary');
assert(apply.includes("runLoadTestHook('after-world'"),
  'apply transaction lacks post-world fault boundary');
assert(apply.includes("runLoadTestHook('before-commit'"),
  'apply transaction lacks pre-commit fault boundary');
assert(apply.includes('window._lastLoadRollback = null;'),
  'successful transaction must clear stale rollback evidence');

const loadStart = runtime.indexOf('function loadFromSlot(slot)');
const loadEnd = runtime.indexOf('function openSaveLoadMenu', loadStart);
const load = runtime.slice(loadStart, loadEnd);
assert(load.includes('window._lastLoadResult = null;'),
  'failed player load must clear stale success evidence');
assert(!load.includes('window._lastLoadRollback = null;'),
  'load failure handler must not erase rollback evidence emitted by apply transaction');

console.log('Aetherwake transactional load rollback contract: PASS');
