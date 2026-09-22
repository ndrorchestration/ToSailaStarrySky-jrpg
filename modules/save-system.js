/*
 * Aetherwake — Save System v1
 * Durable, versioned, corruption-aware save storage.
 * Desktop: NW.js app-data JSON files with temp-write + rename + backup.
 * Browser/tests: localStorage fallback using the same envelope format.
 */
(function attach(root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(null);
  else root.AetherSaveSystem = factory(root);
}(typeof window !== 'undefined' ? window : globalThis, function (root) {
  'use strict';

  const VERSION = '1.0.0';
  const SCHEMA_VERSION = 1;
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

  function validateEnvelope(envelope) {
    if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) {
      throw new Error('SAVE_ENVELOPE_OBJECT_REQUIRED');
    }
    if (envelope.schemaVersion !== SCHEMA_VERSION) throw new Error('SAVE_SCHEMA_UNSUPPORTED');
    validateSlot(envelope.slot);
    if (!envelope.payload || typeof envelope.payload !== 'object') throw new Error('SAVE_PAYLOAD_MISSING');
    const given = envelope.checksum;
    const body = { ...envelope };
    delete body.checksum;
    if (given !== checksum(body)) throw new Error('SAVE_CHECKSUM_INVALID');
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
        fs.writeFileSync(tmp, json, 'utf8');
        if (fs.existsSync(target)) {
          try { fs.copyFileSync(target, bak); } catch (_) {}
        }
        fs.renameSync(tmp, target);
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
    validateEnvelope(envelope);
    return { envelope, storageType: storage.type, path: storage.path(slot) };
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
    VERSION, SCHEMA_VERSION, MANUAL_SLOTS: MANUAL_SLOTS.slice(),
    AUTOSAVE_SLOTS: AUTOSAVE_SLOTS.slice(), makeEnvelope, validateEnvelope,
    checksum, getStorage, save, load, remove, list, latest, rotateAutosave
  });
}));
