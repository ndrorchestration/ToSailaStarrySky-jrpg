'use strict';

const assert = require('assert');
const path = require('path');

const legacyRoot = process.argv[2];
if (!legacyRoot) throw new Error('LEGACY_V1_ROOT_REQUIRED');

const current = require('../modules/save-system.js');
const legacy = require(path.resolve(legacyRoot, 'modules', 'save-system.js'));

assert.strictEqual(current.SCHEMA_VERSION, 2,
  'current candidate must be schema v2');
assert.strictEqual(legacy.SCHEMA_VERSION, 1,
  'cross-version fixture must be the protected schema-v1 baseline');

function makeLocalStorage() {
  const map = new Map();
  return {
    setItem(k,v){ map.set(k,String(v)); },
    getItem(k){ return map.has(k) ? map.get(k) : null; },
    removeItem(k){ map.delete(k); },
  };
}

function pathKey(saveResult) {
  return saveResult.path.replace('localStorage://', '');
}

function v2Envelope(slot, marker) {
  return current.makeEnvelope(slot, {
    marker,
    routeNetwork: {
      persistenceVersion: 1,
      operationalStates: {},
      discoveredClues: [],
      precedents: [],
    },
  }, { gameVersion: '2.0.0-cross-version' });
}

const localStorage = makeLocalStorage();
const oldBuild = legacy._createForTesting({ localStorage });

// v2 primary: old v1 build must refuse overwrite and preserve bytes.
const manualSeed = oldBuild.save('manual-1', { marker: 'v1-seed' }, { gameVersion: '1.0.0' });
const manualKey = pathKey(manualSeed);
const primaryV2 = v2Envelope('manual-1', 'v2-primary');
const primaryBytes = JSON.stringify(primaryV2);
localStorage.setItem(manualKey, primaryBytes);

assert.throws(
  () => oldBuild.save('manual-1', { marker: 'old-write' }, { gameVersion: '1.0.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-1:2:primary/
);
assert.strictEqual(localStorage.getItem(manualKey), primaryBytes,
  'protected v2 primary bytes changed under v1 writer');

// v2 backup: corrupt v1-visible primary must not allow destructive overwrite.
const backupSeed = oldBuild.save('manual-2', { marker: 'v1-seed' }, { gameVersion: '1.0.0' });
const backupKey = pathKey(backupSeed);
localStorage.setItem(backupKey, '{"broken":');
const backupV2Bytes = JSON.stringify(v2Envelope('manual-2', 'v2-backup'));
localStorage.setItem(backupKey + '.bak', backupV2Bytes);

assert.throws(
  () => oldBuild.save('manual-2', { marker: 'old-write' }, { gameVersion: '1.0.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-2:2:backup/
);
assert.strictEqual(localStorage.getItem(backupKey + '.bak'), backupV2Bytes,
  'protected v2 backup bytes changed under v1 writer');

// Autosave: protected v2 slot must be skipped.
for (const slot of oldBuild.AUTOSAVE_SLOTS) oldBuild.remove(slot);
const autoSeed = oldBuild.save('autosave-0', { marker: 'seed' }, { gameVersion: '1.0.0' });
const autoKey = pathKey(autoSeed);
const autoV2Bytes = JSON.stringify(v2Envelope('autosave-0', 'v2-auto'));
localStorage.setItem(autoKey, autoV2Bytes);

const rotated = oldBuild.rotateAutosave({ marker: 'old-new-auto' }, { gameVersion: '1.0.0' });
assert.notStrictEqual(rotated.envelope.slot, 'autosave-0',
  'legacy v1 autosave selected a protected v2 slot');
assert.strictEqual(localStorage.getItem(autoKey), autoV2Bytes,
  'legacy v1 autosave changed protected v2 bytes');

// Every autosave v2: old build must fail closed.
for (const slot of oldBuild.AUTOSAVE_SLOTS) {
  oldBuild.remove(slot);
  const seed = oldBuild.save(slot, { marker: 'seed' }, { gameVersion: '1.0.0' });
  localStorage.setItem(pathKey(seed), JSON.stringify(v2Envelope(slot, 'v2-' + slot)));
}
assert.throws(
  () => oldBuild.rotateAutosave({ marker: 'must-not-write' }, { gameVersion: '1.0.0' }),
  /SAVE_AUTOSAVE_ALL_SLOTS_FUTURE_PROTECTED/
);

// Old build must reject v2 load/migration.
assert.throws(
  () => legacy.migrateEnvelope(v2Envelope('manual-3', 'v2-load')),
  /SAVE_SCHEMA_FUTURE_UNSUPPORTED:2/
);

console.log('Aetherwake v1 -> v2 downgrade overwrite guard: PASS');
