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

assert.strictEqual(byId.get('air-navigation').status, 'covered');
assert(/independent of envelope schema/.test(byId.get('air-navigation').versionOwner),
  'air-navigation schema must remain explicitly independent from whole-game save schema');
assert.strictEqual(byId.get('opening-authored-sequence').status, 'transient_not_saveable');
assert.strictEqual(byId.get('combat').status, 'transient_not_saveable');

console.log('Aetherwake persistence coverage registry: PASS');
