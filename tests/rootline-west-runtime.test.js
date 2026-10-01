'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const nav = require('../modules/air-navigation.js');
const route = require('../modules/route-network-state.js');

assert.strictEqual(route.VERSION, '0.2.0');
assert.strictEqual(route.PERSISTENCE_VERSION, 1);
assert.deepStrictEqual(route.OPERATIONAL_STATES, ['open','provisional','shifted','closed']);

const initial = route.createState();
assert.strictEqual(route.conditionFor(initial, 'rootline-west'), 'open');

const onRootline = nav.createState({
  x: 12,
  y: 19,
  altitude: 'cruise',
  speed: 1,
  discoveredRoutes: ['rootline-west'],
});
assert(route.travelFactor(onRootline, initial, 1, -1, 'rootline-west') > 1,
  'engaged open Rootline West should provide a favorable-direction benefit');
assert.strictEqual(route.travelFactor(onRootline, initial, -1, 1, 'rootline-west'), 1,
  'reverse travel must not receive the favorable-direction benefit');

const provisional = route.setCondition(initial, 'rootline-west', 'provisional');
assert.strictEqual(
  route.travelFactor(onRootline, provisional, 1, -1, 'rootline-west'),
  route.SPEED_FACTORS.provisional
);

const shifted = route.setCondition(initial, 'rootline-west', 'shifted');
assert.strictEqual(route.travelFactor(onRootline, shifted, 1, -1, 'rootline-west'), 1,
  'shifted Rootline West must lose ordinary lane assistance');

const highKnown = nav.createState({
  x: 12,
  y: 18,
  altitude: 'high',
  discoveredRoutes: ['rootline-west'],
});
assert(route.cluesAt(highKnown).some(clue => clue.id === 'rootline-west-upper-trace'),
  'known Rootline West must expose its high-altitude trace');

const highUnknown = nav.createState({
  x: 12,
  y: 18,
  altitude: 'high',
  discoveredRoutes: [],
});
assert.strictEqual(route.cluesAt(highUnknown).length, 0,
  'route-condition clue must not reveal an unknown route');

const lowKnown = nav.createState({
  x: 12,
  y: 18,
  altitude: 'low',
  discoveredRoutes: ['rootline-west'],
});
assert.strictEqual(route.cluesAt(lowKnown).length, 0,
  'upper trace must remain altitude-gated');

const discovery = route.discoverNearbyClues(highKnown, initial);
assert.deepStrictEqual(discovery.discoveredNow, ['rootline-west-upper-trace']);
const rediscovery = route.discoverNearbyClues(highKnown, discovery.state);
assert.deepStrictEqual(rediscovery.discoveredNow, [],
  'route clue must not reward repeatedly');

let resolved = route.setCondition(discovery.state, 'rootline-west', 'shifted');
resolved = route.recordPrecedent(resolved, 'LOCAL_ROUTE_ASSISTANCE');
const persisted = route.exportPersistentState(resolved);
assert.strictEqual(route.validatePersistentState(persisted), true);
const restored = route.restorePersistentState(persisted);
assert.strictEqual(route.conditionFor(restored, 'rootline-west'), 'shifted');
assert(restored.discoveredClues.includes('rootline-west-upper-trace'));
assert(restored.precedents.includes('LOCAL_ROUTE_ASSISTANCE'));

assert.throws(
  () => route.travelFactor(onRootline, initial, 1, -1, 'missing-route'),
  /ROUTE_NETWORK_ROUTE_UNKNOWN/
);

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
for (const marker of [
  'let activeRouteAssistId = null;',
  'function scanNearbyRouteClues()',
  'function confirmRootlineShift()',
  'keysPressed[82]',
  'keysPressed[70]',
  'AetherRouteNetworkState.travelFactor(',
  "setCondition(routeNetworkState, 'rootline-west', 'shifted')",
  "recordPrecedent(routeNetworkState, 'LOCAL_ROUTE_ASSISTANCE')",
  'WAKE DOCK // ROOTLINE REPORT ACKNOWLEDGED',
  'routeCondition,',
  'routeAssistActive:',
  'routeClueNearby:',
]) {
  assert(runtime.includes(marker), 'Rootline runtime binding missing: ' + marker);
}

assert(runtime.includes('routeNetwork: window.AetherRouteNetworkState && routeNetworkState'),
  'Rootline operational state must remain inside canonical schema-v2 persistence');
assert(runtime.includes('activeRouteAssistId = null;') &&
       runtime.includes('window._activeRouteAssistId = activeRouteAssistId;'),
  'lane assist must be transient and explicitly reset/synchronized');

const visual = fs.readFileSync(path.join(__dirname, '..', 'modules', 'flight-visual-stage.js'), 'utf8');
for (const marker of [
  "String(ctx.routeCondition || 'open').toUpperCase()",
  "ctx.routeAssistActive ? ' // ASSIST' : ''",
  'TRACE IN RANGE // F CHART',
  'R lane',
  'F chart',
]) {
  assert(visual.includes(marker), 'Rootline HUD binding missing: ' + marker);
}

console.log('Aetherwake Rootline West bounded runtime slice: PASS');
