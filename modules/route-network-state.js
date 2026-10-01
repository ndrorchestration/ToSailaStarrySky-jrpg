/*
 * Aetherwake — Route Network State
 *
 * DESIGN/SCHEMA-PROOF CANDIDATE ONLY.
 * Separates route knowledge (owned by AetherAirNavigation.discoveredRoutes)
 * from objective operational condition.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('./air-navigation.js'));
  } else {
    root.AetherRouteNetworkState = factory(root.AetherAirNavigation);
  }
}(typeof window !== 'undefined' ? window : globalThis, function (nav) {
  'use strict';

  if (!nav) throw new Error('ROUTE_NETWORK_AIR_NAV_REQUIRED');

  const VERSION = '0.1.0';
  const PERSISTENCE_VERSION = 1;
  const DEFAULT_CONDITION = 'open';
  const OPERATIONAL_STATES = Object.freeze(['open','provisional','shifted','closed']);
  const KNOWN_CLUES = Object.freeze(['rootline-west-upper-trace']);
  const KNOWN_PRECEDENTS = Object.freeze(['LOCAL_ROUTE_ASSISTANCE']);
  const ROUTE_IDS = Object.freeze(nav.SKY_ROUTES.map(route => route.id));

  function isPlainObject(value) {
    return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
  }

  function assertKnownKeys(value, allowed, code) {
    if (!isPlainObject(value)) throw new Error(code + '_OBJECT_REQUIRED');
    const keys = new Set(allowed);
    for (const key of Object.keys(value)) {
      if (!keys.has(key)) throw new Error(code + '_UNKNOWN_KEY:' + key);
    }
  }

  function normalizeOperationalStates(input) {
    if (input == null) return {};
    if (!isPlainObject(input)) throw new Error('ROUTE_NETWORK_STATES_OBJECT_REQUIRED');
    const result = {};
    for (const [routeId, condition] of Object.entries(input)) {
      if (!ROUTE_IDS.includes(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
      if (!OPERATIONAL_STATES.includes(condition)) {
        throw new Error('ROUTE_NETWORK_CONDITION_INVALID:' + condition);
      }
      // Sparse canonical form: OPEN is the default and need not be stored.
      if (condition !== DEFAULT_CONDITION) result[routeId] = condition;
    }
    return result;
  }

  function normalizeUniqueList(input, allowed, code) {
    if (input == null) return [];
    if (!Array.isArray(input)) throw new Error(code + '_ARRAY_REQUIRED');
    const result = [];
    for (const id of input) {
      if (typeof id !== 'string' || !allowed.includes(id)) throw new Error(code + '_UNKNOWN:' + id);
      if (result.includes(id)) throw new Error(code + '_DUPLICATE:' + id);
      result.push(id);
    }
    return result;
  }

  function createState(overrides) {
    const o = overrides || {};
    return {
      operationalStates: normalizeOperationalStates(o.operationalStates),
      discoveredClues: normalizeUniqueList(o.discoveredClues, KNOWN_CLUES, 'ROUTE_NETWORK_CLUE'),
      precedents: normalizeUniqueList(o.precedents, KNOWN_PRECEDENTS, 'ROUTE_NETWORK_PRECEDENT'),
    };
  }

  function conditionFor(state, routeId) {
    if (!ROUTE_IDS.includes(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
    const next = createState(state);
    return next.operationalStates[routeId] || DEFAULT_CONDITION;
  }

  function setCondition(state, routeId, condition) {
    if (!ROUTE_IDS.includes(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
    if (!OPERATIONAL_STATES.includes(condition)) throw new Error('ROUTE_NETWORK_CONDITION_INVALID:' + condition);
    const next = createState(state);
    if (condition === DEFAULT_CONDITION) delete next.operationalStates[routeId];
    else next.operationalStates[routeId] = condition;
    return next;
  }

  function discoverClue(state, clueId) {
    const next = createState(state);
    if (!KNOWN_CLUES.includes(clueId)) throw new Error('ROUTE_NETWORK_CLUE_UNKNOWN:' + clueId);
    if (!next.discoveredClues.includes(clueId)) next.discoveredClues.push(clueId);
    return next;
  }

  function recordPrecedent(state, precedentId) {
    const next = createState(state);
    if (!KNOWN_PRECEDENTS.includes(precedentId)) {
      throw new Error('ROUTE_NETWORK_PRECEDENT_UNKNOWN:' + precedentId);
    }
    if (!next.precedents.includes(precedentId)) next.precedents.push(precedentId);
    return next;
  }

  function exportPersistentState(state) {
    const next = createState(state);
    return {
      persistenceVersion: PERSISTENCE_VERSION,
      operationalStates: Object.assign({}, next.operationalStates),
      discoveredClues: next.discoveredClues.slice(),
      precedents: next.precedents.slice(),
    };
  }

  function validatePersistentState(payload) {
    assertKnownKeys(
      payload,
      ['persistenceVersion','operationalStates','discoveredClues','precedents'],
      'ROUTE_NETWORK'
    );
    if (payload.persistenceVersion !== PERSISTENCE_VERSION) {
      throw new Error('ROUTE_NETWORK_VERSION_INVALID:' + payload.persistenceVersion);
    }
    createState(payload);
    return true;
  }

  function restorePersistentState(payload) {
    validatePersistentState(payload);
    return createState(payload);
  }

  return Object.freeze({
    VERSION,
    PERSISTENCE_VERSION,
    DEFAULT_CONDITION,
    OPERATIONAL_STATES: OPERATIONAL_STATES.slice(),
    KNOWN_CLUES: KNOWN_CLUES.slice(),
    KNOWN_PRECEDENTS: KNOWN_PRECEDENTS.slice(),
    ROUTE_IDS: ROUTE_IDS.slice(),
    createState,
    conditionFor,
    setCondition,
    discoverClue,
    recordPrecedent,
    exportPersistentState,
    validatePersistentState,
    restorePersistentState,
  });
}));
