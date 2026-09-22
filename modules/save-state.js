/* ============================================================
   Aetherwake JRPG — Versioned Save State
   modules/save-state.js

   Compatibility boundary:
   - versioned JSON document;
   - stable authored character IDs;
   - allowlisted persistent subsystem data only;
   - canonical identity remains code-owned;
   - encounter/render/transient state is intentionally excluded;
   - unsupported or unversioned data fails closed.
   ============================================================ */

(function (global) {
  'use strict';

  const SAVE_KIND = 'aetherwake-save';
  const CURRENT_SCHEMA_VERSION = 3;
  const STORAGE_KEY = 'aetherwake.save.v3';
  const LEGACY_STORAGE_KEYS = Object.freeze(['aetherwake.save.v2','aetherwake.save.v1']);

  // Every released schema transition is explicit. v1 contained only
  // party/progression persistence; v2 adds World/quest/ledger and Dragonfly
  // payloads. Migrated v1 documents preserve the initialized runtime defaults
  // for those newly introduced domains by representing them as null.
  const MIGRATIONS = Object.freeze({
    1: function migrateV1ToV2(input) {
      const document = cloneJson(input);
      document.schemaVersion = 2;
      document.worldState = null;
      document.airshipState = null;
      return document;
    },
    2: function migrateV2ToV3(input) {
      const document = cloneJson(input);
      document.schemaVersion = 3;
      document.navigationState = null;
      return document;
    },
  });

  function cloneJson(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function requirePartyState() {
    const partyState = global.AetherPartyState;
    if (!partyState ||
        typeof partyState.exportPersistentState !== 'function' ||
        typeof partyState.validatePersistentState !== 'function' ||
        typeof partyState.restorePersistentState !== 'function') {
      throw new Error('SAVE_PARTY_STATE_API_UNAVAILABLE');
    }
    return partyState;
  }

  function requireRuntimePersistence() {
    const runtime = global.AetherRuntimePersistence;
    const required = [
      'exportWorldState',
      'validateWorldState',
      'restoreWorldState',
      'exportAirshipState',
      'validateAirshipState',
      'restoreAirshipState',
      'exportNavigationState',
      'validateNavigationState',
      'restoreNavigationState',
    ];
    if (!runtime || required.some(method => typeof runtime[method] !== 'function')) {
      throw new Error('SAVE_RUNTIME_PERSISTENCE_API_UNAVAILABLE');
    }
    return runtime;
  }

  function validateDocument(document) {
    if (!document || typeof document !== 'object' || Array.isArray(document)) {
      throw new Error('SAVE_DOCUMENT_OBJECT_REQUIRED');
    }
    if (document.kind !== SAVE_KIND) {
      throw new Error('SAVE_KIND_INVALID');
    }
    if (!Number.isInteger(document.schemaVersion)) {
      throw new Error('SAVE_SCHEMA_VERSION_REQUIRED');
    }
    if (document.schemaVersion !== CURRENT_SCHEMA_VERSION) {
      throw new Error('SAVE_SCHEMA_VERSION_NOT_CURRENT');
    }
    if (typeof document.savedAt !== 'string' ||
        !/^\d{4}-\d{2}-\d{2}T/.test(document.savedAt)) {
      throw new Error('SAVE_TIMESTAMP_INVALID');
    }

    requirePartyState().validatePersistentState(document.partyState);

    if (!Object.prototype.hasOwnProperty.call(document, 'worldState') ||
        !Object.prototype.hasOwnProperty.call(document, 'airshipState') ||
        !Object.prototype.hasOwnProperty.call(document, 'navigationState')) {
      throw new Error('SAVE_V3_SUBSYSTEM_PAYLOADS_REQUIRED');
    }

    if (document.worldState !== null || document.airshipState !== null ||
        document.navigationState !== null) {
      const runtime = requireRuntimePersistence();
      if (document.worldState !== null) runtime.validateWorldState(document.worldState);
      if (document.airshipState !== null) runtime.validateAirshipState(document.airshipState);
      if (document.navigationState !== null) runtime.validateNavigationState(document.navigationState);
    }
    return true;
  }

  function migrateToCurrent(input) {
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      throw new Error('SAVE_DOCUMENT_OBJECT_REQUIRED');
    }
    if (!Number.isInteger(input.schemaVersion)) {
      throw new Error('SAVE_SCHEMA_VERSION_REQUIRED');
    }
    if (input.schemaVersion > CURRENT_SCHEMA_VERSION) {
      throw new Error('SAVE_SCHEMA_VERSION_FROM_FUTURE');
    }

    let document = cloneJson(input);
    while (document.schemaVersion < CURRENT_SCHEMA_VERSION) {
      const migration = MIGRATIONS[document.schemaVersion];
      if (typeof migration !== 'function') {
        throw new Error('SAVE_MIGRATION_MISSING_FROM_V' + document.schemaVersion);
      }
      document = migration(document);
      if (!document || !Number.isInteger(document.schemaVersion)) {
        throw new Error('SAVE_MIGRATION_RESULT_INVALID');
      }
    }

    validateDocument(document);
    return document;
  }

  function createDocument(options) {
    const partyState = requirePartyState();
    const runtime = requireRuntimePersistence();
    const now = options && typeof options.now === 'string'
      ? options.now
      : new Date().toISOString();

    const document = {
      kind: SAVE_KIND,
      schemaVersion: CURRENT_SCHEMA_VERSION,
      savedAt: now,
      partyState: partyState.exportPersistentState(),
      worldState: runtime.exportWorldState(),
      airshipState: runtime.exportAirshipState(),
      navigationState: runtime.exportNavigationState(),
    };

    validateDocument(document);
    return document;
  }

  function serialize(document) {
    validateDocument(document);
    return JSON.stringify(document);
  }

  function deserialize(text) {
    if (typeof text !== 'string' || text.trim() === '') {
      throw new Error('SAVE_TEXT_REQUIRED');
    }

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (error) {
      throw new Error('SAVE_JSON_INVALID');
    }
    return migrateToCurrent(parsed);
  }

  function restoreDocument(document) {
    const current = migrateToCurrent(document);
    const partyResult = requirePartyState().restorePersistentState(current.partyState);
    let worldResult = null;
    let airshipResult = null;
    let navigationResult = null;

    if (current.worldState !== null || current.airshipState !== null ||
        current.navigationState !== null) {
      const runtime = requireRuntimePersistence();
      if (current.worldState !== null) {
        worldResult = runtime.restoreWorldState(current.worldState);
      }
      if (current.airshipState !== null) {
        airshipResult = runtime.restoreAirshipState(current.airshipState);
      }
      if (current.navigationState !== null) {
        navigationResult = runtime.restoreNavigationState(current.navigationState);
      }
    }

    return {
      document: current,
      roster: partyResult.roster,
      activeParty: partyResult.activeParty,
      worldState: worldResult,
      airshipState: airshipResult,
      navigationState: navigationResult,
    };
  }

  function requireStorage(storage) {
    const target = storage || global.localStorage;
    if (!target ||
        typeof target.getItem !== 'function' ||
        typeof target.setItem !== 'function') {
      throw new Error('SAVE_STORAGE_UNAVAILABLE');
    }
    return target;
  }

  function saveToStorage(storage, options) {
    const target = requireStorage(storage);
    const document = createDocument(options);
    target.setItem(STORAGE_KEY, JSON.stringify(document));
    return { ok: true, document };
  }

  function loadFromStorage(storage) {
    const target = requireStorage(storage);
    let sourceKey = STORAGE_KEY;
    let raw = target.getItem(sourceKey);

    if (raw == null) {
      for (const legacyKey of LEGACY_STORAGE_KEYS) {
        raw = target.getItem(legacyKey);
        if (raw != null) {
          sourceKey = legacyKey;
          break;
        }
      }
    }

    if (raw == null) {
      return { ok: false, reason: 'SAVE_NOT_FOUND' };
    }

    const document = deserialize(raw);
    const restored = restoreDocument(document);

    // Successful legacy loads are copied forward only after validation and
    // restore succeed. The legacy key is retained as a rollback-safe source.
    if (sourceKey !== STORAGE_KEY) {
      target.setItem(STORAGE_KEY, JSON.stringify(document));
    }

    return {
      ok: true,
      migrated: sourceKey !== STORAGE_KEY,
      sourceKey,
      document,
      roster: restored.roster,
      activeParty: restored.activeParty,
      worldState: restored.worldState,
      airshipState: restored.airshipState,
      navigationState: restored.navigationState,
    };
  }

  function clearStorage(storage) {
    const target = requireStorage(storage);
    if (typeof target.removeItem !== 'function') {
      throw new Error('SAVE_STORAGE_REMOVE_UNAVAILABLE');
    }
    target.removeItem(STORAGE_KEY);
    for (const legacyKey of LEGACY_STORAGE_KEYS) {
      target.removeItem(legacyKey);
    }
    return { ok: true };
  }

  global.AetherSaveState = Object.freeze({
    kind: SAVE_KIND,
    schemaVersion: CURRENT_SCHEMA_VERSION,
    storageKey: STORAGE_KEY,
    legacyStorageKeys: LEGACY_STORAGE_KEYS.slice(),
    migrationVersions: Object.freeze(Object.keys(MIGRATIONS).map(Number)),
    createDocument,
    validateDocument,
    migrateToCurrent,
    serialize,
    deserialize,
    restoreDocument,
    saveToStorage,
    loadFromStorage,
    clearStorage,
  });
})(window);
