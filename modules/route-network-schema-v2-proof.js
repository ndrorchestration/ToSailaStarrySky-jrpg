/*
 * Aetherwake — Route Network / Save Schema v2 Design Proof
 *
 * DESIGN-PROOF ONLY. Not loaded by the runtime. Does not change the live
 * whole-game save schema, current payload validator, or route-state authority.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('./air-navigation.js'));
  } else {
    root.AetherRouteNetworkSchemaV2Proof = factory(root.AetherAirNavigation);
  }
}(typeof window !== 'undefined' ? window : globalThis, function (nav) {
  'use strict';

  if (!nav) throw new Error('ROUTE_NETWORK_V2_AIR_NAV_REQUIRED');

  const VERSION = '0.1.0';
  const ENVELOPE_SCHEMA_VERSION = 2;
  const PERSISTENCE_VERSION = 1;
  const OPERATIONAL_STATES = Object.freeze(['open','provisional','shifted','closed']);
  const KNOWN_CLUES = Object.freeze(['rootline-west-upper-trace']);
  const KNOWN_PRECEDENTS = Object.freeze(['LOCAL_ROUTE_ASSISTANCE']);
  const ALLOWED_KEYS = Object.freeze([
    'persistenceVersion',
    'operationalStates',
    'discoveredClues',
    'precedents',
  ]);

  function clone(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  function knownRoute(routeId) {
    return Boolean(nav.SKY_ROUTES && nav.SKY_ROUTES.some(route => route.id === routeId));
  }

  function assertKnownKeys(value) {
    for (const key of Object.keys(value)) {
      if (!ALLOWED_KEYS.includes(key)) {
        throw new Error('ROUTE_NETWORK_V2_UNKNOWN_KEY:' + key);
      }
    }
  }

  function normalizeOperationalStates(input) {
    if (input === undefined || input === null) return {};
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      throw new Error('ROUTE_NETWORK_V2_STATES_OBJECT_REQUIRED');
    }
    const result = {};
    for (const [routeId, state] of Object.entries(input)) {
      if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_V2_ROUTE_UNKNOWN:' + routeId);
      if (!OPERATIONAL_STATES.includes(state)) {
        throw new Error('ROUTE_NETWORK_V2_STATE_INVALID:' + routeId + ':' + state);
      }
      // OPEN is the canonical authored default. Keep the durable representation sparse.
      if (state !== 'open') result[routeId] = state;
    }
    return result;
  }

  function normalizeUniqueList(input, known, errorPrefix) {
    if (input === undefined || input === null) return [];
    if (!Array.isArray(input)) throw new Error(errorPrefix + '_ARRAY_REQUIRED');
    const result = [];
    for (const item of input) {
      if (!known.includes(item)) throw new Error(errorPrefix + '_UNKNOWN:' + item);
      if (!result.includes(item)) result.push(item);
    }
    return result;
  }

  function createState(overrides) {
    const o = overrides || {};
    const candidate = {
      persistenceVersion: o.persistenceVersion === undefined ? PERSISTENCE_VERSION : o.persistenceVersion,
      operationalStates: o.operationalStates,
      discoveredClues: o.discoveredClues,
      precedents: o.precedents,
    };
    if (candidate.persistenceVersion !== PERSISTENCE_VERSION) {
      throw new Error('ROUTE_NETWORK_V2_VERSION_INVALID');
    }
    return {
      persistenceVersion: PERSISTENCE_VERSION,
      operationalStates: normalizeOperationalStates(candidate.operationalStates),
      discoveredClues: normalizeUniqueList(candidate.discoveredClues, KNOWN_CLUES, 'ROUTE_NETWORK_V2_CLUE'),
      precedents: normalizeUniqueList(candidate.precedents, KNOWN_PRECEDENTS, 'ROUTE_NETWORK_V2_PRECEDENT'),
    };
  }

  function validatePersistentState(payload) {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new Error('ROUTE_NETWORK_V2_OBJECT_REQUIRED');
    }
    assertKnownKeys(payload);
    createState(payload);
    return true;
  }

  function restorePersistentState(payload) {
    validatePersistentState(payload);
    return createState(payload);
  }

  function exportPersistentState(state) {
    const next = createState(state);
    return clone(next);
  }

  function effectiveOperationalState(state, routeId) {
    if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_V2_ROUTE_UNKNOWN:' + routeId);
    const next = createState(state);
    return next.operationalStates[routeId] || 'open';
  }

  function routeKnowledge(airNavigationState, routeId) {
    if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_V2_ROUTE_UNKNOWN:' + routeId);
    const discovered = airNavigationState &&
      Array.isArray(airNavigationState.discoveredRoutes)
        ? airNavigationState.discoveredRoutes
        : [];
    return discovered.includes(routeId) ? 'discovered' : 'unknown';
  }

  function migrateV1PayloadToV2(payload) {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new Error('ROUTE_NETWORK_V2_PAYLOAD_OBJECT_REQUIRED');
    }
    if (Object.prototype.hasOwnProperty.call(payload, 'routeNetwork')) {
      throw new Error('ROUTE_NETWORK_V2_MIGRATION_SOURCE_ALREADY_HAS_ROUTE_NETWORK');
    }

    const migrated = clone(payload);
    migrated.routeNetwork = createState();

    // Deliberately do not infer operational state, clues, or precedent from route discovery.
    // v1 discoveredRoutes proves only route knowledge.
    return migrated;
  }

  return Object.freeze({
    VERSION,
    ENVELOPE_SCHEMA_VERSION,
    PERSISTENCE_VERSION,
    OPERATIONAL_STATES: OPERATIONAL_STATES.slice(),
    KNOWN_CLUES: KNOWN_CLUES.slice(),
    KNOWN_PRECEDENTS: KNOWN_PRECEDENTS.slice(),
    createState,
    validatePersistentState,
    restorePersistentState,
    exportPersistentState,
    effectiveOperationalState,
    routeKnowledge,
    migrateV1PayloadToV2,
  });
}));
