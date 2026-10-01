/*
 * Aetherwake — Save Schema v2 Proof
 *
 * DESIGN/TEST CANDIDATE ONLY.
 * This module is intentionally NOT loaded by the playable runtime.
 * It proves deterministic v1 -> v2 envelope migration for a bounded
 * route-network persistence domain and exercises downgrade protection
 * through the supported schema-v1 save system.
 */
'use strict';

const saveV1 = require('./save-system.js');
const air = require('./air-navigation.js');

const VERSION = '0.1.0';
const SOURCE_SCHEMA_VERSION = 1;
const TARGET_SCHEMA_VERSION = 2;
const ROUTE_NETWORK_PERSISTENCE_VERSION = 1;
const OPERATIONAL_STATES = Object.freeze(['open','provisional','shifted','closed']);
const CLUE_IDS = Object.freeze(['rootline-west-upper-trace']);
const PRECEDENT_IDS = Object.freeze(['LOCAL_ROUTE_ASSISTANCE']);

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function knownRoute(routeId) {
  return air.SKY_ROUTES.some(route => route.id === routeId);
}

function uniqueKnown(values, known, errorCode) {
  if (values === undefined || values === null) return [];
  if (!Array.isArray(values)) throw new Error(errorCode + '_ARRAY_REQUIRED');
  const result = [];
  for (const value of values) {
    if (!known.includes(value)) throw new Error(errorCode + '_UNKNOWN:' + value);
    if (!result.includes(value)) result.push(value);
  }
  return result;
}

function createRouteNetwork(overrides) {
  const o = overrides || {};
  const operationalStates = {};
  const source = o.operationalStates || {};
  if (!source || typeof source !== 'object' || Array.isArray(source)) {
    throw new Error('ROUTE_NETWORK_OPERATIONAL_STATES_OBJECT_REQUIRED');
  }
  for (const [routeId, state] of Object.entries(source)) {
    if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
    if (!OPERATIONAL_STATES.includes(state)) {
      throw new Error('ROUTE_NETWORK_STATE_UNKNOWN:' + state);
    }
    // Sparse-state rule: OPEN is canonical default and need not be serialized.
    if (state !== 'open') operationalStates[routeId] = state;
  }
  return {
    persistenceVersion: ROUTE_NETWORK_PERSISTENCE_VERSION,
    operationalStates,
    discoveredClues: uniqueKnown(o.discoveredClues, CLUE_IDS, 'ROUTE_NETWORK_CLUE'),
    precedents: uniqueKnown(o.precedents, PRECEDENT_IDS, 'ROUTE_NETWORK_PRECEDENT'),
  };
}

function validateRouteNetwork(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('ROUTE_NETWORK_OBJECT_REQUIRED');
  }
  const keys = Object.keys(value).sort();
  const allowed = ['discoveredClues','operationalStates','persistenceVersion','precedents'].sort();
  if (keys.length !== allowed.length || keys.some((key, index) => key !== allowed[index])) {
    const unknown = keys.find(key => !allowed.includes(key));
    throw new Error('ROUTE_NETWORK_UNKNOWN_KEY:' + (unknown || 'missing-required-key'));
  }
  if (value.persistenceVersion !== ROUTE_NETWORK_PERSISTENCE_VERSION) {
    throw new Error('ROUTE_NETWORK_VERSION_UNSUPPORTED:' + value.persistenceVersion);
  }
  createRouteNetwork(value);
  return true;
}

function operationalState(routeNetwork, routeId) {
  if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
  validateRouteNetwork(routeNetwork);
  return routeNetwork.operationalStates[routeId] || 'open';
}

function checksumEnvelope(envelope) {
  const body = clone(envelope);
  delete body.checksum;
  return { ...body, checksum: saveV1.checksum(body) };
}

function migrateV1ToV2(envelope) {
  saveV1.validateEnvelopeIntegrity(envelope);
  if (envelope.schemaVersion !== SOURCE_SCHEMA_VERSION) {
    throw new Error('SAVE_V2_PROOF_SOURCE_SCHEMA_REQUIRED:' + envelope.schemaVersion);
  }

  const next = clone(envelope);
  next.schemaVersion = TARGET_SCHEMA_VERSION;
  if (!next.payload || typeof next.payload !== 'object' || Array.isArray(next.payload)) {
    throw new Error('SAVE_V2_PROOF_PAYLOAD_REQUIRED');
  }

  // Preserve route knowledge exactly where v1 already owns it.
  if (next.payload.airNavigation && Array.isArray(next.payload.airNavigation.discoveredRoutes)) {
    for (const routeId of next.payload.airNavigation.discoveredRoutes) {
      if (!knownRoute(routeId)) throw new Error('SAVE_V2_PROOF_DISCOVERED_ROUTE_UNKNOWN:' + routeId);
    }
  }

  // Do not infer PROVISIONAL/SHIFTED/CLOSED, clues, or precedents from v1.
  next.payload.routeNetwork = createRouteNetwork();
  return checksumEnvelope(next);
}

function validateV2Envelope(envelope) {
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) {
    throw new Error('SAVE_V2_PROOF_ENVELOPE_REQUIRED');
  }
  if (envelope.schemaVersion !== TARGET_SCHEMA_VERSION) {
    throw new Error('SAVE_V2_PROOF_SCHEMA_REQUIRED:' + envelope.schemaVersion);
  }
  saveV1.validateEnvelopeIntegrity(envelope);
  if (!envelope.payload || !envelope.payload.routeNetwork) {
    throw new Error('SAVE_V2_PROOF_ROUTE_NETWORK_REQUIRED');
  }
  validateRouteNetwork(envelope.payload.routeNetwork);
  return true;
}

function withRouteNetworkState(envelope, routeId, state) {
  validateV2Envelope(envelope);
  if (!knownRoute(routeId)) throw new Error('ROUTE_NETWORK_ROUTE_UNKNOWN:' + routeId);
  if (!OPERATIONAL_STATES.includes(state)) throw new Error('ROUTE_NETWORK_STATE_UNKNOWN:' + state);
  const next = clone(envelope);
  const rn = createRouteNetwork(next.payload.routeNetwork);
  if (state === 'open') delete rn.operationalStates[routeId];
  else rn.operationalStates[routeId] = state;
  next.payload.routeNetwork = rn;
  return checksumEnvelope(next);
}

module.exports = Object.freeze({
  VERSION,
  SOURCE_SCHEMA_VERSION,
  TARGET_SCHEMA_VERSION,
  ROUTE_NETWORK_PERSISTENCE_VERSION,
  OPERATIONAL_STATES: OPERATIONAL_STATES.slice(),
  CLUE_IDS: CLUE_IDS.slice(),
  PRECEDENT_IDS: PRECEDENT_IDS.slice(),
  createRouteNetwork,
  validateRouteNetwork,
  operationalState,
  migrateV1ToV2,
  validateV2Envelope,
  withRouteNetworkState,
});
