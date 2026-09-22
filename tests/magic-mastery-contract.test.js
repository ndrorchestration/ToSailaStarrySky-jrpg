const assert = require('assert');
const mastery = require('../modules/magic-mastery.js');

assert.strictEqual(mastery.runtimeStatus, 'PURE_DESIGN_ELIGIBILITY_ONLY');

assert.strictEqual(mastery.compressedTier(0), 0);
assert.strictEqual(mastery.compressedTier(1), 1);
assert.strictEqual(mastery.compressedTier(2), 1);
assert.strictEqual(mastery.compressedTier(3), 2);
assert.strictEqual(mastery.compressedTier(4), 2);
assert.strictEqual(mastery.compressedTier(5), 3);

assert.throws(() => mastery.normalizeProfile({ trees: { fire: 6 } }), /MAGIC_MASTERY_INVALID_RANK/);
assert.throws(() => mastery.normalizeProfile({ trees: { void: 1 } }), /MAGIC_MASTERY_UNKNOWN_TREE/);
assert.throws(() => mastery.normalizeProfile({ domains: { holy: 1 } }), /MAGIC_MASTERY_UNKNOWN_DOMAIN/);

let access = mastery.evaluateTreeAccess({ trees: { water: 1 } }, 'frost');
assert.strictEqual(access.eligible, false);
assert.strictEqual(access.missingAll.length, 1);

access = mastery.evaluateTreeAccess({ trees: { water: 2 } }, 'frost');
assert.strictEqual(access.eligible, true);

access = mastery.evaluateTreeAccess({ trees: { air: 2 } }, 'sonic');
assert.strictEqual(access.eligible, true);

access = mastery.evaluateTreeAccess({ domains: { resonance: 2 } }, 'sonic');
assert.strictEqual(access.eligible, true);

access = mastery.evaluateTreeAccess({ trees: { air: 3, lightning: 3, water: 2 } }, 'storm');
assert.strictEqual(access.eligible, true);
assert.strictEqual(access.benefitsActive.length, 1);

access = mastery.evaluateTreeAccess({ trees: { air: 3, lightning: 2 } }, 'storm');
assert.strictEqual(access.eligible, false);

access = mastery.evaluateTreeAccess({ trees: { fire: 4 }, domains: { aether: 1 } }, 'plasma');
assert.strictEqual(access.eligible, false);

access = mastery.evaluateTreeAccess({ trees: { fire: 4 }, domains: { aether: 2 } }, 'plasma');
assert.strictEqual(access.eligible, true);

let synergy = mastery.evaluateSynergy({ trees: { storm: 1, lightning: 5 } }, 'storm', 'lightning');
assert.strictEqual(synergy.active, false);
assert.strictEqual(synergy.level, 'none');

synergy = mastery.evaluateSynergy({ trees: { storm: 3, lightning: 5 } }, 'storm', 'lightning');
assert.strictEqual(synergy.active, true);
assert.strictEqual(synergy.level, 'cross-school-art');
assert.strictEqual(synergy.grand, null);

synergy = mastery.evaluateSynergy({ trees: { storm: 5, lightning: 5 } }, 'storm', 'lightning');
assert.strictEqual(synergy.active, true);
assert.strictEqual(synergy.level, 'grand-synthesis-art');
assert.strictEqual(synergy.grand, 'Heavenbreak Tempest');

synergy = mastery.evaluateSynergy({ trees: { crystal: 4 }, domains: { lumen: 4 } }, 'lumen', 'crystal');
assert.strictEqual(synergy.active, true);
assert.strictEqual(synergy.level, 'advanced-synergy-passive');

const available = mastery.availableSynergies({
  trees: { storm: 5, lightning: 5, crystal: 3 },
  domains: { lumen: 3 }
});
assert.ok(available.some(x => x.a === 'storm' && x.b === 'lightning' && x.grand === 'Heavenbreak Tempest'));
assert.ok(available.some(x => (x.a === 'crystal' && x.b === 'lumen') && x.level === 'cross-school-art'));

assert.deepStrictEqual(mastery.reactionFor('wet', 'lightning'), {
  state: 'wet',
  applied: 'lightning',
  reaction: 'conduct'
});
assert.strictEqual(mastery.reactionFor('wet', 'sonic'), null);

console.log('magic-mastery contract: PASS');
