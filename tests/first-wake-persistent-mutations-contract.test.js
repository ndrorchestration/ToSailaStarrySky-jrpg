'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const registry = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'first-wake-persistent-mutations.json'),
  'utf8'
));
const live = fs.readFileSync(path.join(repo, 'aetherwake.js'), 'utf8');
const validator = fs.readFileSync(
  path.join(repo, 'modules', 'save-payload-validator.js'),
  'utf8'
);
const coverage = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'persistence-coverage.json'),
  'utf8'
));

assert.strictEqual(registry.version, 1);
assert.strictEqual(registry.milestone, 'M0-reliable-first-wake-benchmark');
assert.strictEqual(registry.policy.unknownPersistentMutation, 'BLOCKING_UNREGISTERED');
assert.strictEqual(registry.policy.deferredSystemsDoNotCountAsImplemented, true);
assert(Array.isArray(registry.mutations) && registry.mutations.length >= 10,
  'First Wake mutation registry is unexpectedly sparse');

const ids = new Set();
for (const mutation of registry.mutations) {
  assert(mutation.id && !ids.has(mutation.id),
    'duplicate/missing mutation id: ' + mutation.id);
  ids.add(mutation.id);
  for (const key of [
    'runtimeSource','payloadPath','snapshotEvidence',
    'restoreEvidence','validatorEvidence','versionOwner'
  ]) {
    assert(typeof mutation[key] === 'string' && mutation[key].length > 0,
      mutation.id + ' missing ' + key);
  }
  assert(live.includes(mutation.snapshotEvidence),
    mutation.id + ' snapshot owner drifted: ' + mutation.snapshotEvidence);
  assert(live.includes(mutation.restoreEvidence),
    mutation.id + ' restore owner drifted: ' + mutation.restoreEvidence);
  assert(validator.includes(mutation.validatorEvidence) ||
         live.includes(mutation.validatorEvidence),
    mutation.id + ' validator owner drifted: ' + mutation.validatorEvidence);
}

for (const required of [
  'world-player-position',
  'world-covenant-field',
  'world-commons-ledger',
  'quest-first-wake-progression',
  'party-roster-progression',
  'party-active-formation',
  'air-navigation'
]) {
  assert(ids.has(required), 'required persistent mutation unregistered: ' + required);
}

const deferred = new Set((registry.explicitlyDeferred || []).map(x => x.id));
assert(deferred.has('economy-crafting'));
assert(deferred.has('relationships-private-actions'));

const byId = new Map(coverage.subsystems.map(x => [x.id, x]));
const mutationControl = byId.get('world-mutations-beyond-covered-fields');
assert(mutationControl,
  'persistence coverage must retain world-mutation registration control');
assert.strictEqual(mutationControl.status, 'derived',
  'world-mutation coverage entry must describe the derived registration control');
assert(/first-wake-persistent-mutations\.json/.test(mutationControl.rationale),
  'persistence coverage must route mutation ownership to the registry');
assert.strictEqual(byId.get('economy-crafting').status, 'gap');
assert.strictEqual(byId.get('relationships-private-actions').status, 'gap');

console.log('Aetherwake First Wake persistent mutation registry: PASS');
