/*
 * Aetherwake — Whole-game Save Schema v2 Proof
 *
 * SOURCE/CONTRACT PROOF ONLY. This does not alter AetherSaveSystem.SCHEMA_VERSION
 * or the playable runtime. It proves the exact v1 -> v2 migration shape required
 * before routeNetwork can become durable runtime state.
 */
'use strict';

const saveV1 = require('./save-system.js');
const routeNetwork = require('./route-network-state.js');

const VERSION = '0.1.0';
const SOURCE_SCHEMA_VERSION = 1;
const TARGET_SCHEMA_VERSION = 2;

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function migrateV1Envelope(envelopeV1) {
  saveV1.validateEnvelopeIntegrity(envelopeV1);
  if (envelopeV1.schemaVersion !== SOURCE_SCHEMA_VERSION) {
    throw new Error('SAVE_V2_PROOF_SOURCE_SCHEMA_INVALID:' + envelopeV1.schemaVersion);
  }

  const next = clone(envelopeV1);
  // Preserve existing air-navigation discovery exactly. Route knowledge does not
  // become objective route condition during migration.
  next.payload.routeNetwork = routeNetwork.exportPersistentState(routeNetwork.createState());
  next.schemaVersion = TARGET_SCHEMA_VERSION;

  const body = { ...next };
  delete body.checksum;
  next.checksum = saveV1.checksum(body);
  return next;
}

function validateV2Envelope(envelope) {
  saveV1.validateEnvelopeIntegrity(envelope);
  if (envelope.schemaVersion !== TARGET_SCHEMA_VERSION) {
    throw new Error('SAVE_V2_PROOF_SCHEMA_INVALID:' + envelope.schemaVersion);
  }
  if (!envelope.payload || typeof envelope.payload !== 'object' || Array.isArray(envelope.payload)) {
    throw new Error('SAVE_V2_PROOF_PAYLOAD_INVALID');
  }
  if (!Object.prototype.hasOwnProperty.call(envelope.payload, 'routeNetwork')) {
    throw new Error('SAVE_V2_PROOF_ROUTE_NETWORK_MISSING');
  }
  routeNetwork.validatePersistentState(envelope.payload.routeNetwork);
  return true;
}

function migrateAndValidate(envelopeV1) {
  const next = migrateV1Envelope(envelopeV1);
  validateV2Envelope(next);
  return next;
}

module.exports = Object.freeze({
  VERSION,
  SOURCE_SCHEMA_VERSION,
  TARGET_SCHEMA_VERSION,
  migrateV1Envelope,
  validateV2Envelope,
  migrateAndValidate,
});
