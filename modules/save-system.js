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
      readPrimary(slot) {
        const raw = root.localStorage.getItem(STORAGE_PREFIX + slot);
        return raw ? JSON.parse(raw) : null;
      },
      readBackup() { return null; },
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

    function testHook(stage, context) {
      if (root && typeof root.__AETHERWAKE_SAVE_TEST_HOOK__ === 'function') {
        root.__AETHERWAKE_SAVE_TEST_HOOK__(stage, context || {});
      }
    }

    function file(slot) { return path.join(dir, slot + '.json'); }
    return {
      type: 'nw-file',
      write(slot, envelope) {
        const target = file(slot);
        const tmp = target + '.tmp';
        const bak = target + '.bak';
        const json = JSON.stringify(envelope, null, 2) + '\n';
        testHook('before-temp-write', { slot, target, tmp, bak });

        const fd = fs.openSync(tmp, 'w');
        try {
          fs.writeFileSync(fd, json, 'utf8');
          fs.fsyncSync(fd);
        } finally {
          fs.closeSync(fd);
        }
        testHook('after-temp-fsync', { slot, target, tmp, bak });

        try {
          if (fs.existsSync(target)) {
            if (fs.existsSync(bak)) fs.unlinkSync(bak);
            fs.renameSync(target, bak);
          }
          testHook('after-backup-promote', { slot, target, tmp, bak });
          testHook('before-primary-promote', { slot, target, tmp, bak });
          fs.renameSync(tmp, target);
          testHook('after-primary-promote', { slot, target, tmp, bak });
        } catch (error) {
          // If the old primary has already moved to backup but no primary exists,
          // restore it before reporting failure. If the new primary already exists,
          // it is itself a complete fsynced JSON file and may safely remain primary.
          if (!fs.existsSync(target) && fs.existsSync(bak)) {
            fs.renameSync(bak, target);
          }
          if (fs.existsSync(tmp)) {
            try { fs.unlinkSync(tmp); } catch (_) {}
          }
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
      readPrimary(slot) {
        const target = file(slot);
        if (!fs.existsSync(target)) return null;
        return JSON.parse(fs.readFileSync(target, 'utf8'));
      },
      readBackup(slot) {
        const bak = file(slot) + '.bak';
        if (!fs.existsSync(bak)) return null;
        return JSON.parse(fs.readFileSync(bak, 'utf8'));
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

  function futureSchemaVersion(envelope) {
    if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) return null;
    try {
      validateEnvelopeIntegrity(envelope);
    } catch (_) {
      return null;
    }
    return Number.isInteger(envelope.schemaVersion) && envelope.schemaVersion > SCHEMA_VERSION
      ? envelope.schemaVersion
      : null;
  }

  function futureProtectedSlot(slot, storageOverride) {
    validateSlot(slot);
    const storage = storageOverride || getStorage();
    if (!storage) return null;
    const candidates = [];
    for (const reader of ['readPrimary','readBackup']) {
      if (typeof storage[reader] !== 'function') continue;
      try {
        const envelope = storage[reader](slot);
        const version = futureSchemaVersion(envelope);
        if (version != null) candidates.push({ source: reader === 'readPrimary' ? 'primary' : 'backup', version });
      } catch (_) {
        // Unreadable/corrupt records are not future-schema protection claims.
      }
    }
    if (!candidates.length) return null;
    candidates.sort((a,b) => b.version - a.version);
    return candidates[0];
  }

  function assertSlotOverwriteCompatible(slot, storage) {
    const protectedState = futureProtectedSlot(slot, storage);
    if (protectedState) {
      throw new Error(
        'SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:' +
        slot + ':' + protectedState.version + ':' + protectedState.source
      );
    }
    return true;
  }

  function save(slot, payload, meta) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    assertSlotOverwriteCompatible(slot, storage);
    const envelope = makeEnvelope(slot, payload, meta || {});
    validateEnvelope(envelope);
    storage.write(slot, envelope);
    return { envelope, storageType: storage.type, path: storage.path(slot) };
  }

  function load(slot) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');

    let primary = null;
    let primaryError = null;
    try {
      primary = typeof storage.readPrimary === 'function'
        ? storage.readPrimary(slot)
        : storage.read(slot);
      if (primary) {
        const migrated = migrateEnvelope(primary);
        return {
          envelope: migrated,
          migratedFromSchemaVersion: primary.schemaVersion === migrated.schemaVersion
            ? null
            : primary.schemaVersion,
          storageType: storage.type,
          path: storage.path(slot),
          recoveredFromBackup: false
        };
      }
    } catch (error) {
      primaryError = error;
    }

    if (typeof storage.readBackup === 'function') {
      try {
        const backup = storage.readBackup(slot);
        if (backup) {
          const migrated = migrateEnvelope(backup);
          return {
            envelope: migrated,
            migratedFromSchemaVersion: backup.schemaVersion === migrated.schemaVersion
              ? null
              : backup.schemaVersion,
            storageType: storage.type,
            path: storage.path(slot) + '.bak',
            recoveredFromBackup: true,
            primaryLoadError: primaryError ? primaryError.message : 'SAVE_PRIMARY_MISSING'
          };
        }
      } catch (backupError) {
        if (primaryError) {
          throw new Error(
            'SAVE_PRIMARY_AND_BACKUP_INTEGRITY_UNLOADABLE:' +
            primaryError.message + '|' + backupError.message
          );
        }
        throw backupError;
      }
    }

    if (primaryError) throw primaryError;
    return null;
  }

  function loadBackup(slot) {
    validateSlot(slot);
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    if (typeof storage.readBackup !== 'function') return null;
    const envelope = storage.readBackup(slot);
    if (!envelope) return null;
    const migrated = migrateEnvelope(envelope);
    return {
      envelope: migrated,
      migratedFromSchemaVersion: envelope.schemaVersion === migrated.schemaVersion
        ? null
        : envelope.schemaVersion,
      storageType: storage.type,
      path: storage.path(slot) + '.bak',
      recoveredFromBackup: true
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
    const storage = getStorage();
    if (!storage) throw new Error('SAVE_STORAGE_UNAVAILABLE');
    const candidates = AUTOSAVE_SLOTS.filter(slot => !futureProtectedSlot(slot, storage));
    if (!candidates.length) throw new Error('SAVE_AUTOSAVE_ALL_SLOTS_FUTURE_PROTECTED');

    const entries = candidates.map(slot => {
      try { return { slot, loaded: load(slot) }; } catch (_) { return { slot, loaded: null }; }
    });
    const dated = entries.map(entry => ({
      slot: entry.slot,
      time: entry.loaded && entry.loaded.envelope && entry.loaded.envelope.savedAt
        ? Date.parse(entry.loaded.envelope.savedAt) || 0
        : 0
    })).sort((a,b) => a.time - b.time);
    return save(dated[0].slot, payload, meta);
  }

  return Object.freeze({
    VERSION, SCHEMA_VERSION, MIGRATIONS,
    MANUAL_SLOTS: MANUAL_SLOTS.slice(),
    AUTOSAVE_SLOTS: AUTOSAVE_SLOTS.slice(),
    makeEnvelope, validateEnvelopeIntegrity, migrateEnvelope, validateEnvelope,
    checksum, getStorage, futureSchemaVersion, futureProtectedSlot, assertSlotOverwriteCompatible,
    save, load, loadBackup, remove, list, latest, rotateAutosave,
    _createForTesting: createSaveSystem
  });
}));
