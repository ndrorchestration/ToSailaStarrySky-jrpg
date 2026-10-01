'use strict';

const assert = require('assert');
const routeNetwork = require('../modules/route-network-state.js');

assert.strictEqual(routeNetwork.VERSION, '0.1.0');
assert.strictEqual(routeNetwork.PERSISTENCE_VERSION, 1);
assert.strictEqual(routeNetwork.DEFAULT_CONDITION, 'open');
assert.deepStrictEqual(routeNetwork.OPERATIONAL_STATES,
  ['open','provisional','shifted','closed']);

const initial = routeNetwork.createState();
assert.deepStrictEqual(initial, {
  operationalStates: {},
  discoveredClues: [],
  precedents: [],
});
assert.strictEqual(routeNetwork.conditionFor(initial, 'rootline-west'), 'open');

const provisional = routeNetwork.setCondition(initial, 'rootline-west', 'provisional');
assert.strictEqual(routeNetwork.conditionFor(provisional, 'rootline-west'), 'provisional');
assert.deepStrictEqual(initial.operationalStates, {},
  'route-network state transitions must not mutate prior state');

const shifted = routeNetwork.setCondition(provisional, 'rootline-west', 'shifted');
assert.strictEqual(routeNetwork.conditionFor(shifted, 'rootline-west'), 'shifted');

const reopened = routeNetwork.setCondition(shifted, 'rootline-west', 'open');
assert.deepStrictEqual(reopened.operationalStates, {},
  'OPEN must remain the sparse default');

let enriched = routeNetwork.discoverClue(initial, 'rootline-west-upper-trace');
enriched = routeNetwork.recordPrecedent(enriched, 'LOCAL_ROUTE_ASSISTANCE');
const persisted = routeNetwork.exportPersistentState(enriched);
assert.strictEqual(routeNetwork.validatePersistentState(persisted), true);
assert.deepStrictEqual(routeNetwork.restorePersistentState(persisted), enriched);

assert.throws(
  () => routeNetwork.setCondition(initial, 'unknown-route', 'shifted'),
  /ROUTE_NETWORK_ROUTE_UNKNOWN/
);
assert.throws(
  () => routeNetwork.setCondition(initial, 'rootline-west', 'mystery'),
  /ROUTE_NETWORK_CONDITION_INVALID/
);
assert.throws(
  () => routeNetwork.validatePersistentState({
    persistenceVersion: 1,
    operationalStates: { 'unknown-route': 'open' },
    discoveredClues: [],
    precedents: [],
  }),
  /ROUTE_NETWORK_ROUTE_UNKNOWN/
);
assert.throws(
  () => routeNetwork.validatePersistentState({
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: ['unknown-clue'],
    precedents: [],
  }),
  /ROUTE_NETWORK_CLUE_UNKNOWN/
);
assert.throws(
  () => routeNetwork.validatePersistentState({
    persistenceVersion: 1,
    operationalStates: {},
    discoveredClues: [],
    precedents: ['unknown-precedent'],
  }),
  /ROUTE_NETWORK_PRECEDENT_UNKNOWN/
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

console.log('Aetherwake route-network persistence authority: PASS');
