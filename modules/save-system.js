/*
 * Aetherwake — Save System v1
 * Durable, versioned, corruption-aware save storage.
 * Desktop: NW.js app-data JSON files with temp-write + rename + backup.
 * Browser/tests: localStorage fallback using the same envelope format.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(null);
  else root.AetherSaveSystem = factory(root);
}(typeof window !== 'undefined' ? window : globalThis, function createSaveSystem(root) {
  'use strict';

  const VERSION = '1.1.0';
  const SCHEMA_VERSION = 1;
  const MIGRATIONS = Object.freeze({
    // Future entries are keyed by their source schema version.
    // Example: 1: envelopeV1 => envelopeV2
    // Keeping the registry live before v2 exists prevents ad-hoc migration logic later.
  });
  const STORAGE_PREFIX = 'aetherwake.save.v1.';
  const MANUAL_SLOTS = Object.freeze(['manual-1','manual-2','manual-3','manual-4','manual-5','manual-6']);
  const AUTOSAVE_SLOTS = Object.freeze(['autosave-0','autosave-1','autosave-2']);

  function stableStringify(value) {
    if (value === null || typeof value !== 'object') return JSON.stringify(value);
    if (Array.isArray(value)) return '[' + value.map(stableStringify).join(',') + ']';
    const keys = Object.keys(value).sort();
    return '{' + keys.map(k => JSON.stringify(k) + ':' + stableStringify(value[k])).join(',') + '}';
  }

  function checksum(payload) {
    const text = stableStringify(payload);
    let hash = 2166136261;
    for (let i = 0; i < text.length; i++) {
      hash ^= text.charCodeAt(i);
      hash = Math.imul(hash, 16777619);
    }
    return ('00000000' + (hash >>> 0).toString(16)).slice(-8);
  }

  function validateSlot(slot) {
    if (!MANUAL_SLOTS.includes(slot) && !AUTOSAVE_SLOTS.includes(slot)) {
      throw new Error('SAVE_SLOT_INVALID:' + slot);
    }
    return slot;
  }

  function makeEnvelope(slot, payload, meta) {
    validateSlot(slot);
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new Error('SAVE_PAYLOAD_OBJECT_REQUIRED');
    }
    const body = {
      schemaVersion: SCHEMA_VERSION,
      gameVersion: (meta && meta.gameVersion) || 'unknown',
      slot,
      kind: slot.startsWith('autosave-') ? 'autosave' : 'manual',
      savedAt: new Date().toISOString(),
      playtimeMs: Number.isFinite(meta && meta.playtimeMs) ? Math.max(0, meta.playtimeMs) : 0,
      chapter: (meta && meta.chapter) || null,
      location: (meta && meta.location) || null,
      partySummary: Array.isArray(meta && meta.partySummary) ? meta.partySummary.slice() : [],
      payload
    };
    return { ...body, checksum: checksum(body) };
  }

  function validateEnvelopeIntegrity(envelope) {
    if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) {
      throw new Error('SAVE_ENVELOPE_OBJECT_REQUIRED');
    }
    if (!Number.isInteger(envelope.schemaVersion) || envelope.schemaVersion < 1) {
      throw new Error('SAVE_SCHEMA_INVALID');
    }
    validateSlot(envelope.slot);
    if (!envelope.payload || typeof envelope.payload !== 'object' || Array.isArray(envelope.payload)) {
      throw new Error('SAVE_PAYLOAD_MISSING');
    }
    const given = envelope.checksum;
    const body = { ...envelope };
    delete body.checksum;
    if (given !== checksum(body)) throw new Error('SAVE_CHECKSUM_INVALID');
    return true;
  }

  function migrateEnvelope(envelope) {
    validateEnvelopeIntegrity(envelope);
    if (envelope.schemaVersion > SCHEMA_VERSION) {
      throw new Error('SAVE_SCHEMA_FUTURE_UNSUPPORTED:' + envelope.schemaVersion);
    }

    let current = JSON.parse(JSON.stringify(envelope));
    while (current.schemaVersion < SCHEMA_VERSION) {
      const migration = MIGRATIONS[current.schemaVersion];
      if (typeof migration !== 'function') {
        throw new Error('SAVE_MIGRATION_MISSING:' + current.schemaVersion);
      }
      const fromVersion = current.schemaVersion;
      current = migration(JSON.parse(JSON.stringify(current)));
      if (!current || current.schemaVersion !== fromVersion + 1) {
        throw new Error('SAVE_MIGRATION_VERSION_INVALID:' + fromVersion);
      }
      const body = { ...current };
      delete body.checksum;
      current.checksum = checksum(body);
    }
    validateEnvelopeIntegrity(current);
    return current;
  }

  function validateEnvelope(envelope) {
    const migrated = migrateEnvelope(envelope);
    if (migrated.schemaVersion !== SCHEMA_VERSION) throw new Error('SAVE_SCHEMA_UNSUPPORTED');
    return true;
  }

  function browserStorage() {
    if (!root || !root.localStorage) return null;
    return {
      type: 'localStorage',
      write(slot, envelope) {
        root.localStorage.setItem(STORAGE_PREFIX + slot, JSON.stringify(envelope));
      },
      read(slot) {
        const raw = root.localStorage.getItem(STORAGE_PREFIX + slot);
        return raw ? JSON.parse(raw) : null;
      },
      remove(slot) { root.localStorage.removeItem(STORAGE_PREFIX + slot); },
      exists(slot) { return root.localStorage.getItem(STORAGE_PREFIX + slot) !== null; },
      path(slot) { return 'localStorage://' + STORAGE_PREFIX + slot; }
    };
  }

  function nwStorage() {
    if (!root || typeof root.require !== 'function' || !root.nw || !root.nw.App || !root.nw.App.dataPath) return null;
    const fs = root.require('fs');
    const path = root.require('path');
    const dir = path.join(root.nw.App.dataPath, 'saves');
    fs.mkdirSync(dir, { recursive: true });

    function file(slot) { return path.join(dir, slot + '.json'); }
    return {
      type: 'nw-file',
      write(slot, envelope) {
        const target = file(slot);
        const tmp = target + '.tmp';
        const bak = target + '.bak';
        const json = JSON.stringify(envelope, null, 2) + '\n';
        const fd = fs.openSync(tmp, 'w');
        try {
          fs.writeFileSync(fd, json, 'utf8');
          fs.fsyncSync(fd);
        } finally {
          fs.closeSync(fd);
        }
        if (fs.existsSync(target)) {
          if (fs.existsSync(bak)) fs.unlinkSync(bak);
          fs.renameSync(target, bak);
        }
        try {
          fs.renameSync(tmp, target);
        } catch (error) {
          if (!fs.existsSync(target) && fs.existsSync(bak)) fs.renameSync(bak, target);
          throw error;
        }
      },
      read(slot) {
        const target = file(slot);
        if (!fs.existsSync(target)) return null;
        try {
          return JSON.parse(fs.readFileSync(target, 'utf8'));
        } catch (primaryError) {
          const bak = target + '.bak';
          if (!fs.existsSync(bak)) throw primaryError;
          const backup = JSON.parse(fs.readFileSync(bak, 'utf8'));
          validateEnvelope(backup);
          return backup;
        }
      },
      remove(slot) {
        const target = file(slot);
        for (const p of [target, target + '.bak', target + '.tmp']) {
          if (fs.existsSync(p)) fs.unlinkSync(p);
        }
      },
      exists(slot) { return fs.existsSync(file(slot)); },
      path(slot) { return file(slot); }
    };
  }

  function getStorage() {
    return nwStorage() || browserStorage() || null;
  }

  function save(slot, payload, meta) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    const envelope = makeEnvelope(slot, payload, meta || {});
    validateEnvelope(envelope);
    storage.write(slot, envelope);
    return { envelope, storageType: storage.type, path: storage.path(slot) };
  }

  function load(slot) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    const envelope = storage.read(slot);
    if (!envelope) return null;
    const migrated = migrateEnvelope(envelope);
    return {
      envelope: migrated,
      migratedFromSchemaVersion: envelope.schemaVersion === migrated.schemaVersion
        ? null
        : envelope.schemaVersion,
      storageType: storage.type,
      path: storage.path(slot)
    };
  }

  function remove(slot) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    storage.remove(slot);
  }

  function list() {
    const storage = getStorage();
    if (!storage) return [];
    return MANUAL_SLOTS.concat(AUTOSAVE_SLOTS).map(slot => {
      if (!storage.exists(slot)) return { slot, exists: false, kind: slot.startsWith('autosave-') ? 'autosave' : 'manual' };
      try {
        const loaded = load(slot);
        const e = loaded.envelope;
        return {
          slot, exists: true, valid: true, kind: e.kind, savedAt: e.savedAt,
          playtimeMs: e.playtimeMs, chapter: e.chapter, location: e.location,
          partySummary: e.partySummary, gameVersion: e.gameVersion
        };
      } catch (error) {
        return { slot, exists: true, valid: false, error: error.message, kind: slot.startsWith('autosave-') ? 'autosave' : 'manual' };
      }
    });
  }

  function latest() {
    const valid = list().filter(entry => entry.exists && entry.valid && entry.savedAt);
    valid.sort((a,b) => String(b.savedAt).localeCompare(String(a.savedAt)));
    return valid[0] || null;
  }

  function rotateAutosave(payload, meta) {
    const entries = AUTOSAVE_SLOTS.map(slot => {
      try { return load(slot); } catch (_) { return null; }
    });
    const dated = entries.map((entry, i) => ({
      slot: AUTOSAVE_SLOTS[i],
      time: entry && entry.envelope && entry.envelope.savedAt
        ? Date.parse(entry.envelope.savedAt) || 0
        : 0
    })).sort((a,b) => a.time - b.time);
    return save(dated[0].slot, payload, meta);
  }

  return Object.freeze({
    VERSION, SCHEMA_VERSION, MIGRATIONS,
    MANUAL_SLOTS: MANUAL_SLOTS.slice(),
    AUTOSAVE_SLOTS: AUTOSAVE_SLOTS.slice(),
    makeEnvelope, validateEnvelopeIntegrity, migrateEnvelope, validateEnvelope,
    checksum, getStorage, save, load, remove, list, latest, rotateAutosave,
    _createForTesting: createSaveSystem
  });
}));
