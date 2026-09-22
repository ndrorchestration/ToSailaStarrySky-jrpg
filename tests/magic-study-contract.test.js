const assert = require('assert');
const profileApi = require('../modules/character-magic-profile.js');
const study = require('../modules/magic-study.js');

assert.strictEqual(study.runtimeStatus, 'EXPLICIT_STUDY_TRANSACTION_ONLY');

let profile = profileApi.createProfile('ender');

// Affinity alone still grants no mastery or spell access.
assert.strictEqual(profileApi.rankFor(profile, 'aether'), 0);
assert.strictEqual(profileApi.knowsSpell(profile, 'aether.current_sense'), false);
assert.strictEqual(
  study.evaluateSpellStudy(profile, 'aether.current_sense').eligible,
  false
);

// Mastery advances exactly one rank per explicit transaction.
let check = study.evaluateMasteryAdvance(profile, 'fire', 1);
assert.strictEqual(check.eligible, true);
profile = study.advanceMastery(profile, 'fire', 1);
assert.strictEqual(profileApi.rankFor(profile, 'fire'), 1);

check = study.evaluateMasteryAdvance(profile, 'fire', 3);
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('rank_must_advance_exactly_one'));
assert.throws(
  () => study.advanceMastery(profile, 'fire', 3),
  /MAGIC_STUDY_MASTERY_NOT_ELIGIBLE/
);

profile = study.advanceMastery(profile, 'fire', 2);
assert.strictEqual(profileApi.rankFor(profile, 'fire'), 2);

// Advanced elemental trees require their registry prerequisites.
check = study.evaluateMasteryAdvance(profile, 'frost', 1);
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('tree_prerequisites_not_met'));

profile = study.advanceMastery(profile, 'water', 1);
profile = study.advanceMastery(profile, 'water', 2);
check = study.evaluateMasteryAdvance(profile, 'frost', 1);
assert.strictEqual(check.eligible, true);
profile = study.advanceMastery(profile, 'frost', 1);
assert.strictEqual(profileApi.rankFor(profile, 'frost'), 1);

// Established non-elemental domains can be studied but are still sequential.
profile = study.advanceMastery(profile, 'aether', 1);
assert.strictEqual(profileApi.rankFor(profile, 'aether'), 1);

// Proposed domains remain closed without explicit admission.
check = study.evaluateMasteryAdvance(profile, 'vital', 1);
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('domain_not_admitted'));

check = study.evaluateMasteryAdvance(profile, 'vital', 1, {
  admittedDomainIds:['vital']
});
assert.strictEqual(check.eligible, true);
profile = study.advanceMastery(profile, 'vital', 1, {
  admittedDomainIds:['vital']
});
assert.strictEqual(profileApi.rankFor(profile, 'vital'), 1);

// Spell study requires source mastery and cross-prerequisites.
check = study.evaluateSpellStudy(profile, 'fire.ember_dart');
assert.strictEqual(check.eligible, true);
profile = study.learnSpell(profile, 'fire.ember_dart');
assert.strictEqual(profileApi.knowsSpell(profile, 'fire.ember_dart'), true);

check = study.evaluateSpellStudy(profile, 'fire.ember_dart');
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('already_learned'));

check = study.evaluateSpellStudy(profile, 'fire.flashover');
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('insufficient_source_mastery'));

// Affinity + mastery allows study; affinity alone did not.
check = study.evaluateSpellStudy(profile, 'aether.current_sense');
assert.strictEqual(check.eligible, true);
profile = study.learnSpell(profile, 'aether.current_sense');
assert.strictEqual(profileApi.knowsSpell(profile, 'aether.current_sense'), true);

// Proposed-domain learning still requires admission even after mastery exists.
check = study.evaluateSpellStudy(profile, 'vital.life_sense');
assert.strictEqual(check.eligible, false);
assert.ok(check.reasons.includes('domain_not_admitted'));

check = study.evaluateSpellStudy(profile, 'vital.life_sense', {
  admittedDomainIds:['vital']
});
assert.strictEqual(check.eligible, true);
profile = study.learnSpell(profile, 'vital.life_sense', {
  admittedDomainIds:['vital']
});
assert.strictEqual(profileApi.knowsSpell(profile, 'vital.life_sense'), true);

// Studyable listing excludes already learned spells.
const studyable = study.listStudyableSpells(profile, {
  admittedDomainIds:['vital']
});
assert.ok(!studyable.some(spell => spell.id === 'fire.ember_dart'));
assert.ok(!studyable.some(spell => spell.id === 'aether.current_sense'));
assert.ok(!studyable.some(spell => spell.id === 'vital.life_sense'));
assert.ok(studyable.some(spell => spell.id === 'fire.flame_arc'));

// No transaction invents XP, costs, teachers, or automatic progression.
assert.strictEqual(Object.prototype.hasOwnProperty.call(profile, 'masteryXp'), false);
assert.strictEqual(Object.prototype.hasOwnProperty.call(profile, 'studyCurrency'), false);

console.log('magic-study contract: PASS');
console.log(JSON.stringify({
  schemaVersion:profile.schemaVersion,
  learnedSpells:profile.learnedSpells,
  fireRank:profileApi.rankFor(profile, 'fire'),
  waterRank:profileApi.rankFor(profile, 'water'),
  frostRank:profileApi.rankFor(profile, 'frost'),
  aetherRank:profileApi.rankFor(profile, 'aether'),
  vitalRank:profileApi.rankFor(profile, 'vital')
}, null, 2));
