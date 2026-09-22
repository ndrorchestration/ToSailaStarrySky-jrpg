const assert = require('assert');
const abilities = require('../modules/ability-defs.js');

const costMap = Object.fromEntries(
  abilities.ACTION_ORDER.map(id => [id, abilities.getActionResourceCost(id)])
);

assert.deepStrictEqual(costMap, {
  staffStrike: 0,
  uncoverTruth: 2,
  sharedDream: 2,
  mycelialLedger: 0,
  hold: 0,
  windWard: 2,
  aetherSeal: 3,
  rest: 0,
}, 'legacy action costs changed during centralization');

const pooled = {
  unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
  echoes: { current: 1, max: 3 },
  aether: { current: 1, max: 6 },
};

assert.strictEqual(abilities.getAvailableActionResource(pooled), 2);
assert.strictEqual(abilities.getUseEligibility(pooled, 'uncoverTruth').canUse, true);
assert.strictEqual(abilities.getUseEligibility(pooled, 'sharedDream').canUse, false);
assert.strictEqual(abilities.getUseEligibility(pooled, 'sharedDream').reason, 'ssot_blocked');

const underfunded = {
  unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
  echoes: { current: 1, max: 3 },
  aether: { current: 0, max: 6 },
};

const denied = abilities.getUseEligibility(underfunded, 'uncoverTruth');
assert.strictEqual(denied.canUse, false);
assert.strictEqual(denied.reason, 'insufficient_resources');
assert.strictEqual(denied.resourceCost, 2);
assert.strictEqual(denied.availableResource, 1);

assert.deepStrictEqual(
  abilities.getUsableActionIds(underfunded),
  ['staffStrike', 'mycelialLedger', 'hold'],
  'usable-action set must account for unlock state and pooled resources'
);

const persistentShape = {
  unlockedAbilities: ['uncoverTruth'],
  echoes: 1,
  aether: 1,
};
assert.strictEqual(
  abilities.getUseEligibility(persistentShape, 'uncoverTruth').canUse,
  true,
  'use eligibility must accept persistent numeric resource shape'
);

assert.throws(
  () => abilities.getActionResourceCost('notAnAction'),
  /UNKNOWN_ACTION_FOR_RESOURCE_COST/
);

console.log('Aetherwake resource eligibility contract: PASS');
console.log(JSON.stringify({ abilityVersion: abilities.VERSION, costMap }, null, 2));
