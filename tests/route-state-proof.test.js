'use strict';
const assert = require('assert');
const nav = require('../modules/air-navigation.js');
const proof = require('../modules/route-state-proof.js');

assert.strictEqual(proof.VERSION, '0.1.0');
assert.strictEqual(proof.PERSISTENCE_VERSION, 1);
assert.deepStrictEqual(proof.ROUTE_STATES, ['open', 'provisional', 'shifted', 'closed']);

const initial = proof.createState();
assert.strictEqual(proof.routeState(initial, 'rootline-west'), 'open');

assert.throws(
  () => proof.setRouteState(initial, 'missing-route', 'open'),
  /ROUTE_PROOF_ROUTE_UNKNOWN/,
  'unknown route IDs must fail closed'
);
assert.throws(
  () => proof.setRouteState(initial, 'rootline-west', 'magic'),
  /ROUTE_PROOF_ROUTE_STATE_INVALID/,
  'unknown route states must fail closed'
);

const shifted = proof.setRouteState(initial, 'rootline-west', 'shifted');
assert.strictEqual(proof.routeState(shifted, 'rootline-west'), 'shifted');
assert.strictEqual(proof.routeState(initial, 'rootline-west'), 'open', 'route state mutation must be immutable');

const onRoute = nav.createState({
  x: 12,
  y: 19,
  altitude: 'cruise',
  speed: 1,
  discoveredRoutes: ['rootline-west'],
});
const forwardFactor = proof.travelFactor(onRoute, initial, 1, -1);
const reverseFactor = proof.travelFactor(onRoute, initial, -1, 1);
assert(forwardFactor > 1, 'discovered open lane should provide a prototype favorable-direction benefit');
assert.strictEqual(reverseFactor, 1, 'reverse travel must not receive the favorable-direction lane benefit');
assert.strictEqual(
  proof.travelFactor(onRoute, shifted, 1, -1),
  1,
  'shifted route must not provide the ordinary lane benefit'
);

const baselineMove = nav.move(onRoute, 1, -1);
const routedMove = proof.prototypeMove(onRoute, initial, 1, -1);
assert(
  Math.hypot(routedMove.navigationState.x - onRoute.x, routedMove.navigationState.y - onRoute.y) >
  Math.hypot(baselineMove.x - onRoute.x, baselineMove.y - onRoute.y),
  'prototype routed movement should cover more distance than ordinary free flight'
);

const clueProbe = nav.createState({
  x: 12,
  y: 18,
  altitude: 'high',
  discoveredRoutes: ['rootline-west'],
});
const clues = proof.cluesAt(clueProbe);
assert(clues.some(clue => clue.id === 'rootline-west-upper-trace'), 'high-sky dead-route clue should be detectable');

const noLowClue = proof.cluesAt(nav.createState({
  x: 12,
  y: 18,
  altitude: 'low',
  discoveredRoutes: ['rootline-west'],
}));
assert.strictEqual(noLowClue.length, 0, 'upper trace must remain altitude-gated');

const discovered = proof.discoverNearbyClues(clueProbe, initial);
assert(discovered.discoveredClues.includes('rootline-west-upper-trace'), 'route clue discovery ledger missing');

const persisted = proof.exportPersistentState(
  proof.setRouteState(discovered, 'rootline-west', 'shifted')
);
assert(proof.validatePersistentState(persisted), 'valid route-proof persistence rejected');
const restored = proof.restorePersistentState(persisted);
assert.strictEqual(proof.routeState(restored, 'rootline-west'), 'shifted');
assert(restored.discoveredClues.includes('rootline-west-upper-trace'));

assert.throws(
  () => proof.validatePersistentState(Object.assign({}, persisted, {
    routeStates: Object.assign({}, persisted.routeStates, { 'unknown-route': 'open' }),
  })),
  /ROUTE_PROOF_ROUTE_UNKNOWN/,
  'unknown persisted routes must fail closed'
);

console.log('Aetherwake bounded route-state proof: PASS');
