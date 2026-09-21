const assert = require('assert');
const effects = require('../modules/effect-vocabulary.js');
const abilities = require('../modules/ability-defs.js');
const progression = require('../modules/progression-defs.js');

const expectedActionOrder = [
  'staffStrike',
  'uncoverTruth',
  'sharedDream',
  'mycelialLedger',
  'hold',
  'windWard',
  'aetherSeal',
  'rest',
];

assert.strictEqual(abilities.VERSION, '0.5.0');
assert.strictEqual(progression.VERSION, '0.1.0');
assert.deepStrictEqual(abilities.ACTION_ORDER, expectedActionOrder);
assert.strictEqual(abilities.validateDefs(), true);

const runtimeActions = abilities.createRuntimeActions();
assert.strictEqual(abilities.assertRuntimeActions(runtimeActions), true);
assert.strictEqual(effects.assertActionCoverage(runtimeActions), true);
assert.strictEqual(progression.validateAgainstAbilityDefs(abilities), true);

assert.deepStrictEqual(
  Object.keys(progression.LEVEL_UNLOCKS),
  ['3', '4', '5'],
  'legacy unlock levels must remain behavior-preserving'
);
assert.deepStrictEqual(
  progression.getUnlocksForLevel(3).map(entry => entry.abilityId),
  ['windWard']
);
assert.deepStrictEqual(
  progression.getUnlocksForLevel(4).map(entry => entry.abilityId),
  ['aetherSeal']
);
assert.deepStrictEqual(
  progression.getUnlocksForLevel(5).map(entry => entry.abilityId),
  ['rest']
);
assert.deepStrictEqual(progression.getUnlocksForLevel(2), []);

const level1Actor = {
  unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
};
assert.deepStrictEqual(
  abilities.getEligibleActionIds(level1Actor),
  ['staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold'],
  'level-1 eligibility must enforce current unlock state'
);
assert.strictEqual(abilities.isActionUnlocked(level1Actor, 'windWard'), false);
assert.strictEqual(abilities.isActionUnlocked(level1Actor, 'aetherSeal'), false);
assert.strictEqual(abilities.isActionUnlocked(level1Actor, 'rest'), false);

const fullyUnlockedActor = {
  unlockedAbilities: [
    'uncoverTruth', 'sharedDream', 'mycelialLedger',
    'windWard', 'aetherSeal', 'rest',
  ],
};
assert.deepStrictEqual(
  abilities.getEligibleActionIds(fullyUnlockedActor),
  expectedActionOrder,
  'fully unlocked actor should expose all current actions'
);

assert.strictEqual(abilities.getActionResourceCost('staffStrike'), 0);
assert.deepStrictEqual(abilities.DEFS.staffStrike.resolution, {
  model: 'jrpg-stat-formula',
  formulaId: 'staffStrike',
});
assert.strictEqual(abilities.getActionResourceCost('uncoverTruth'), 2);
assert.strictEqual(abilities.getActionResourceCost('sharedDream'), 2);
assert.strictEqual(abilities.getActionResourceCost('mycelialLedger'), 0);
assert.strictEqual(abilities.getActionResourceCost('hold'), 0);
assert.deepStrictEqual(abilities.DEFS.hold.resolution, {
  model: 'jrpg-stat-formula',
  formulaId: 'hold',
});
assert.deepStrictEqual(abilities.DEFS.rest.resolution, {
  model: 'jrpg-stat-formula',
  formulaId: 'rest',
});
assert.strictEqual(abilities.getActionResourceCost('windWard'), 2);
assert.strictEqual(abilities.getActionResourceCost('aetherSeal'), 3);
assert.strictEqual(abilities.getActionResourceCost('rest'), 0);

const exactFundsActor = {
  unlockedAbilities: ['uncoverTruth'],
  echoes: { current: 1, max: 3 },
  aether: { current: 1, max: 6 },
};
assert.deepStrictEqual(
  abilities.getUseEligibility(exactFundsActor, 'uncoverTruth'),
  {
    canUse: true,
    reason: 'ok',
    actionId: 'uncoverTruth',
    resourceCost: 2,
    availableResource: 2,
  }
);

const underfundedActor = {
  unlockedAbilities: ['uncoverTruth'],
  echoes: { current: 1, max: 3 },
  aether: { current: 0, max: 6 },
};
assert.deepStrictEqual(
  abilities.getUseEligibility(underfundedActor, 'uncoverTruth'),
  {
    canUse: false,
    reason: 'insufficient_resources',
    actionId: 'uncoverTruth',
    resourceCost: 2,
    availableResource: 1,
  }
);
assert.strictEqual(
  abilities.getUseEligibility(underfundedActor, 'windWard').reason,
  'locked',
  'unlock failure must take precedence over resource failure'
);
assert.strictEqual(
  abilities.getUseEligibility(underfundedActor, 'staffStrike').canUse,
  true,
  'zero-cost baseline actions must remain usable without pooled resources'
);

assert(Object.isFrozen(abilities.DEFS), 'ability definitions must be frozen');
assert(Object.isFrozen(abilities.ALWAYS_AVAILABLE), 'always-available actions must be frozen');
assert(Object.isFrozen(progression.LEVEL_UNLOCKS), 'progression definitions must be frozen');

const copy = abilities.createRuntimeActions();
copy[0].label = 'mutated copy';
assert.notStrictEqual(copy[0].label, abilities.DEFS.staffStrike.label,
  'runtime action copies must not mutate canonical definitions');

console.log('Aetherwake registry contract: PASS');
console.log(JSON.stringify({
  abilityVersion: abilities.VERSION,
  progressionVersion: progression.VERSION,
  actionOrder: abilities.ACTION_ORDER,
  levelUnlocks: Object.fromEntries(
    Object.entries(progression.LEVEL_UNLOCKS)
      .map(([level, entries]) => [level, entries.map(entry => entry.abilityId)])
  ),
}, null, 2));
