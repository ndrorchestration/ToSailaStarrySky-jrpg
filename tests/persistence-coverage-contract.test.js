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
  'desktop-save-backup-recovery',
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
assert(/before any primary replacement or autosave rotation/.test(byId.get('save-write-semantic-preflight').rationale),
  'save-write semantic preflight must remain ahead of destructive slot mutation');
assert.strictEqual(byId.get('desktop-save-backup-recovery').status, 'derived');
assert(/integrity\/migration and full semantic preflight/.test(byId.get('desktop-save-backup-recovery').rationale),
  'desktop backup recovery must remain gated by integrity, migration, and semantic validation');
assert.strictEqual(byId.get('air-navigation').status, 'covered');
assert(/independent of envelope schema/.test(byId.get('air-navigation').versionOwner),
  'air-navigation schema must remain explicitly independent from whole-game save schema');
assert.strictEqual(byId.get('opening-authored-sequence').status, 'transient_not_saveable');
assert.strictEqual(byId.get('combat').status, 'transient_not_saveable');
assert.strictEqual(byId.get('settings').status, 'covered',
  'user settings persistence must remain independently covered');
assert(/newer-schema primary\/backup sidecars are downgrade-protected/.test(byId.get('settings').rationale),
  'settings persistence must preserve newer-schema sidecars during downgrade');
assert.strictEqual(byId.get('settings').versionOwner, 'user-settings SCHEMA_VERSION',
  'user settings must own an independent schema version');
assert.strictEqual(byId.get('input-bindings').status, 'covered',
  'input remaps must persist independently from game saves');
assert(/newer-schema primary\/backup sidecars are downgrade-protected/.test(byId.get('input-bindings').rationale),
  'input bindings persistence must preserve newer-schema sidecars during downgrade');
assert.strictEqual(byId.get('input-bindings').versionOwner, 'input-bindings SCHEMA_VERSION',
  'input remaps must own an independent schema version');

console.log('Aetherwake persistence coverage registry: PASS');
