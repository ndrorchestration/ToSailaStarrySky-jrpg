const assert = require('assert');
const scaling = require('../modules/encounter-scaling.js');

assert.strictEqual(scaling.VERSION, '0.1.0');

const baseline = {
  name: 'Baseline Enemy',
  hp: 100,
  maxHp: 100,
  recommendedLevel: 20,
  recommendedPartySize: 3,
};

const equal = scaling.scaleEnemy(baseline, {
  partyLevels: [20, 20, 20],
  partySize: 3,
});
assert.strictEqual(equal.hp, 100);
assert.strictEqual(equal.maxHp, 100);
assert.strictEqual(equal.scaling.hpFactor, 1);
assert.strictEqual(equal.scaling.threatTier, 0);

const fiveMember = scaling.scaleEnemy(baseline, {
  partyLevels: [20, 20, 20, 20, 20],
  partySize: 5,
});
assert(fiveMember.hp > equal.hp, 'five-member party should increase encounter durability');
assert.strictEqual(fiveMember.scaling.partySize, 5);
assert.strictEqual(fiveMember.scaling.partyDelta, 2);

const overleveled = scaling.scaleEnemy(baseline, {
  partyLevels: [40, 40, 40],
  partySize: 3,
});
assert(overleveled.hp > equal.hp, 'bounded over-level adjustment should increase durability');
assert.strictEqual(overleveled.scaling.boundedLevelDelta, 18);

const underleveled = scaling.scaleEnemy(baseline, {
  partyLevels: [5, 5, 5],
  partySize: 3,
});
assert(underleveled.hp < equal.hp, 'under-level adjustment should reduce durability');
assert.strictEqual(underleveled.scaling.boundedLevelDelta, -8);

const hugeLevel = scaling.scaleEnemy(baseline, {
  partyLevels: [175, 175, 175, 175, 175],
  partySize: 5,
});
assert(hugeLevel.scaling.hpFactor <= scaling.LIMITS.MAX_HP_FACTOR);
assert(hugeLevel.scaling.threatTier <= 5);

const fallback = scaling.scaleEnemy({ hp: 12, maxHp: 12 }, {
  partyLevels: [10, 10],
  partySize: 2,
});
assert.strictEqual(fallback.hp, 12,
  'encounters without authored baseline metadata should preserve current difficulty');

console.log('Aetherwake encounter scaling contract: PASS');
console.log(JSON.stringify({
  baselineHp: equal.hp,
  fiveMemberHp: fiveMember.hp,
  overleveledHp: overleveled.hp,
  underleveledHp: underleveled.hp,
  cappedHighLevelHp: hugeLevel.hp,
}, null, 2));
