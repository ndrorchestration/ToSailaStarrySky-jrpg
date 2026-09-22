const assert = require('assert');
const access = require('../modules/magic-spell-access.js');

assert.strictEqual(access.runtimeStatus, 'ACCESS_EVALUATION_ONLY');
assert.strictEqual(Object.keys(access.SPELL_INDEX).length, 260);

let profile = { trees:{}, domains:{} };

let result = access.evaluate(profile, 'fire.ember_dart');
assert.strictEqual(result.eligible, false);
assert.deepStrictEqual(result.reasons, ['insufficient_source_mastery']);

profile = { trees:{fire:1}, domains:{} };
result = access.evaluate(profile, 'fire.ember_dart');
assert.strictEqual(result.eligible, true);

result = access.evaluate(profile, 'fire.flame_arc');
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('insufficient_source_mastery'));

profile = { trees:{water:4, fire:1}, domains:{} };
result = access.evaluate(profile, 'water.steam_sheath');
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('missing_cross_mastery'));
assert.deepStrictEqual(result.missingRequirements, [{tree:'fire',rank:2}]);

profile = { trees:{water:4, fire:2}, domains:{} };
result = access.evaluate(profile, 'water.steam_sheath');
assert.strictEqual(result.eligible, true);

profile = { trees:{storm:5, lightning:4}, domains:{} };
result = access.evaluate(profile, 'storm.heavenbreak_tempest');
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('missing_cross_mastery'));

profile = { trees:{storm:5, lightning:5}, domains:{} };
result = access.evaluate(profile, 'storm.heavenbreak_tempest');
assert.strictEqual(result.eligible, true);

// Established domains are admitted by registry status, but still require mastery.
profile = { trees:{}, domains:{aether:1} };
result = access.evaluate(profile, 'aether.current_sense');
assert.strictEqual(result.eligible, true);
assert.strictEqual(result.sourceStatus, 'established');

profile = { trees:{}, domains:{arcane:1} };
result = access.evaluate(profile, 'arcane.force_bolt');
assert.strictEqual(result.eligible, true);
assert.strictEqual(result.sourceStatus, 'established-family');

// Proposed domains fail closed until explicitly admitted by a later canon/governance decision.
profile = { trees:{fire:5}, domains:{vital:5} };
result = access.evaluate(profile, 'vital.phoenix_garden');
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('domain_not_admitted'));

result = access.evaluate(profile, 'vital.phoenix_garden', {
  admittedDomainIds:['vital']
});
assert.strictEqual(result.eligible, true);

profile = { trees:{}, domains:{time:5, fate:5} };
result = access.evaluate(profile, 'time.moment_of_many_roads');
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('domain_not_admitted'));

result = access.evaluate(profile, 'time.moment_of_many_roads', {
  admittedDomainIds:['time','fate']
});
assert.strictEqual(result.eligible, true);

// Explicit admission never bypasses rank or cross-mastery requirements.
profile = { trees:{}, domains:{time:4, fate:5} };
result = access.evaluate(profile, 'time.moment_of_many_roads', {
  admittedDomainIds:['time','fate']
});
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('insufficient_source_mastery'));

profile = { trees:{}, domains:{time:5, fate:4} };
result = access.evaluate(profile, 'time.moment_of_many_roads', {
  admittedDomainIds:['time','fate']
});
assert.strictEqual(result.eligible, false);
assert.ok(result.reasons.includes('missing_cross_mastery'));

// Dreaming remains outside the ordinary catalog.
assert.strictEqual(access.getSpell('dreaming.shared_dream'), null);
assert.throws(
  () => access.evaluate({trees:{},domains:{}}, 'dreaming.shared_dream'),
  /MAGIC_SPELL_ACCESS_UNKNOWN_SPELL/
);

// Listing respects the same fail-closed rules.
profile = { trees:{fire:3}, domains:{} };
const accessibleFire = access.listAccessible(profile);
assert.ok(accessibleFire.some(s => s.id === 'fire.ember_dart'));
assert.ok(accessibleFire.some(s => s.id === 'fire.flashover'));
assert.ok(!accessibleFire.some(s => s.id === 'fire.furnace_field'));

assert.strictEqual(access.listBySource('fire').length, 10);
assert.strictEqual(access.listBySource('aether').length, 10);

console.log('magic-spell-access contract: PASS');
console.log(JSON.stringify({
  catalogSize:Object.keys(access.SPELL_INDEX).length,
  fireEntries:access.listBySource('fire').length,
  aetherEntries:access.listBySource('aether').length
}, null, 2));
