'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const registry = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'first-wake-benchmark.json'),
  'utf8'
));

assert.strictEqual(registry.version, 1);
assert.strictEqual(registry.milestone, 'M0-reliable-first-wake-benchmark');
assert(Array.isArray(registry.gates) && registry.gates.length >= 12,
  'First Wake benchmark must define a representative gate set');

const allowed = new Set(['automated','partial','manual','gap']);
const ids = new Set();

for (const gate of registry.gates) {
  assert(gate && typeof gate.id === 'string' && gate.id.length > 0, 'benchmark gate id missing');
  assert(!ids.has(gate.id), 'duplicate benchmark gate: ' + gate.id);
  ids.add(gate.id);
  assert(typeof gate.category === 'string' && gate.category.length > 0,
    gate.id + ' category missing');
  assert(typeof gate.blocking === 'boolean', gate.id + ' blocking flag missing');
  assert(allowed.has(gate.status), gate.id + ' has invalid status');
  assert(typeof gate.outcome === 'string' && gate.outcome.length > 0,
    gate.id + ' outcome missing');
  assert(typeof gate.owner === 'string' && gate.owner.length > 0,
    gate.id + ' owner missing');
  assert(Array.isArray(gate.evidence), gate.id + ' evidence must be an array');
  assert(typeof gate.nextAction === 'string' && gate.nextAction.length > 0,
    gate.id + ' next action missing');

  if (gate.status === 'automated') {
    assert(gate.evidence.length > 0, gate.id + ' automated gate needs evidence owner');
  }
  if (gate.status === 'gap') {
    assert(gate.evidence.length === 0, gate.id + ' gap must not claim existing evidence');
  }
}

for (const required of [
  'desktop-installed-launch',
  'desktop-save-restart',
  'title-new-game',
  'authored-opening-00-09',
  'world-handoff',
  'three-signal-contacts',
  'four-crossing-hazards',
  'four-contact-voices',
  'quest-log',
  'combat-roundtrip',
  'manual-save-load',
  'wake-resolution',
  'dragonfly-flight',
  'input-controller-accessibility',
  'visual-benchmark-set'
]) {
  assert(ids.has(required), 'required First Wake benchmark gate missing: ' + required);
}

const blockers = registry.gates.filter(gate => gate.blocking);
assert(blockers.some(gate => gate.status === 'gap' || gate.status === 'partial' || gate.status === 'manual'),
  'benchmark registry must expose unresolved blocking work honestly');

console.log('Aetherwake First Wake benchmark registry: PASS');
