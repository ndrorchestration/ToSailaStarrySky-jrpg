const assert = require('assert');
const policy = require('../modules/combat-system-policy.js');
const statModel = require('../modules/jrpg-stat-model.js');
const formula = require('../modules/combat-formula.js');
const abilities = require('../modules/ability-defs.js');

assert.strictEqual(policy.TARGET.model, 'jrpg-stat-formula');
assert.strictEqual(formula.VERSION, '1.1.0');
assert.strictEqual(formula.validateAgainstAbilityDefs(abilities), true);

const actor = {
  productionStats: { might:3, grace:4, wits:8, spirit:12, presence:4 },
  productionDerivedStats: statModel.derive(
    { might:3, grace:4, wits:8, spirit:12, presence:4 }, 1
  ),
  staffCharges:2,
  maxStaffCharges:2,
  heat:{current:2,max:3},
  vit:10,
  maxVit:13,
};

const target = {
  productionDerivedStats: {
    aetherDefense:20,
    evasion:10,
  },
};

function sequence(values) {
  let i = 0;
  return () => {
    if (i >= values.length) throw new Error('RNG_EXHAUSTED');
    return values[i++];
  };
}

const normal = formula.resolveAction(
  'staffStrike', actor, target, sequence([0.5, 0.99])
);
assert.strictEqual(normal.hit, true);
assert.strictEqual(normal.critical, false);
assert.strictEqual(normal.scalingValue, 3);
assert.strictEqual(normal.defenseStat, 'aetherDefense');
assert(normal.defenseMultiplier > 0 && normal.defenseMultiplier < 1);
assert(normal.damage >= 1);

const critical = formula.resolveAction(
  'staffStrike', actor, target, sequence([0.5, 0.01])
);
assert.strictEqual(critical.critical, true);
assert(critical.damage > normal.damage);

const analysis = formula.resolveAction(
  'uncoverTruth',
  actor,
  { weakness:'EMP fractures the exposed harmonic seam.' },
  () => { throw new Error('ANALYSIS_RNG_FORBIDDEN'); }
);
assert.strictEqual(analysis.kind, 'analysis');
assert.strictEqual(analysis.weakness, 'EMP fractures the exposed harmonic seam.');
assert.strictEqual(analysis.modifier.nextDamageMultiplier, 1.15);
assert.strictEqual(analysis.modifier.charges, 1);

const analyzedTarget = {
  productionDerivedStats: { aetherDefense:20, evasion:10 },
  analysis: { nextDamageMultiplier:1.15, charges:1 },
};
const analyzedDamage = formula.resolveAction(
  'staffStrike', actor, analyzedTarget, sequence([0.5,0.99])
);
assert.strictEqual(analyzedDamage.consumedAnalysis, true);
assert.strictEqual(analyzedDamage.analysisMultiplier, 1.15);
assert(analyzedDamage.damage > normal.damage);

const hold = formula.resolveAction('hold', {
  staffCharges:1,maxStaffCharges:2
}, null, () => { throw new Error('HOLD_RNG_FORBIDDEN'); });
assert.strictEqual(hold.delta, 1);

const rest = formula.resolveAction('rest', actor, null,
  () => { throw new Error('REST_RNG_FORBIDDEN'); });
assert.strictEqual(rest.heatReduction, 2);
assert.strictEqual(rest.vitalityRestore, 1);

assert.throws(
  () => formula.resolveAction('staffStrike', actor, target, () => 1),
  /COMBAT_FORMULA_RANDOM_OUT_OF_RANGE/
);

assert.strictEqual(abilities.DEFS.staffStrike.resolution.model, 'jrpg-stat-formula');
assert.strictEqual(abilities.DEFS.uncoverTruth.resolution.formulaId, 'uncoverTruth');
assert.strictEqual(abilities.DEFS.hold.resolution.formulaId, 'hold');
assert.strictEqual(abilities.DEFS.rest.resolution.formulaId, 'rest');

console.log('Aetherwake production JRPG formula engine: PASS');
