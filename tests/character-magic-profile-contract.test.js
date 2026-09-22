const assert = require('assert');
const profileApi = require('../modules/character-magic-profile.js');

assert.strictEqual(profileApi.runtimeStatus, 'PURE_PROFILE_NOT_PERSISTED');

const ender = profileApi.createProfile('ender');
assert.deepStrictEqual(ender.innateAffinities, ['aether', 'resonance', 'correspondence', 'lumen']);
assert.strictEqual(ender.affinityStatus, 'established');

// Affinity must never silently grant mastery.
for (const id of ender.innateAffinities) {
  assert.strictEqual(profileApi.rankFor(ender, id), 0, `${id} affinity must not imply mastery`);
}

const lyra = profileApi.createProfile('lyra');
const ionia = profileApi.createProfile('ionia');
const reson = profileApi.createProfile('reson');
const aepex = profileApi.createProfile('aepex');

for (const character of [lyra, ionia, reson, aepex]) {
  assert.strictEqual(character.affinityStatus, 'open');
  assert.deepStrictEqual(character.innateAffinities, []);
}

assert.strictEqual(profileApi.hasAffinity(ender, 'aether'), true);
assert.strictEqual(profileApi.hasAffinity(ender, 'fire'), false);

const trained = profileApi.withMasteryRank(ender, 'fire', 3);
assert.strictEqual(profileApi.rankFor(trained, 'fire'), 3);
assert.strictEqual(profileApi.rankFor(ender, 'fire'), 0, 'profile updates must be immutable');

const tuned = profileApi.withMasteryRank(trained, 'resonance', 2);
assert.strictEqual(profileApi.rankFor(tuned, 'resonance'), 2);
assert.strictEqual(profileApi.hasAffinity(tuned, 'resonance'), true);

assert.throws(() => profileApi.createProfile('talen'), /UNKNOWN_CHARACTER/);
assert.throws(() => profileApi.hasAffinity(ender, 'holy'), /UNKNOWN_AFFINITY/);
assert.throws(() => profileApi.withMasteryRank(ender, 'dreaming', 1), /UNKNOWN_MASTERY_ID/);
assert.throws(() => profileApi.withMasteryRank(ender, 'fire', 6), /INVALID_RANK/);

assert.throws(() => profileApi.validateProfile({
  characterId: 'ender',
  innateAffinities: ['aether', 'aether'],
  mastery: { trees: {}, domains: {} }
}), /DUPLICATE_AFFINITY/);

console.log('character-magic-profile contract: PASS');
