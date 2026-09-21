const assert = require('node:assert/strict');
const policy = require('../modules/combat-system-policy.js');
const formula = require('../modules/combat-formula.js');
const abilities = require('../modules/ability-defs.js');

assert.equal(formula.VERSION, '0.1.0');
assert.equal(policy.TARGET.model, 'jrpg-stat-formula');
assert.equal(formula.validateAgainstAbilityDefs(abilities), true);

const staff = formula.getFormula('staffStrike');
assert(staff);
assert.equal(staff.model, 'jrpg-stat-formula');
assert.equal(staff.damageType, 'emp');
assert.equal(staff.power, 5);
assert.deepEqual(staff.scaling, { stat: 'might', coefficient: 1 });
assert.deepEqual(staff.defenseInteraction, {
  stat: 'empDefense',
  coefficient: 1,
  fallback: 0,
});
assert.deepEqual(staff.accuracyPolicy, { mode: 'guaranteed' });
assert.deepEqual(staff.criticalPolicy, {
  mode: 'chance',
  chance: 0.10,
  multiplier: 1.5,
});
assert.deepEqual(staff.variancePolicy, {
  mode: 'bounded',
  min: 0.95,
  max: 1.05,
});
assert.deepEqual(staff.dedicatedCost, {
  resource: 'staffCharges',
  amount: 1,
});

function sequence(values) {
  let index = 0;
  return () => {
    if (index >= values.length) throw new Error('RANDOM_SEQUENCE_EXHAUSTED');
    return values[index++];
  };
}

const normal = formula.resolveDamage(
  'staffStrike',
  { might: -1 },
  {},
  sequence([0.5, 0.99])
);
assert.equal(normal.hit, true);
assert.equal(normal.critical, false);
assert.equal(normal.scaledPower, 4);
assert.equal(normal.defenseValue, 0);
assert.equal(normal.damage, 4);
assert.equal(normal.model, 'jrpg-stat-formula');

const critical = formula.resolveDamage(
  'staffStrike',
  { might: -1 },
  {},
  sequence([0.5, 0.01])
);
assert.equal(critical.hit, true);
assert.equal(critical.critical, true);
assert.equal(critical.damage, 6);

const defended = formula.resolveDamage(
  'staffStrike',
  { might: 2 },
  { empDefense: 2 },
  sequence([0.5, 0.99])
);
assert.equal(defended.scaledPower, 7);
assert.equal(defended.mitigation, 2);
assert.equal(defended.damage, 5);

assert.throws(
  () => formula.resolveDamage(
    'staffStrike',
    { might: 0 },
    {},
    () => 1
  ),
  /COMBAT_FORMULA_RANDOM_OUT_OF_RANGE/
);
assert.throws(
  () => formula.resolveDamage('unknown', {}, {}, () => 0.5),
  /COMBAT_FORMULA_UNKNOWN_ACTION/
);

console.log('Aetherwake JRPG combat formula resolver: PASS');
