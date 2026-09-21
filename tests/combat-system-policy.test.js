const assert = require('node:assert/strict');
const policy = require('../modules/combat-system-policy.js');

assert.equal(policy.VERSION, '0.1.0');
assert.equal(policy.validate(), true);
assert.equal(policy.TARGET.model, 'jrpg-stat-formula');
assert.equal(policy.TARGET.turnStructure, 'turn-based');
assert.equal(policy.TARGET.visibleDice, false);
assert.equal(policy.TARGET.outcomeBands, false);
assert.equal(policy.TARGET.primaryResolution, 'stats+ability-formulas');
assert.equal(policy.TARGET.rngRole, 'secondary-bounded');

assert.deepEqual(Array.from(policy.ALLOWED_RNG_USES), [
  'accuracy-evasion',
  'critical-hit',
  'status-application',
  'bounded-damage-variance',
  'enemy-ai-choice',
]);

assert.equal(policy.MIGRATION.legacyModel, '2d6-pbta-outcome-bands');
assert.equal(policy.MIGRATION.legacyStatus, 'compatibility-only');
assert.equal(policy.MIGRATION.preserveGameplayIntent, true);
assert.equal(policy.MIGRATION.preserveExplicitResourceEvidence, true);
assert.equal(policy.MIGRATION.preserveLegacyRollSemanticsAsTarget, false);
assert.equal(policy.MIGRATION.requireNewFormulaContractBeforeAuthorization, true);

for (const field of [
  'targeting',
  'costs',
  'power',
  'scaling',
  'defenseInteraction',
  'elementOrType',
  'accuracyPolicy',
  'criticalPolicy',
  'variancePolicy',
  'effects',
]) {
  assert(policy.TARGET_ABILITY_METADATA.includes(field), 'missing target ability metadata: ' + field);
}

console.log('Aetherwake JRPG combat direction contract: PASS');
