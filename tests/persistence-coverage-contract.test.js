'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const registryPath = path.join(__dirname, '..', 'docs', 'persistence-coverage.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

assert.strictEqual(registry.version, 1);
assert.strictEqual(registry.wholeGameEnvelopeSchema, 1);
assert(Array.isArray(registry.subsystems) && registry.subsystems.length > 0);

const validStatuses = new Set(['covered','derived','transient_not_saveable','gap']);
const byId = new Map();

for (const entry of registry.subsystems) {
  assert(entry && typeof entry.id === 'string' && entry.id.length > 0, 'persistence entry id missing');
  assert(!byId.has(entry.id), 'duplicate persistence entry: ' + entry.id);
  assert(validStatuses.has(entry.status), 'unknown persistence status for ' + entry.id);
  byId.set(entry.id, entry);

  if (entry.status === 'covered') {
    assert(typeof entry.snapshot === 'string' && entry.snapshot.length > 0,
      entry.id + ' missing snapshot owner');
    assert(typeof entry.restore === 'string' && entry.restore.length > 0,
      entry.id + ' missing restore owner');
    assert(typeof entry.validator === 'string' && entry.validator.length > 0,
      entry.id + ' missing validator owner');
    assert(typeof entry.versionOwner === 'string' && entry.versionOwner.length > 0,
      entry.id + ' missing version owner');
  }

  if (entry.status === 'gap') {
    assert(typeof entry.rationale === 'string' && entry.rationale.length > 0,
      entry.id + ' gap must explain its boundary');
  }
}

for (const required of [
  'runtime',
  'save-write-semantic-preflight',
  'future-schema-overwrite-protection',
  'save-backup-recovery',
  'transactional-load-apply',
  'world-position',
  'quest',
  'party-roster',
  'party-formation',
  'character-progression',
  'equipment',
  'magic-profile-mastery',
  'air-navigation',
  'opening-authored-sequence',
  'combat',
]) {
  assert(byId.has(required), 'required persistence subsystem not registered: ' + required);
}

assert.strictEqual(byId.get('save-write-semantic-preflight').status, 'derived');
assert.strictEqual(byId.get('future-schema-overwrite-protection').status, 'derived');
assert(/must not overwrite newer-schema persistent player data/.test(byId.get('future-schema-overwrite-protection').rationale),
  'future-schema overwrite protection must remain explicit across save and sidecar persistence');
assert(/newer primary and an older valid backup may load the older backup/.test(byId.get('future-schema-overwrite-protection').rationale),
  'mixed-version slots must remain loadable-through-backup but non-writable');
assert(/before any primary replacement or autosave rotation/.test(byId.get('save-write-semantic-preflight').rationale),
  'save-write semantic preflight must remain ahead of destructive slot mutation');
assert.strictEqual(byId.get('world-mutations-beyond-covered-fields').status, 'derived',
  'world mutation registration control must remain derived');
assert(/first-wake-persistent-mutations\.json/.test(
  byId.get('world-mutations-beyond-covered-fields').rationale
), 'world mutation registration must route to its explicit ownership registry');
assert(/BLOCKING_UNREGISTERED/.test(
  byId.get('world-mutations-beyond-covered-fields').rationale
), 'unknown future persistent mutations must remain blocking until registered');
assert.strictEqual(byId.get('save-backup-recovery').status, 'derived');
assert(/integrity\/migration and full semantic preflight/.test(byId.get('save-backup-recovery').rationale),
  'save backup recovery must remain gated by integrity, migration, and semantic validation');
assert(/Desktop and browser persistence share this recovery contract/.test(byId.get('save-backup-recovery').rationale),
  'backup recovery contract must cover both desktop and browser persistence');
assert(/Manual overwrite and autosave rotation both preserve the validated backup/.test(byId.get('save-backup-recovery').rationale),
  'manual and autosave replacement must preserve validated recovery backups');
assert.strictEqual(byId.get('air-navigation').status, 'covered');
assert(/independent of envelope schema/.test(byId.get('air-navigation').versionOwner),
  'air-navigation schema must remain explicitly independent from whole-game save schema');
assert.strictEqual(byId.get('opening-authored-sequence').status, 'transient_not_saveable');
assert.strictEqual(byId.get('combat').status, 'transient_not_saveable');
assert.strictEqual(byId.get('settings').status, 'covered',
  'user settings persistence must remain independently covered');
assert(/newer-schema primary\/backup sidecars are downgrade-protected/.test(byId.get('settings').rationale),
  'settings persistence must preserve newer-schema sidecars during downgrade');
assert(/Missing\/corrupt primaries recover from validated backup with explicit provenance/.test(byId.get('settings').rationale),
  'settings persistence must retain explicit recovery provenance');
assert(/first post-recovery edit preserves that backup/.test(byId.get('settings').rationale),
  'settings persistence must preserve the validated recovery backup on first edit');
assert.strictEqual(byId.get('settings').versionOwner, 'user-settings SCHEMA_VERSION',
  'user settings must own an independent schema version');
assert.strictEqual(byId.get('input-bindings').status, 'covered',
  'input remaps must persist independently from game saves');
assert(/newer-schema primary\/backup sidecars are downgrade-protected/.test(byId.get('input-bindings').rationale),
  'input bindings persistence must preserve newer-schema sidecars during downgrade');
assert(/Missing\/corrupt primaries recover from validated backup with explicit provenance/.test(byId.get('input-bindings').rationale),
  'input bindings persistence must retain explicit recovery provenance');
assert(/first post-recovery edit preserves that backup/.test(byId.get('input-bindings').rationale),
  'input bindings persistence must preserve the validated recovery backup on first edit');
assert.strictEqual(byId.get('input-bindings').versionOwner, 'input-bindings SCHEMA_VERSION',
  'input remaps must own an independent schema version');

console.log('Aetherwake persistence coverage registry: PASS');

assert.strictEqual(byId.get('transactional-load-apply').status, 'derived');
assert(/late runtime exception during rehydration/.test(byId.get('transactional-load-apply').rationale),
  'load application must remain transactional after semantic preflight');
assert(/rollback itself fails/.test(byId.get('transactional-load-apply').rationale),
  'load transaction must fail closed if rollback cannot restore the prior runtime');
assert(/Success markers are written only after apply commits/.test(byId.get('transactional-load-apply').rationale),
  'load evidence must reflect committed outcomes only');
