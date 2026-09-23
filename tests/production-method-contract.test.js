'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const contract = fs.readFileSync(
  path.join(repo, 'docs', 'AI_ASSISTED_PRODUCTION_CONTRACT.md'),
  'utf8'
);
const registry = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'production-registries.json'),
  'utf8'
));
const registryIndex = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'production-registry-index.json'),
  'utf8'
));
const decisionLog = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'DECISION_LOG.json'),
  'utf8'
));

assert(contract.includes('design specification -> AI draft -> human review -> validation -> repository / SSOT'),
  'AI admission path must remain explicit and human-gated');
assert(contract.includes('Runtime dialogue remains deterministic and authored by default'),
  'runtime dialogue must remain deterministic/authored by default');
assert(contract.includes('Do not scale regions, quests, enemies, items, abilities, or final assets'),
  'evidence-before-scale boundary must remain explicit');
assert(contract.includes('Combat depth is measured by readable tradeoffs, not move count'),
  'combat admission rule must preserve decision-space priority');
assert(contract.includes('Regression plans must cover transitions and permutations'),
  'state-space QA rule must remain explicit');

assert.strictEqual(registry.version, 1);
assert.deepStrictEqual(
  registry.aiAdmissionPath,
  ['design-specification','ai-draft','human-review','validation','repository-or-ssot']
);
const ids = new Set(registry.registries.map(entry => entry.id));
for (const id of ['canonical-lore','content','asset-provenance','decision-log']) {
  assert(ids.has(id), 'missing required production registry: ' + id);
}
assert(registry.registries.every(entry => entry.required === true),
  'all four production registries must remain required');
assert.strictEqual(registry.contentScaleGate.blocking, true,
  'content scale gate must remain blocking');
assert(registry.contentScaleGate.requires.includes('representative-slice-completable-without-live-explanation'),
  'content scale gate must require independent player comprehension');
assert(registry.contentScaleGate.requires.includes('save-load-and-restart-stable'),
  'content scale gate must preserve persistence/restart evidence');
assert(registry.combatBudgetFields.length >= 7,
  'combat budget must retain the full representative parameter set');
assert(registry.stateSpaceQACategories.includes('quest-order-permutations'),
  'state-space QA must include quest-order permutations');
assert(registry.stateSpaceQACategories.includes('invalid-newest-save-fallback'),
  'state-space QA must include invalid-newest-save fallback');

const indexedIds = new Set(registryIndex.registries.map(entry => entry.id));
for (const id of ['canonical-lore','content','asset-provenance','decision-log']) {
  assert(indexedIds.has(id), 'production registry index missing: ' + id);
}
for (const entry of registryIndex.registries) {
  assert(Array.isArray(entry.authorityPaths) && entry.authorityPaths.length > 0,
    'registry index entry has no authority paths: ' + entry.id);
  for (const relative of entry.authorityPaths) {
    assert(fs.existsSync(path.join(repo, relative)),
      'indexed authority path does not exist: ' + relative);
  }
}

assert(Array.isArray(decisionLog.entries) && decisionLog.entries.length >= 2,
  'production decision log must retain the adopted production-method decisions');
for (const entry of decisionLog.entries) {
  assert(entry.status === 'adopted', 'decision log entry is not adopted: ' + entry.id);
  assert(typeof entry.runtimeImpact === 'string' &&
         typeof entry.canonImpact === 'string' &&
         typeof entry.saveSchemaImpact === 'string',
    'decision log entry must declare runtime/canon/save impacts: ' + entry.id);
}

console.log('Aetherwake AI-assisted production contract: PASS');
