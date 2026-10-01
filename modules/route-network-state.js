/*
 * Aetherwake — Route Network State
 *
 * Runtime persistence authority for objective route condition, bounded route
 * clues, and bounded local precedents. Route knowledge remains separately
 * owned by AetherAirNavigation.discoveredRoutes.
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

  const VERSION = '0.2.0';
  const PERSISTENCE_VERSION = 1;
  const DEFAULT_CONDITION = 'open';
  const OPERATIONAL_STATES = Object.freeze(['open','provisional','shifted','closed']);
  const KNOWN_PRECEDENTS = Object.freeze(['LOCAL_ROUTE_ASSISTANCE']);
  const ROUTE_IDS = Object.freeze(nav.SKY_ROUTES.map(route => route.id));
  const SPEED_FACTORS = Object.freeze({
    open: 1.25,
    provisional: 1.10,
    shifted: 1,
    closed: 1,
  });
  const ROUTE_CLUES = Object.freeze([
    Object.freeze({
      id: 'rootline-west-upper-trace',
      routeId: 'rootline-west',
      label: 'UPPER WAKE TRACE',
      x: 12,
      y: 18,
      radius: 2.5,
      altitudes: Object.freeze(['high']),
      suggestsCondition: 'shifted',
    }),
  ]);
  const KNOWN_CLUES = Object.freeze(ROUTE_CLUES.map(clue => clue.id));

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

  function routeAlignment(dx, dy, routeId) {
    if (!Number.isFinite(dx) || !Number.isFinite(dy) || (!dx && !dy)) return 0;
    const route = nav.SKY_ROUTES.find(candidate => candidate.id === routeId);
    if (!route) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
    const from = nav.LANDMARKS.find(mark => mark.id === route.from);
    const to = nav.LANDMARKS.find(mark => mark.id === route.to);
    if (!from || !to) throw new Error('ROUTE_NETWORK_GEOMETRY_INVALID:' + routeId);
    const rx = to.x - from.x;
    const ry = to.y - from.y;
    const routeLength = Math.hypot(rx, ry);
    const moveLength = Math.hypot(dx, dy);
    if (!routeLength || !moveLength) return 0;
    return (rx * dx + ry * dy) / (routeLength * moveLength);
  }

  function travelFactor(navState, routeState, dx, dy, routeId) {
    if (!ROUTE_IDS.includes(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
    const context = nav.routeContext(navState);
    if (!context.onRoute || !context.discovered || !context.route || context.route.id !== routeId) return 1;
    const condition = conditionFor(routeState, routeId);
    if (condition === 'shifted' || condition === 'closed') return 1;
    if (routeAlignment(dx, dy, routeId) < 0.5) return 1;
    return SPEED_FACTORS[condition];
  }

  function cluesAt(navState) {
    if (!navState || typeof navState !== 'object') throw new Error('ROUTE_NETWORK_NAV_STATE_REQUIRED');
    return ROUTE_CLUES
      .filter(clue => clue.altitudes.includes(navState.altitude))
      .filter(clue => Array.isArray(navState.discoveredRoutes) && navState.discoveredRoutes.includes(clue.routeId))
      .filter(clue => Math.hypot(clue.x - navState.x, clue.y - navState.y) <= clue.radius)
      .map(clue => Object.assign({}, clue, { altitudes: clue.altitudes.slice() }));
  }

  function discoverNearbyClues(navState, state) {
    let next = createState(state);
    const discoveredNow = [];
    for (const clue of cluesAt(navState)) {
      if (!next.discoveredClues.includes(clue.id)) {
        next = discoverClue(next, clue.id);
        discoveredNow.push(clue.id);
      }
    }
    return { state: next, discoveredNow };
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
    SPEED_FACTORS: Object.assign({}, SPEED_FACTORS),
    ROUTE_CLUES: ROUTE_CLUES.map(clue => Object.assign({}, clue, { altitudes: clue.altitudes.slice() })),
    createState,
    conditionFor,
    setCondition,
    discoverClue,
    recordPrecedent,
    routeAlignment,
    travelFactor,
    cluesAt,
    discoverNearbyClues,
    exportPersistentState,
    validatePersistentState,
    restorePersistentState,
  });
}));
