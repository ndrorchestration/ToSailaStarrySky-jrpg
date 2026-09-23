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
  'visual-benchmark-set',
  'uncoached-external-player'
]) {
  assert(ids.has(required), 'required First Wake benchmark gate missing: ' + required);
}

const externalPlayer = registry.gates.find(gate => gate.id === 'uncoached-external-player');
assert(externalPlayer, 'external-player M0 gate missing');
assert.strictEqual(externalPlayer.blocking, true,
  'external-player M0 gate must remain blocking');
assert.strictEqual(externalPlayer.status, 'manual',
  'external-player comprehension must remain a manual evidence gate');
assert.strictEqual(externalPlayer.owner, 'docs/M0_EXTERNAL_PLAYTEST.md');
assert(externalPlayer.evidence.includes('docs/M0_EXTERNAL_PLAYTEST.md'));
assert(externalPlayer.evidence.includes('docs/m0-external-playtest-record.template.json'));

const protocol = fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'M0_EXTERNAL_PLAYTEST.md'),
  'utf8'
);
const record = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'm0-external-playtest-record.template.json'),
  'utf8'
));
assert(protocol.includes('do not explain objectives, controls, combat strategy'),
  'external-player protocol must preserve the no-coaching boundary');
assert(protocol.includes('A passing developer smoke test or local M0 run cannot substitute'),
  'manual comprehension evidence must remain distinct from automated verification');
assert.strictEqual(record.result, 'NOT_RUN',
  'playtest template must fail closed before an actual session');
assert.strictEqual(record.constraints.liveCreatorCoachingAllowed, false,
  'playtest template must prohibit live creator coaching');
assert.strictEqual(record.constraints.browserDependencyAllowed, false,
  'playtest candidate must not depend on browser execution');
assert.strictEqual(record.candidate.playerVerifiedStandalone, false,
  'template must not pre-claim player verification');
assert(Object.prototype.hasOwnProperty.call(record.observations, 'objectiveUnderstandingEvidence'),
  'playtest record must capture evidence for objective comprehension');
assert(Array.isArray(record.observations.combatDecisionReasoning),
  'playtest record must capture observed combat decision reasoning');
assert(Object.prototype.hasOwnProperty.call(record.observations, 'recoveryReasoning'),
  'playtest record must capture player-facing recovery reasoning');

const blockers = registry.gates.filter(gate => gate.blocking);
assert(blockers.some(gate => gate.status === 'gap' || gate.status === 'partial' || gate.status === 'manual'),
  'benchmark registry must expose unresolved blocking work honestly');

console.log('Aetherwake First Wake benchmark registry: PASS');
