const assert = require('assert');
const seal = require('../modules/aether-seal-contract.js');

assert.strictEqual(seal.VERSION, '0.1.0');
assert.strictEqual(seal.OWNER, 'ender');
assert.strictEqual(seal.DOMAIN, 'aether');
assert.strictEqual(seal.BRANCH, 'ward');
assert.strictEqual(seal.STATUS, 'design-substrate-not-live');
assert.strictEqual(seal.validate(), true);

const dependent = seal.evaluateTarget({
  id:'aether_device',
  aetherDependent:true,
});
assert.strictEqual(dependent.applicable, true);
assert.strictEqual(dependent.reason, 'explicit-aether-dependence');
assert.strictEqual(dependent.effect.status, 'aether-suppressed');
assert.strictEqual(dependent.effect.durationTurns, 2);
assert.strictEqual(dependent.effect.incomingAetherDamageMultiplier, 1.15);
assert.strictEqual(dependent.effect.outgoingAetherEffectMultiplier, 0.80);

const tagged = seal.evaluateTarget({
  id:'wraith',
  tags:['aether-dependent'],
});
assert.strictEqual(tagged.applicable, true);

const explicitNo = seal.evaluateTarget({
  id:'mundane_machine',
  aetherDependent:false,
});
assert.strictEqual(explicitNo.applicable, false);
assert.strictEqual(explicitNo.reason, 'target-explicitly-not-aether-dependent');

const unknown = seal.evaluateTarget({id:'unknown_target'});
assert.strictEqual(unknown.applicable, false);
assert.strictEqual(unknown.reason, 'aether-dependence-unknown');
assert.strictEqual(unknown.effect, undefined);

assert.strictEqual(seal.hasExplicitAetherDependency(null), null);
assert.throws(() => seal.evaluateTarget(null), /AETHER_SEAL_TARGET_REQUIRED/);

console.log('Aetherwake Aether Seal design contract: PASS');
