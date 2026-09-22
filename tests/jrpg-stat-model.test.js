const assert = require('assert');
const model = require('../modules/jrpg-stat-model.js');

assert.strictEqual(model.VERSION, '0.1.0');
assert.strictEqual(model.LEVEL_CAP, 175);
assert.strictEqual(model.PRIMARY_HARD_CAP, 75);
assert.strictEqual(model.validate(), true);

const ids = ['ender','lyra','ionia','reson','aepex'];
assert.deepStrictEqual(Object.keys(model.PROFILES), ids);

for (const id of ids) {
  const profile = model.PROFILES[id];
  const budget = model.PRIMARY_STATS.reduce((n, key) => n + profile.level1[key], 0);
  assert(budget >= model.LEVEL_ONE_BASELINE_BUDGET,
    id + ' level-1 budget fell below the baseline');
  assert.deepStrictEqual(model.getPrimaryStats(id, 1), profile.level1,
    id + ' level-1 interpolation drift');
  assert.deepStrictEqual(model.getPrimaryStats(id, 175), profile.capstone,
    id + ' capstone interpolation drift');

  let previous = model.getPrimaryStats(id, 1);
  for (let level = 2; level <= 175; level++) {
    const current = model.getPrimaryStats(id, level);
    for (const stat of model.PRIMARY_STATS) {
      assert(current[stat] >= previous[stat], id + ' ' + stat + ' regressed at level ' + level);
      assert(current[stat] >= 1 && current[stat] <= 75,
        id + ' ' + stat + ' escaped hard bounds at level ' + level);
    }
    previous = current;
  }
}

// Signature identity at level 1.
assert.strictEqual(model.getPrimaryStats('ender', 1).wits, 8);
assert.strictEqual(model.getPrimaryStats('ender', 1).spirit, 12);
assert.strictEqual(model.getPrimaryStats('lyra', 1).spirit, 9);
assert.strictEqual(model.getPrimaryStats('ionia', 1).presence, 9);
assert.strictEqual(model.getPrimaryStats('reson', 1).might, 9);
assert.strictEqual(model.getPrimaryStats('aepex', 1).wits, 9);

// Representative growth snapshots stay readable rather than exploding.
for (const level of [1, 30, 70, 130, 150, 175]) {
  for (const id of ids) {
    const stats = model.getPrimaryStats(id, level);
    for (const stat of model.PRIMARY_STATS) {
      assert(Number.isInteger(stats[stat]));
      assert(stats[stat] <= 75);
    }
  }
}

// Derived-stat role checks.
const ender = model.derive(model.getPrimaryStats('ender', 70), 70);
const lyra = model.derive(model.getPrimaryStats('lyra', 70), 70);
const ionia = model.derive(model.getPrimaryStats('ionia', 70), 70);
const reson = model.derive(model.getPrimaryStats('reson', 70), 70);
const aepex = model.derive(model.getPrimaryStats('aepex', 70), 70);

assert(ender.technicalPower > reson.technicalPower, 'Ender should outperform Reson technically');
assert(lyra.aetherAttack > reson.aetherAttack, 'Lyra should outperform Reson aetherically');
assert(ionia.supportPotency > ender.supportPotency, 'Ionia should lead support potency');
assert(reson.physicalAttack > ender.physicalAttack, 'Reson should lead physical attack');
assert(aepex.technicalPower >= ender.technicalPower, 'Aepex should be top-tier technically');

// Defense is diminishing rather than subtractive/cliff-forming.
const d0 = model.defenseMultiplier(0);
const d50 = model.defenseMultiplier(50);
const d100 = model.defenseMultiplier(100);
assert.strictEqual(d0, 1);
assert(d50 > d100 && d100 > 0);
assert(d50 < 1);

// Bounded variance.
assert.strictEqual(model.varianceMultiplier(0), 0.95);
assert(model.varianceMultiplier(0.999999) < 1.051);

// Deterministic damage with injected RNG.
const normal = model.resolveDamage({
  attacker: { might: 30 },
  scalingStat: 'might',
  power: 40,
  scaling: 1.4,
  equipmentPower: 20,
  defense: 50,
  canCrit: true,
  critRate: 0.1,
  critRng: 0.9,
  varianceRng: 0.5,
});
const crit = model.resolveDamage({
  attacker: { might: 30 },
  scalingStat: 'might',
  power: 40,
  scaling: 1.4,
  equipmentPower: 20,
  defense: 50,
  canCrit: true,
  critRate: 0.1,
  critRng: 0.05,
  varianceRng: 0.5,
});
assert.strictEqual(normal.critical, false);
assert.strictEqual(crit.critical, true);
assert(crit.damage > normal.damage);
assert(normal.damage >= 1);

// Accuracy remains bounded and never creates routine 5%/95% tabletop-style extremes.
assert.strictEqual(model.resolveHitChance({baseAccuracy:0.95,attackerAccuracy:100,defenderEvasion:0}), 0.995);
assert.strictEqual(model.resolveHitChance({baseAccuracy:0.8,attackerAccuracy:0,defenderEvasion:100}), 0.6);

// Status and Break are bounded/fail-safe.
assert(model.resolveStatusChance({baseChance:0.5,potency:60,resolve:20}) <= 0.95);
assert.strictEqual(model.resolveBreakDamage({breakPower:20,breakResistance:100,power:1}), 0);

// Healing is deterministic and stat-scaled.
assert.strictEqual(model.resolveHealing({
  actor:{presence:20}, scalingStat:'presence', power:30, scaling:1.5, supportBonus:10
}), 70);

console.log('Aetherwake JRPG stat model v0.1: PASS');
