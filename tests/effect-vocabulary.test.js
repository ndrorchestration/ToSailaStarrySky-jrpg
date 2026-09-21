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
  effect.runtimeStatus === vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED
), 'Uncover Truth reveal debt must remain explicit');

assert(uncoverSuccess.some(effect =>
  effect.kind === vocabulary.EFFECT_KIND.MODIFIER &&
  effect.runtimeStatus === vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED
), 'Uncover Truth next-roll modifier debt must remain explicit');

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
  declaredNotApplied: [
    'uncoverTruth.reveal',
    'uncoverTruth.nextRoll',
    'sharedDream.nextRoll',
  ],
}, null, 2));
