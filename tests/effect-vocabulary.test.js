const assert = require('assert');
const vocabulary = require('../modules/effect-vocabulary.js');

const expectedKinds = [
  'damage',
  'restore',
  'resource',
  'modifier',
  'status',
  'reveal',
  'movement',
];

const expectedActions = [
  'staffStrike',
  'uncoverTruth',
  'sharedDream',
  'mycelialLedger',
  'hold',
  'windWard',
  'aetherSeal',
  'rest',
];

assert.strictEqual(vocabulary.VERSION, '0.1.0');
assert.deepStrictEqual(Object.values(vocabulary.EFFECT_KIND), expectedKinds);
assert.deepStrictEqual(Object.keys(vocabulary.ACTION_EFFECT_PROFILES), expectedActions);
assert.strictEqual(vocabulary.validateVocabulary(), true);

const actionFixture = expectedActions.map(id => ({ id, effectProfile: id }));
assert.strictEqual(vocabulary.assertActionCoverage(actionFixture), true);

assert(Object.isFrozen(vocabulary.EFFECT_KIND), 'effect kinds must be frozen');
assert(Object.isFrozen(vocabulary.ACTION_EFFECT_PROFILES), 'effect profiles must be frozen');

const uncoverSuccess = vocabulary.ACTION_EFFECT_PROFILES.uncoverTruth.success;
assert(uncoverSuccess.some(effect =>
  effect.kind === vocabulary.EFFECT_KIND.REVEAL &&
  effect.key === 'weakness' &&
  effect.runtimeStatus === vocabulary.RUNTIME_STATUS.IMPLEMENTED
), 'Uncover Truth weakness reveal must be implemented');

assert(uncoverSuccess.some(effect =>
  effect.kind === vocabulary.EFFECT_KIND.MODIFIER &&
  effect.key === 'nextDamageMultiplier' &&
  effect.runtimeStatus === vocabulary.RUNTIME_STATUS.IMPLEMENTED
), 'Uncover Truth analysis modifier must be implemented');

const mycelialSuccess = vocabulary.ACTION_EFFECT_PROFILES.mycelialLedger.success;
for (const key of ['relationships', 'dependencies', 'exchanges', 'obligations']) {
  assert(mycelialSuccess.some(effect =>
    effect.kind === vocabulary.EFFECT_KIND.REVEAL &&
    effect.key === key &&
    effect.runtimeStatus === vocabulary.RUNTIME_STATUS.IMPLEMENTED
  ), 'Mycelial Ledger must implement read-only reveal: ' + key);
}
assert.strictEqual(
  vocabulary.ACTION_EFFECT_PROFILES.mycelialLedger.common.length, 0,
  'Mycelial Ledger must not generate Heat or other common mutations'
);
assert.strictEqual(
  vocabulary.ACTION_EFFECT_PROFILES.mycelialLedger.partial.length, 0,
  'Mycelial Ledger must not retain legacy partial-outcome mutations'
);
assert.strictEqual(
  vocabulary.ACTION_EFFECT_PROFILES.mycelialLedger.failure.length, 0,
  'Mycelial Ledger must not retain legacy failure mutations'
);

const sharedDreamSuccess = vocabulary.ACTION_EFFECT_PROFILES.sharedDream.success;
assert(sharedDreamSuccess.some(effect =>
  effect.kind === vocabulary.EFFECT_KIND.MODIFIER &&
  effect.runtimeStatus === vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED
), 'Shared Dream modifier debt must remain explicit');

assert(!Object.values(vocabulary.EFFECT_KIND).includes('scriptHook'),
  'script hooks are intentionally outside effect vocabulary v0.1');

console.log('Aetherwake effect vocabulary contract: PASS');
console.log(JSON.stringify({
  version: vocabulary.VERSION,
  kinds: Object.values(vocabulary.EFFECT_KIND),
  actionProfiles: Object.keys(vocabulary.ACTION_EFFECT_PROFILES),
  implementedAnalysis: [
    'uncoverTruth.reveal',
    'uncoverTruth.nextDamageMultiplier',
    'mycelialLedger.relationships',
    'mycelialLedger.dependencies',
    'mycelialLedger.exchanges',
    'mycelialLedger.obligations',
  ],
  declaredNotApplied: [
    'sharedDream.nextRoll',
  ],
}, null, 2));
