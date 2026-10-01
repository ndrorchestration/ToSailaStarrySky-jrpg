'use strict';

const assert = require('assert');
const saveV1 = require('../modules/save-system.js');
const air = require('../modules/air-navigation.js');
const routeNetwork = require('../modules/route-network-state.js');
const schemaV2 = require('../modules/save-schema-v2-proof.js');

assert.strictEqual(schemaV2.SOURCE_SCHEMA_VERSION, 1);
assert.strictEqual(schemaV2.TARGET_SCHEMA_VERSION, 2);
assert.strictEqual(routeNetwork.PERSISTENCE_VERSION, 1);
assert.deepStrictEqual(
  routeNetwork.OPERATIONAL_STATES,
  ['open','provisional','shifted','closed']
);

// Knowledge and condition are independent.
const defaultState = routeNetwork.createState();
assert.strictEqual(routeNetwork.conditionFor(defaultState, 'rootline-west'), 'open');
assert.deepStrictEqual(defaultState.operationalStates, {},
  'OPEN must remain the sparse default rather than redundant stored state');

const shifted = routeNetwork.setCondition(defaultState, 'rootline-west', 'shifted');
assert.strictEqual(routeNetwork.conditionFor(shifted, 'rootline-west'), 'shifted');
assert.strictEqual(routeNetwork.conditionFor(defaultState, 'rootline-west'), 'open');

const resetOpen = routeNetwork.setCondition(shifted, 'rootline-west', 'open');
assert.deepStrictEqual(resetOpen.operationalStates, {},
  'returning to OPEN should remove the sparse override');

assert.throws(
  () => routeNetwork.setCondition(defaultState, 'unknown-route', 'shifted'),
  /ROUTE_NETWORK_ROUTE_UNKNOWN/
);
assert.throws(
  () => routeNetwork.setCondition(defaultState, 'rootline-west', 'mystery'),
  /ROUTE_NETWORK_CONDITION_INVALID/
);
assert.throws(
  () => routeNetwork.validatePersistentState({
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: [],
    precedents: [],
    futureField: true,
  }),
  /ROUTE_NETWORK_UNKNOWN_KEY:futureField/
);
assert.throws(
  () => routeNetwork.validatePersistentState({
    persistenceVersion: 2,
    operationalStates: {},
    discoveredClues: [],
    precedents: [],
  }),
  /ROUTE_NETWORK_VERSION_INVALID/
);

// Build a representative schema-v1 envelope with route knowledge already present.
const airState = air.exportPersistentState(air.createState({
  x: 12,
  y: 19,
  altitude: 'cruise',
  speed: 1,
  discoveredRoutes: ['rootline-west'],
}));

const v1 = saveV1.makeEnvelope('manual-1', {
  runtime: { scene: 'airship' },
  world: {},
  quest: {},
  party: {},
  airNavigation: airState,
}, {
  gameVersion: '0.1.0-proof',
  chapter: 'Chapter I — First Wake',
  location: 'Open Sky',
});

const v2 = schemaV2.migrateAndValidate(v1);
assert.strictEqual(v2.schemaVersion, 2);
assert.deepStrictEqual(
  v2.payload.airNavigation.discoveredRoutes,
  ['rootline-west'],
  'v1 -> v2 migration must preserve existing route knowledge'
);
assert.deepStrictEqual(
  v2.payload.routeNetwork,
  {
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: [],
    precedents: [],
  },
  'v1 -> v2 migration must create a conservative empty route-network state'
);
assert.strictEqual(
  routeNetwork.conditionFor(
    routeNetwork.restorePersistentState(v2.payload.routeNetwork),
    'rootline-west'
  ),
  'open',
  'migration must default route condition to OPEN'
);
assert(!v2.payload.routeNetwork.discoveredClues.includes('rootline-west-upper-trace'),
  'migration must not invent route clues');
assert(!v2.payload.routeNetwork.precedents.includes('LOCAL_ROUTE_ASSISTANCE'),
  'migration must not invent route precedents');

// New v2 state round-trips independently of route knowledge.
let routeState = routeNetwork.createState();
routeState = routeNetwork.discoverClue(routeState, 'rootline-west-upper-trace');
routeState = routeNetwork.setCondition(routeState, 'rootline-west', 'shifted');
routeState = routeNetwork.recordPrecedent(routeState, 'LOCAL_ROUTE_ASSISTANCE');
const persistedRoute = routeNetwork.exportPersistentState(routeState);
assert(routeNetwork.validatePersistentState(persistedRoute));
const restoredRoute = routeNetwork.restorePersistentState(persistedRoute);
assert.strictEqual(routeNetwork.conditionFor(restoredRoute, 'rootline-west'), 'shifted');
assert.deepStrictEqual(restoredRoute.discoveredClues, ['rootline-west-upper-trace']);
assert.deepStrictEqual(restoredRoute.precedents, ['LOCAL_ROUTE_ASSISTANCE']);

function makeLocalStorage() {
  const map = new Map();
  return {
    setItem(k,v){ map.set(k,String(v)); },
    getItem(k){ return map.has(k) ? map.get(k) : null; },
    removeItem(k){ map.delete(k); },
  };
}

function keyFromPath(path) {
  return path.replace('localStorage://', '');
}

function makeFutureEnvelope(slot, marker) {
  const current = saveV1.makeEnvelope(slot, { marker }, { gameVersion: '2.0.0-proof' });
  return schemaV2.migrateAndValidate(current);
}

// Downgrade safety: hardened v1 must never overwrite a v2 primary.
const localStorage = makeLocalStorage();
const oldBuild = saveV1._createForTesting({ localStorage });

const seededManual = oldBuild.save('manual-2', { marker: 'v1-seed' }, { gameVersion: '1.0.0' });
const manualKey = keyFromPath(seededManual.path);
const protectedManual = makeFutureEnvelope('manual-2', 'v2-primary');
localStorage.setItem(manualKey, JSON.stringify(protectedManual));

assert.throws(
  () => oldBuild.save('manual-2', { marker: 'downgrade-write' }, { gameVersion: '1.0.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-2:2:primary/
);
assert.strictEqual(
  JSON.parse(localStorage.getItem(manualKey)).payload.marker,
  'v2-primary',
  'hardened v1 must preserve v2 primary bytes'
);

// A v2 backup is protected even when the primary is unusable.
const seededBackup = oldBuild.save('manual-3', { marker: 'v1-seed' }, { gameVersion: '1.0.0' });
const backupKey = keyFromPath(seededBackup.path);
localStorage.setItem(backupKey, '{"broken":');
localStorage.setItem(backupKey + '.bak', JSON.stringify(makeFutureEnvelope('manual-3', 'v2-backup')));

assert.throws(
  () => oldBuild.save('manual-3', { marker: 'downgrade-write' }, { gameVersion: '1.0.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-3:2:backup/
);
assert.strictEqual(
  JSON.parse(localStorage.getItem(backupKey + '.bak')).payload.marker,
  'v2-backup',
  'hardened v1 must preserve v2 backup bytes'
);

// Autosave rotation skips protected v2 slots.
for (const slot of oldBuild.AUTOSAVE_SLOTS) oldBuild.remove(slot);
const auto0Seed = oldBuild.save('autosave-0', { marker: 'seed' }, { gameVersion: '1.0.0' });
const auto0Key = keyFromPath(auto0Seed.path);
localStorage.setItem(auto0Key, JSON.stringify(makeFutureEnvelope('autosave-0', 'v2-auto-0')));

const rotated = oldBuild.rotateAutosave({ marker: 'old-build-new-auto' }, { gameVersion: '1.0.0' });
assert.notStrictEqual(rotated.envelope.slot, 'autosave-0',
  'hardened v1 autosave rotation must skip a v2 slot');
assert.strictEqual(
  JSON.parse(localStorage.getItem(auto0Key)).payload.marker,
  'v2-auto-0'
);

// If all autosave slots are v2, v1 must fail closed.
for (const slot of oldBuild.AUTOSAVE_SLOTS) {
  oldBuild.remove(slot);
  const seed = oldBuild.save(slot, { marker: 'seed' }, { gameVersion: '1.0.0' });
  localStorage.setItem(keyFromPath(seed.path), JSON.stringify(makeFutureEnvelope(slot, 'v2-' + slot)));
}
assert.throws(
  () => oldBuild.rotateAutosave({ marker: 'must-not-write' }, { gameVersion: '1.0.0' }),
  /SAVE_AUTOSAVE_ALL_SLOTS_FUTURE_PROTECTED/
);

// The v1 system itself must reject v2 load/migration.
assert.throws(
  () => saveV1.migrateEnvelope(v2),
  /SAVE_SCHEMA_FUTURE_UNSUPPORTED:2/
);

console.log('Aetherwake save schema v2 route-network proof: PASS');
