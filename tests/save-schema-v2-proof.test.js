'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const saveV1 = require('../modules/save-system.js');
const air = require('../modules/air-navigation.js');
const proof = require('../modules/save-schema-v2-proof.js');

assert.strictEqual(proof.VERSION, '0.1.0');
assert.strictEqual(proof.SOURCE_SCHEMA_VERSION, 1);
assert.strictEqual(proof.TARGET_SCHEMA_VERSION, 2);
assert.strictEqual(proof.ROUTE_NETWORK_PERSISTENCE_VERSION, 1);
assert.deepStrictEqual(proof.OPERATIONAL_STATES, ['open','provisional','shifted','closed']);

const fixture = JSON.parse(fs.readFileSync(
  path.join(__dirname, 'fixtures', 'saves', 'schema-v1-manual-1.json'),
  'utf8'
));

// Build a checksum-valid v1 fixture carrying existing route knowledge.
const v1 = JSON.parse(JSON.stringify(fixture));
v1.payload.airNavigation = air.exportPersistentState(air.createState({
  x: 12,
  y: 19,
  altitude: 'cruise',
  speed: 1,
  discoveredRoutes: ['rootline-west'],
}));
const v1Body = { ...v1 };
delete v1Body.checksum;
v1.checksum = saveV1.checksum(v1Body);
assert.strictEqual(saveV1.validateEnvelope(v1), true);

const migrated = proof.migrateV1ToV2(v1);
assert.strictEqual(migrated.schemaVersion, 2);
assert.strictEqual(proof.validateV2Envelope(migrated), true);
assert(migrated.payload.airNavigation.discoveredRoutes.includes('rootline-west'),
  'v1 route knowledge must survive migration');
assert.deepStrictEqual(migrated.payload.routeNetwork.operationalStates, {},
  'v1 migration must not invent non-open route conditions');
assert.deepStrictEqual(migrated.payload.routeNetwork.discoveredClues, [],
  'v1 migration must not invent route clues');
assert.deepStrictEqual(migrated.payload.routeNetwork.precedents, [],
  'v1 migration must not invent precedents');
assert.strictEqual(proof.operationalState(migrated.payload.routeNetwork, 'rootline-west'), 'open',
  'sparse migrated route state must default deterministically to OPEN');

const shifted = proof.withRouteNetworkState(migrated, 'rootline-west', 'shifted');
assert.strictEqual(proof.validateV2Envelope(shifted), true);
assert.strictEqual(proof.operationalState(shifted.payload.routeNetwork, 'rootline-west'), 'shifted');
assert(migrated.payload.routeNetwork.operationalStates['rootline-west'] === undefined,
  'route-state mutation must not mutate source envelope');

assert.throws(
  () => proof.createRouteNetwork({ operationalStates: { 'missing-route': 'shifted' } }),
  /ROUTE_NETWORK_ROUTE_UNKNOWN/,
  'unknown route IDs must fail closed'
);
assert.throws(
  () => proof.createRouteNetwork({ operationalStates: { 'rootline-west': 'magic' } }),
  /ROUTE_NETWORK_STATE_UNKNOWN/,
  'unknown operational states must fail closed'
);
assert.throws(
  () => proof.validateRouteNetwork({
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: [],
    precedents: [],
    futureField: true,
  }),
  /ROUTE_NETWORK_UNKNOWN_KEY/,
  'unexpected route-network keys must fail closed'
);

// Downgrade proof: recovered schema-v1 writer must protect v2 data.
function makeLocalStorage() {
  const map = new Map();
  return {
    setItem(k,v){ map.set(k,String(v)); },
    getItem(k){ return map.has(k) ? map.get(k) : null; },
    removeItem(k){ map.delete(k); },
    _map: map,
  };
}

const localStorage = makeLocalStorage();
const oldWriter = saveV1._createForTesting({ localStorage });
const prefix = 'aetherwake.save.v1.';

// Future v2 primary cannot be overwritten by hardened v1.
localStorage.setItem(prefix + 'manual-1', JSON.stringify(shifted));
assert.throws(
  () => oldWriter.save('manual-1', v1.payload, { gameVersion: '0.1.0-old' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-1:2:primary/
);
assert.strictEqual(JSON.parse(localStorage.getItem(prefix + 'manual-1')).schemaVersion, 2);

// Future v2 backup also protects the slot even behind a current/corrupt primary.
localStorage.setItem(prefix + 'manual-2', '{"broken":');
const v2Backup = JSON.parse(JSON.stringify(shifted));
v2Backup.slot = 'manual-2';
v2Backup.kind = 'manual';
const backupBody = { ...v2Backup };
delete backupBody.checksum;
v2Backup.checksum = saveV1.checksum(backupBody);
localStorage.setItem(prefix + 'manual-2.bak', JSON.stringify(v2Backup));
assert.throws(
  () => oldWriter.save('manual-2', v1.payload, { gameVersion: '0.1.0-old' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-2:2:backup/
);
assert.strictEqual(JSON.parse(localStorage.getItem(prefix + 'manual-2.bak')).schemaVersion, 2);

// Autosave rotation skips protected v2 slots.
const v2Auto0 = JSON.parse(JSON.stringify(shifted));
v2Auto0.slot = 'autosave-0';
v2Auto0.kind = 'autosave';
const auto0Body = { ...v2Auto0 };
delete auto0Body.checksum;
v2Auto0.checksum = saveV1.checksum(auto0Body);
localStorage.setItem(prefix + 'autosave-0', JSON.stringify(v2Auto0));
const rotated = oldWriter.rotateAutosave(v1.payload, { gameVersion: '0.1.0-old' });
assert.notStrictEqual(rotated.envelope.slot, 'autosave-0',
  'hardened v1 autosave must skip a v2-protected slot');

// If every autosave is v2, v1 must fail closed.
for (const slot of oldWriter.AUTOSAVE_SLOTS) {
  const env = JSON.parse(JSON.stringify(shifted));
  env.slot = slot;
  env.kind = 'autosave';
  const body = { ...env };
  delete body.checksum;
  env.checksum = saveV1.checksum(body);
  localStorage.setItem(prefix + slot, JSON.stringify(env));
}
assert.throws(
  () => oldWriter.rotateAutosave(v1.payload, { gameVersion: '0.1.0-old' }),
  /SAVE_AUTOSAVE_ALL_SLOTS_FUTURE_PROTECTED/
);

console.log('Aetherwake save schema v2 proof: PASS');
