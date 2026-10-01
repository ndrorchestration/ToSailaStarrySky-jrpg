'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const saveSystem = require('../modules/save-system.js');
const validator = require('../modules/save-payload-validator.js');
const routeNetwork = require('../modules/route-network-state.js');

const v1 = JSON.parse(fs.readFileSync(
  path.join(__dirname, 'fixtures', 'saves', 'schema-v1-manual-1.json'),
  'utf8'
));
const v2Fixture = JSON.parse(fs.readFileSync(
  path.join(__dirname, 'fixtures', 'saves', 'schema-v2-manual-1.json'),
  'utf8'
));

assert.strictEqual(saveSystem.SCHEMA_VERSION, 2);
assert.deepStrictEqual(Object.keys(saveSystem.MIGRATIONS), ['1']);

const migrated = saveSystem.migrateEnvelope(v1);
assert.strictEqual(migrated.schemaVersion, 2);
assert.deepStrictEqual(migrated.payload.airNavigation, v1.payload.airNavigation,
  'v1 -> v2 migration must preserve route knowledge/navigation state exactly');
assert.deepStrictEqual(migrated.payload.routeNetwork, {
  persistenceVersion: 1,
  operationalStates: {},
  discoveredClues: [],
  precedents: [],
}, 'v1 -> v2 migration must add only neutral route-network state');

assert.strictEqual(saveSystem.validateEnvelope(v2Fixture), true);
assert.strictEqual(routeNetwork.validatePersistentState(v2Fixture.payload.routeNetwork), true);

const context = {
  validateAirNavigation() { return true; },
  validateRouteNetwork(candidate) {
    return routeNetwork.validatePersistentState(candidate);
  },
};
assert.strictEqual(validator.validatePayload(migrated.payload, context), true);
assert.strictEqual(validator.validatePayload(v2Fixture.payload, context), true);

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');

for (const marker of [
  'let routeNetworkState = null;',
  "throw new Error('AETHER_ROUTE_NETWORK_STATE_UNAVAILABLE')",
  'window._routeNetworkState = routeNetworkState;',
  'window.AetherRouteNetworkState.exportPersistentState(routeNetworkState)',
  'window.AetherRouteNetworkState.restorePersistentState(payload.routeNetwork)',
  'validateRouteNetwork(candidate)',
  'preparedRouteNetwork',
]) {
  assert(runtime.includes(marker), 'schema-v2 runtime integration missing: ' + marker);
}

assert(html.includes('<script src="modules/route-network-state.js"></script>'));
assert(html.indexOf('modules/air-navigation.js') < html.indexOf('modules/route-network-state.js'),
  'route-network authority must load after air-navigation authority');
assert(html.indexOf('modules/route-network-state.js') < html.indexOf('aetherwake.js'),
  'route-network authority must load before runtime');

console.log('Aetherwake production schema v2 route-network integration: PASS');
