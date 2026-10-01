'use strict';

const assert = require('assert');
const proof = require('../modules/route-network-schema-v2-proof.js');

assert.strictEqual(proof.VERSION, '0.1.0');
assert.strictEqual(proof.ENVELOPE_SCHEMA_VERSION, 2);
assert.strictEqual(proof.PERSISTENCE_VERSION, 1);
assert.deepStrictEqual(proof.OPERATIONAL_STATES, ['open','provisional','shifted','closed']);

const base = proof.createState();
assert.deepStrictEqual(base.operationalStates, {});
assert.strictEqual(proof.effectiveOperationalState(base, 'rootline-west'), 'open');

const shifted = proof.createState({ operationalStates: { 'rootline-west': 'shifted' } });
assert.strictEqual(proof.effectiveOperationalState(shifted, 'rootline-west'), 'shifted');
assert.deepStrictEqual(proof.exportPersistentState(shifted).operationalStates, { 'rootline-west': 'shifted' });

const redundantOpen = proof.createState({ operationalStates: { 'rootline-west': 'open' } });
assert.deepStrictEqual(redundantOpen.operationalStates, {},
  'canonical OPEN route condition should remain sparse');

assert.strictEqual(
  proof.routeKnowledge({ discoveredRoutes: [] }, 'rootline-west'),
  'unknown'
);
assert.strictEqual(
  proof.routeKnowledge({ discoveredRoutes: ['rootline-west'] }, 'rootline-west'),
  'discovered'
);
assert.strictEqual(
  proof.effectiveOperationalState(base, 'rootline-west'),
  'open',
  'knowledge and operational condition must remain independent'
);

const v1 = {
  runtime: { scene: 'airship' },
  airNavigation: {
    persistenceVersion: 1,
    discoveredRoutes: ['rootline-west'],
  },
  party: { activeIds: ['ender'] },
};
const original = JSON.parse(JSON.stringify(v1));
const migrated = proof.migrateV1PayloadToV2(v1);
assert.deepStrictEqual(v1, original, 'v1 migration must not mutate source payload');
assert.deepStrictEqual(migrated.airNavigation, v1.airNavigation,
  'v1 route knowledge must be preserved exactly');
assert.deepStrictEqual(migrated.routeNetwork, {
  persistenceVersion: 1,
  operationalStates: {},
  discoveredClues: [],
  precedents: [],
});
assert.strictEqual(proof.routeKnowledge(migrated.airNavigation, 'rootline-west'), 'discovered');
assert.strictEqual(proof.effectiveOperationalState(migrated.routeNetwork, 'rootline-west'), 'open');
assert(!migrated.routeNetwork.discoveredClues.includes('rootline-west-upper-trace'),
  'migration must not invent route clues');
assert(!migrated.routeNetwork.precedents.includes('LOCAL_ROUTE_ASSISTANCE'),
  'migration must not invent route-assistance precedent');

assert.throws(
  () => proof.createState({ persistenceVersion: 2 }),
  /ROUTE_NETWORK_V2_VERSION_INVALID/
);
assert.throws(
  () => proof.createState({ operationalStates: { 'missing-route': 'shifted' } }),
  /ROUTE_NETWORK_V2_ROUTE_UNKNOWN/
);
assert.throws(
  () => proof.createState({ operationalStates: { 'rootline-west': 'magic' } }),
  /ROUTE_NETWORK_V2_STATE_INVALID/
);
assert.throws(
  () => proof.validatePersistentState({
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: [],
    precedents: [],
    futureField: true,
  }),
  /ROUTE_NETWORK_V2_UNKNOWN_KEY/
);
assert.throws(
  () => proof.createState({ discoveredClues: ['invented-clue'] }),
  /ROUTE_NETWORK_V2_CLUE_UNKNOWN/
);
assert.throws(
  () => proof.createState({ precedents: ['GLOBAL_REPUTATION'] }),
  /ROUTE_NETWORK_V2_PRECEDENT_UNKNOWN/
);
assert.throws(
  () => proof.migrateV1PayloadToV2({ routeNetwork: {} }),
  /ROUTE_NETWORK_V2_MIGRATION_SOURCE_ALREADY_HAS_ROUTE_NETWORK/
);

const evidenceState = proof.createState({
  operationalStates: { 'rootline-west': 'shifted' },
  discoveredClues: ['rootline-west-upper-trace'],
  precedents: ['LOCAL_ROUTE_ASSISTANCE'],
});
assert(proof.validatePersistentState(proof.exportPersistentState(evidenceState)));

console.log('Aetherwake route-network schema v2 design proof: PASS');
