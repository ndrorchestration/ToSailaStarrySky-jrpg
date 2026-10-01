/*
 * Aetherwake — First Wake Route-State Proof
 *
 * DESIGN-CANDIDATE ONLY. This module proves route-state, directional lane
 * benefit, route-clue discovery, and a small persistence domain without
 * changing the live AetherAirNavigation contract or Chapter 1 runtime.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('./air-navigation.js'));
  } else {
    root.AetherRouteStateProof = factory(root.AetherAirNavigation);
  }
}(typeof window !== 'undefined' ? window : globalThis, function (nav) {
  'use strict';

  if (!nav) throw new Error('ROUTE_PROOF_AIR_NAV_REQUIRED');

  const VERSION = '0.1.0';
  const PERSISTENCE_VERSION = 1;
  const ROUTE_STATES = Object.freeze(['open', 'provisional', 'shifted', 'closed']);
  const PROTOTYPE_SPEED_FACTORS = Object.freeze({
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
      kind: 'historical-shift',
      x: 12,
      y: 18,
      radius: 2.5,
      altitudes: Object.freeze(['high']),
      suggestsState: 'shifted',
    }),
  ]);

  function knownRoute(routeId) {
    return nav.SKY_ROUTES.some(route => route.id === routeId);
  }

  function defaultRouteStates() {
    const result = {};
    for (const route of nav.SKY_ROUTES) result[route.id] = 'open';
    return result;
  }

  function normalizeRouteStates(input) {
    const result = defaultRouteStates();
    if (input === undefined || input === null) return result;
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      throw new Error('ROUTE_PROOF_ROUTE_STATES_OBJECT_REQUIRED');
    }
    for (const [routeId, state] of Object.entries(input)) {
      if (!knownRoute(routeId)) throw new Error('ROUTE_PROOF_ROUTE_UNKNOWN');
      if (!ROUTE_STATES.includes(state)) throw new Error('ROUTE_PROOF_ROUTE_STATE_INVALID');
      result[routeId] = state;
    }
    return result;
  }

  function normalizeClues(input) {
    if (input === undefined || input === null) return [];
    if (!Array.isArray(input)) throw new Error('ROUTE_PROOF_CLUES_ARRAY_REQUIRED');
    const unique = [];
    for (const clueId of input) {
      if (!ROUTE_CLUES.some(clue => clue.id === clueId)) {
        throw new Error('ROUTE_PROOF_CLUE_UNKNOWN');
      }
      if (!unique.includes(clueId)) unique.push(clueId);
    }
    return unique;
  }

  function createState(overrides) {
    const o = overrides || {};
    return {
      routeStates: normalizeRouteStates(o.routeStates),
      discoveredClues: normalizeClues(o.discoveredClues),
    };
  }

  function routeState(state, routeId) {
    if (!knownRoute(routeId)) throw new Error('ROUTE_PROOF_ROUTE_UNKNOWN');
    const next = createState(state);
    return next.routeStates[routeId];
  }

  function setRouteState(state, routeId, value) {
    if (!knownRoute(routeId)) throw new Error('ROUTE_PROOF_ROUTE_UNKNOWN');
    if (!ROUTE_STATES.includes(value)) throw new Error('ROUTE_PROOF_ROUTE_STATE_INVALID');
    const next = createState(state);
    next.routeStates[routeId] = value;
    return next;
  }

  function routeAlignment(navState, dx, dy, routeId) {
    if (!Number.isFinite(dx) || !Number.isFinite(dy) || (!dx && !dy)) return 0;
    const route = nav.SKY_ROUTES.find(candidate => candidate.id === routeId);
    if (!route) throw new Error('ROUTE_PROOF_ROUTE_UNKNOWN');
    const from = nav.LANDMARKS.find(mark => mark.id === route.from);
    const to = nav.LANDMARKS.find(mark => mark.id === route.to);
    if (!from || !to) throw new Error('ROUTE_PROOF_ROUTE_GEOMETRY_INVALID');

    const rx = to.x - from.x;
    const ry = to.y - from.y;
    const routeLength = Math.hypot(rx, ry);
    const moveLength = Math.hypot(dx, dy);
    if (!routeLength || !moveLength) return 0;
    return (rx * dx + ry * dy) / (routeLength * moveLength);
  }

  function travelFactor(navState, proofState, dx, dy) {
    const context = nav.routeContext(navState);
    if (!context.onRoute || !context.discovered || !context.route) return 1;

    const state = routeState(proofState, context.route.id);
    if (state === 'closed' || state === 'shifted') return 1;

    const alignment = routeAlignment(navState, dx, dy, context.route.id);
    if (alignment < 0.5) return 1;

    return PROTOTYPE_SPEED_FACTORS[state];
  }

  function cluesAt(navState) {
    return ROUTE_CLUES
      .filter(clue => clue.altitudes.includes(navState.altitude))
      .filter(clue => Math.hypot(clue.x - navState.x, clue.y - navState.y) <= clue.radius)
      .map(clue => Object.assign({}, clue, { altitudes: clue.altitudes.slice() }));
  }

  function discoverNearbyClues(navState, proofState) {
    const next = createState(proofState);
    for (const clue of cluesAt(navState)) {
      if (!next.discoveredClues.includes(clue.id)) next.discoveredClues.push(clue.id);
    }
    return next;
  }

  function prototypeMove(navState, proofState, dx, dy) {
    const factor = travelFactor(navState, proofState, dx, dy);
    const navigationState = nav.move(navState, dx * factor, dy * factor);
    const state = discoverNearbyClues(navigationState, proofState);
    return { navigationState, proofState: state, factor };
  }

  function exportPersistentState(state) {
    const next = createState(state);
    return {
      version: PERSISTENCE_VERSION,
      routeStates: Object.assign({}, next.routeStates),
      discoveredClues: next.discoveredClues.slice(),
    };
  }

  function validatePersistentState(payload) {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new Error('ROUTE_PROOF_STATE_OBJECT_REQUIRED');
    }
    if (payload.version !== PERSISTENCE_VERSION) {
      throw new Error('ROUTE_PROOF_STATE_VERSION_INVALID');
    }
    createState({
      routeStates: payload.routeStates,
      discoveredClues: payload.discoveredClues,
    });
    return true;
  }

  function restorePersistentState(payload) {
    validatePersistentState(payload);
    return createState(payload);
  }

  return {
    VERSION,
    PERSISTENCE_VERSION,
    ROUTE_STATES: ROUTE_STATES.slice(),
    ROUTE_CLUES: ROUTE_CLUES.map(clue => Object.assign({}, clue, { altitudes: clue.altitudes.slice() })),
    PROTOTYPE_SPEED_FACTORS: Object.assign({}, PROTOTYPE_SPEED_FACTORS),
    createState,
    routeState,
    setRouteState,
    routeAlignment,
    travelFactor,
    cluesAt,
    discoverNearbyClues,
    prototypeMove,
    exportPersistentState,
    validatePersistentState,
    restorePersistentState,
  };
}));
