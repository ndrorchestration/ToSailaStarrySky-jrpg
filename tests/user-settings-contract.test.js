'use strict';

const assert = require('assert');

function loadFresh(root) {
  const modulePath = require.resolve('../modules/user-settings.js');
  delete require.cache[modulePath];
  global.window = root;
  const api = require(modulePath);
  delete global.window;
  return api;
}

function fakeLocalStorage() {
  const map = new Map();
  return {
    getItem(key) { return map.has(key) ? map.get(key) : null; },
    setItem(key, value) { map.set(key, String(value)); },
    removeItem(key) { map.delete(key); },
    _map: map
  };
}

const localStorage = fakeLocalStorage();
const settings = loadFresh({ localStorage });

const first = settings.load();
assert.strictEqual(first.isDefault, true);
assert.strictEqual(first.settings.textScale, '125');
assert.strictEqual(first.settings.subtitles, true);

const changed = settings.update(first.settings, {
  reducedMotion: true,
  screenShake: 'off',
  textSpeed: 'instant',
  musicVolume: 40
});
const saved = settings.save(changed);
assert.strictEqual(saved.storageType, 'localStorage');

const loaded = settings.load();
assert.strictEqual(loaded.isDefault, false);
assert.strictEqual(loaded.settings.reducedMotion, true);
assert.strictEqual(loaded.settings.screenShake, 'off');
assert.strictEqual(loaded.settings.textSpeed, 'instant');
assert.strictEqual(loaded.settings.musicVolume, 40);

assert.throws(
  () => settings.update(loaded.settings, { musicVolume: 101 }),
  /SETTINGS_VOLUME_INVALID:musicVolume/
);
assert.throws(
  () => settings.update(loaded.settings, { textScale: '999' }),
  /SETTINGS_ENUM_INVALID:textScale/
);

// Browser backup fallback: save a second valid record so the first moves to .bak,
// then corrupt primary. Loading must recover the previous validated record.
const previous = settings.update(loaded.settings, { musicVolume: 55 });
settings.save(previous);
const newest = settings.update(previous, { musicVolume: 65 });
settings.save(newest);
localStorage.setItem(settings.STORAGE_KEY, '{broken json');
const recovered = settings.load();
assert.strictEqual(recovered.settings.musicVolume, 55,
  'settings loader must recover validated browser backup after primary corruption');

// Downgrade protection: parseable newer-schema settings must be preserved.
const futureSettings = {
  schemaVersion: settings.SCHEMA_VERSION + 1,
  savedAt: new Date().toISOString(),
  settings: Object.assign({}, recovered.settings, { musicVolume: 77 })
};
localStorage.setItem(settings.STORAGE_KEY, JSON.stringify(futureSettings));
const futurePrimaryRaw = localStorage.getItem(settings.STORAGE_KEY);
assert.throws(
  () => settings.save(recovered.settings),
  /SETTINGS_FUTURE_SCHEMA_PROTECTED:2/
);
assert.strictEqual(localStorage.getItem(settings.STORAGE_KEY), futurePrimaryRaw,
  'older build must not overwrite newer-schema settings primary');

// A newer-schema backup must also be preserved behind a corrupt primary.
localStorage.setItem(settings.STORAGE_KEY, '{broken json');
localStorage.setItem(settings.STORAGE_KEY + '.bak', JSON.stringify(futureSettings));
const futureBackupRaw = localStorage.getItem(settings.STORAGE_KEY + '.bak');
assert.throws(
  () => settings.save(recovered.settings),
  /SETTINGS_FUTURE_SCHEMA_PROTECTED:2/
);
assert.strictEqual(localStorage.getItem(settings.STORAGE_KEY + '.bak'), futureBackupRaw,
  'older build must not overwrite newer-schema settings backup');

console.log('Aetherwake user settings persistence: PASS');
