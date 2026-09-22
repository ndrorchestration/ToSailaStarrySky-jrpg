const assert = require('assert');
const magic = require('../modules/magic-defs.js');

assert.strictEqual(magic.runtimeStatus, 'DESIGN_CONTRACT_NOT_EXECUTABLE');
assert.strictEqual(Object.keys(magic.ELEMENTAL_TREES).length, 11);
assert.deepStrictEqual(
  ['fire','water','air','earth'].map(id => magic.getTree(id).tier),
  ['primal','primal','primal','primal']
);

for (const [id, tree] of Object.entries(magic.ELEMENTAL_TREES)) {
  assert.strictEqual(tree.id, id, `tree id mismatch: ${id}`);
  assert.strictEqual(tree.ranks.length, 5, `${id} must define five mastery ranks`);
  assert.ok(tree.verb, `${id} missing core verb`);
  assert.ok(tree.governs && tree.governs.length > 0, `${id} missing governed concepts`);
}

assert.ok(magic.getTree('earth').branches.includes('sand-dust'));
assert.ok(magic.getTree('earth').branches.includes('magma'));
assert.ok(magic.getTree('earth').branches.includes('glass-vitrification'));
assert.ok(magic.getTree('water').branches.includes('steam'));
assert.strictEqual(magic.getTree('sonic').verb, 'vibrate');
assert.strictEqual(magic.getDomain('resonance').verb, 'attune');
assert.notStrictEqual(magic.getTree('sonic').verb, magic.getDomain('resonance').verb);

assert.strictEqual(magic.EXCEPTIONAL_POWERS.dreaming.ordinaryLearnable, false);
assert.ok(magic.METAPHYSICAL_MODIFIERS.includes('sanctified'));
assert.ok(magic.METAPHYSICAL_MODIFIERS.includes('profaned'));
assert.ok(!magic.NON_ELEMENTAL_DOMAINS.holy);
assert.ok(!magic.NON_ELEMENTAL_DOMAINS.unholy);

assert.deepStrictEqual(magic.ENVIRONMENT_CHANNELS, [
  'atmosphere','surface','temperature','charge'
]);

for (const synergy of magic.CROSS_MASTERY) {
  assert.ok(synergy.a && synergy.b && synergy.behavior && synergy.grand);
  const aExists = magic.ELEMENTAL_TREES[synergy.a] || magic.NON_ELEMENTAL_DOMAINS[synergy.a];
  const bExists = magic.ELEMENTAL_TREES[synergy.b] || magic.NON_ELEMENTAL_DOMAINS[synergy.b];
  assert.ok(aExists, `unknown synergy source: ${synergy.a}`);
  assert.ok(bExists, `unknown synergy source: ${synergy.b}`);
}

assert.strictEqual(magic.SYNERGY_THRESHOLDS['3+3'], 'cross-school-art');
assert.strictEqual(magic.SYNERGY_THRESHOLDS['5+5'], 'grand-synthesis-art');

console.log('magic-defs contract: PASS');
