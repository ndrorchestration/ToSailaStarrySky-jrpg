(function(factory) {
  const root = typeof window !== 'undefined' ? window : globalThis;
  const api = factory(root);
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherUserSettings = api;
})(function(root) {
  'use strict';

  const VERSION = '0.1.0';
  const SCHEMA_VERSION = 1;
  const STORAGE_KEY = 'aetherwake.settings.v1';

  const DEFAULTS = Object.freeze({
    textScale: '125',
    highContrastUI: false,
    reducedMotion: false,
    screenShake: 'low',
    subtitles: true,
    subtitleSize: 'large',
    subtitleBackground: 'soft',
    speakerLabels: true,
    musicVolume: 80,
    effectsVolume: 80,
    dialogueVolume: 100,
    textSpeed: 'normal',
    controllerVibration: 'low'
  });

  const SETTING_ORDER = Object.freeze(Object.keys(DEFAULTS));

  const ENUMS = Object.freeze({
    textScale: ['100','125','150','175'],
    screenShake: ['off','low','full'],
    subtitleSize: ['medium','large','extra-large'],
    subtitleBackground: ['off','soft','strong'],
    textSpeed: ['slow','normal','fast','instant'],
    controllerVibration: ['off','low','full']
  });

  const BOOLEAN_KEYS = Object.freeze([
    'highContrastUI','reducedMotion','subtitles','speakerLabels'
  ]);
  const VOLUME_KEYS = Object.freeze([
    'musicVolume','effectsVolume','dialogueVolume'
  ]);

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function defaults() {
    return clone(DEFAULTS);
  }

  function validateSettings(settings) {
    if (!settings || typeof settings !== 'object' || Array.isArray(settings)) {
      throw new Error('SETTINGS_OBJECT_REQUIRED');
    }
    const expectedKeys = Object.keys(DEFAULTS);
    for (const key of expectedKeys) {
      if (!Object.prototype.hasOwnProperty.call(settings, key)) {
        throw new Error('SETTINGS_KEY_MISSING:' + key);
      }
    }
    for (const key of Object.keys(settings)) {
      if (!Object.prototype.hasOwnProperty.call(DEFAULTS, key)) {
        throw new Error('SETTINGS_KEY_UNKNOWN:' + key);
      }
    }
    for (const key of Object.keys(ENUMS)) {
      if (!ENUMS[key].includes(settings[key])) {
        throw new Error('SETTINGS_ENUM_INVALID:' + key);
      }
    }
    for (const key of BOOLEAN_KEYS) {
      if (typeof settings[key] !== 'boolean') {
        throw new Error('SETTINGS_BOOLEAN_INVALID:' + key);
      }
    }
    for (const key of VOLUME_KEYS) {
      if (!Number.isInteger(settings[key]) || settings[key] < 0 || settings[key] > 100) {
        throw new Error('SETTINGS_VOLUME_INVALID:' + key);
      }
    }
    return true;
  }

  function makeEnvelope(settings) {
    validateSettings(settings);
    return {
      schemaVersion: SCHEMA_VERSION,
      savedAt: new Date().toISOString(),
      settings: clone(settings)
    };
  }

  function validateEnvelope(envelope) {
    if (!envelope || typeof envelope !== 'object') throw new Error('SETTINGS_ENVELOPE_REQUIRED');
    if (envelope.schemaVersion !== SCHEMA_VERSION) {
      if (Number.isInteger(envelope.schemaVersion) && envelope.schemaVersion > SCHEMA_VERSION) {
        throw new Error('SETTINGS_SCHEMA_FUTURE_UNSUPPORTED');
      }
      throw new Error('SETTINGS_SCHEMA_UNSUPPORTED');
    }
    validateSettings(envelope.settings);
    return true;
  }

  function browserStorage() {
    if (!root || !root.localStorage) return null;
    return {
      type: 'localStorage',
      path() { return 'localStorage://' + STORAGE_KEY; },
      write(envelope) {
        const previous = root.localStorage.getItem(STORAGE_KEY);
        if (previous !== null) root.localStorage.setItem(STORAGE_KEY + '.bak', previous);
        root.localStorage.setItem(STORAGE_KEY, JSON.stringify(envelope));
      },
      read() {
        const primary = root.localStorage.getItem(STORAGE_KEY);
        if (primary === null) return null;
        try {
          const parsed = JSON.parse(primary);
          validateEnvelope(parsed);
          return parsed;
        } catch (primaryError) {
          const backup = root.localStorage.getItem(STORAGE_KEY + '.bak');
          if (backup === null) throw primaryError;
          const parsed = JSON.parse(backup);
          validateEnvelope(parsed);
          return parsed;
        }
      },
      remove() {
        root.localStorage.removeItem(STORAGE_KEY);
        root.localStorage.removeItem(STORAGE_KEY + '.bak');
      }
    };
  }

  function nwStorage() {
    if (!root || typeof root.require !== 'function' ||
        !root.nw || !root.nw.App || !root.nw.App.dataPath) return null;

    const fs = root.require('fs');
    const path = root.require('path');
    const target = path.join(root.nw.App.dataPath, 'settings.json');
    const tmp = target + '.tmp';
    const bak = target + '.bak';

    return {
      type: 'nw-file',
      path() { return target; },
      write(envelope) {
        const json = JSON.stringify(envelope, null, 2) + '\n';
        const fd = fs.openSync(tmp, 'w');
        try {
          fs.writeFileSync(fd, json, 'utf8');
          fs.fsyncSync(fd);
        } finally {
          fs.closeSync(fd);
        }

        try {
          if (fs.existsSync(target)) {
            if (fs.existsSync(bak)) fs.unlinkSync(bak);
            fs.renameSync(target, bak);
          }
          fs.renameSync(tmp, target);
        } catch (error) {
          if (!fs.existsSync(target) && fs.existsSync(bak)) {
            fs.renameSync(bak, target);
          }
          if (fs.existsSync(tmp)) {
            try { fs.unlinkSync(tmp); } catch (_) {}
          }
          throw error;
        }
      },
      read() {
        if (!fs.existsSync(target)) return null;
        try {
          const parsed = JSON.parse(fs.readFileSync(target, 'utf8'));
          validateEnvelope(parsed);
          return parsed;
        } catch (primaryError) {
          if (!fs.existsSync(bak)) throw primaryError;
          const parsed = JSON.parse(fs.readFileSync(bak, 'utf8'));
          validateEnvelope(parsed);
          return parsed;
        }
      },
      remove() {
        for (const file of [target,tmp,bak]) {
          if (fs.existsSync(file)) fs.unlinkSync(file);
        }
      }
    };
  }

  function getStorage() {
    return nwStorage() || browserStorage() || null;
  }

  function load() {
    const storage = getStorage();
    if (!storage) {
      return { settings: defaults(), storageType: 'memory-defaults', path: null, isDefault: true };
    }
    const envelope = storage.read();
    if (!envelope) {
      return { settings: defaults(), storageType: storage.type, path: storage.path(), isDefault: true };
    }
    validateEnvelope(envelope);
    return {
      settings: clone(envelope.settings),
      envelope,
      storageType: storage.type,
      path: storage.path(),
      isDefault: false
    };
  }

  function save(settings) {
    const storage = getStorage();
    if (!storage) throw new Error('SETTINGS_STORAGE_UNAVAILABLE');
    const envelope = makeEnvelope(settings);
    storage.write(envelope);
    return {
      settings: clone(envelope.settings),
      envelope,
      storageType: storage.type,
      path: storage.path()
    };
  }

  function update(current, patch) {
    const next = Object.assign({}, clone(current || defaults()), clone(patch || {}));
    validateSettings(next);
    return next;
  }

  return Object.freeze({
    VERSION,
    SCHEMA_VERSION,
    STORAGE_KEY,
    DEFAULTS,
    SETTING_ORDER,
    ENUMS,
    defaults,
    validateSettings,
    validateEnvelope,
    makeEnvelope,
    getStorage,
    load,
    save,
    update
  });
});
