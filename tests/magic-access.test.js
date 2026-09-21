const assert = require('assert');
const mastery = require('../modules/mastery-defs.js');
const magicAccess = require('../modules/magic-access.js');

assert.strictEqual(magicAccess.VERSION, '0.1.0');
assert.deepStrictEqual(
  magicAccess.CORE_DOMAIN_IDS,
  ['elemental', 'arcane', 'psychic', 'spirit']
);
assert.deepStrictEqual(
  magicAccess.ENDER_INNATE_IDS,
  ['aether', 'resonance', 'correspondence', 'lumen']
);
assert.deepStrictEqual(
  magicAccess.RECOGNIZED_SCHOOL_IDS,
  [
    'elemental',
    'arcane',
    'psychic',
    'spirit',
    'aether',
    'resonance',
    'correspondence',
    'lumen',
  ]
);

const ender = magicAccess.getCharacterAccessProfile('ender');
assert.deepStrictEqual(
  ender.innateSchoolIds,
  ['aether', 'resonance', 'correspondence', 'lumen'],
  'Ender innate schools must follow authored affinities'
);
assert.deepStrictEqual(
  ender.learnableSchoolIds,
  ['elemental', 'arcane', 'psychic', 'spirit'],
  'Ender broad learnability must include established non-native domains'
);
assert.deepStrictEqual(ender.unknownSchoolIds, []);

for (const schoolId of magicAccess.ENDER_INNATE_IDS) {
  const access = magicAccess.getSchoolAccess('ender', schoolId);
  assert.strictEqual(access.status, 'innate');
  assert.strictEqual(access.canStudySchool, true);
  assert.strictEqual(access.requiresDeliberateTraining, false);
}

for (const schoolId of magicAccess.CORE_DOMAIN_IDS) {
  const access = magicAccess.getSchoolAccess('ender', schoolId);
  assert.strictEqual(access.status, 'learnable');
  assert.strictEqual(access.canStudySchool, true);
  assert.strictEqual(access.requiresDeliberateTraining, true);
  assert.strictEqual(access.reason, 'ender_broad_learnability');
}

for (const characterId of ['lyra', 'ionia', 'reson', 'aepex']) {
  const profile = magicAccess.getCharacterAccessProfile(characterId);
  assert.deepStrictEqual(profile.innateSchoolIds, []);
  assert.deepStrictEqual(profile.learnableSchoolIds, []);
  assert.deepStrictEqual(
    profile.unknownSchoolIds,
    magicAccess.RECOGNIZED_SCHOOL_IDS,
    characterId + ' magic access must remain unresolved'
  );

  const access = magicAccess.getSchoolAccess(characterId, 'aether');
  assert.strictEqual(access.status, 'unknown');
  assert.strictEqual(access.canStudySchool, false);
  assert.strictEqual(access.reason, 'character_school_access_unresolved');
}

const unknownCharacter = magicAccess.getSchoolAccess('guest', 'arcane');
assert.strictEqual(unknownCharacter.status, 'unknown');
assert.strictEqual(unknownCharacter.reason, 'character_not_authored');

const unrecognized = magicAccess.getSchoolAccess('ender', 'dream');
assert.strictEqual(unrecognized.status, 'unrecognized');
assert.strictEqual(unrecognized.canStudySchool, false);
assert.strictEqual(unrecognized.reason, 'school_not_recognized');

assert.strictEqual(
  magicAccess.getSchoolMetadata('aether').resourceContext,
  'external_aether'
);
for (const schoolId of [
  'elemental',
  'arcane',
  'psychic',
  'spirit',
  'resonance',
  'correspondence',
  'lumen',
]) {
  assert.strictEqual(
    magicAccess.getSchoolMetadata(schoolId).resourceContext,
    'inner_resource_open',
    schoolId + ' must not receive invented Arete costs'
  );
}

for (const spellId of mastery.FOUNDATION_SPELL_ORDER) {
  const admission = magicAccess.getFoundationSpellStudyAdmission('ender', spellId);
  assert.strictEqual(admission.canStudy, false);
  assert.strictEqual(admission.canUse, false);
  assert.strictEqual(admission.reason, 'spell_design_not_established');
}

const companionSpell = magicAccess.getFoundationSpellStudyAdmission(
  'lyra',
  'aetherSense'
);
assert.strictEqual(companionSpell.canStudy, false);
assert.strictEqual(companionSpell.canUse, false);
assert.strictEqual(companionSpell.reason, 'school_access_unknown');

const unknownSpell = magicAccess.getFoundationSpellStudyAdmission(
  'ender',
  'notASpell'
);
assert.strictEqual(unknownSpell.canStudy, false);
assert.strictEqual(unknownSpell.canUse, false);
assert.strictEqual(unknownSpell.reason, 'unknown_spell');

assert.strictEqual(magicAccess.validate(), true);

console.log('Aetherwake magic school access contract: PASS');
console.log(JSON.stringify({
  version: magicAccess.VERSION,
  recognizedSchools: magicAccess.RECOGNIZED_SCHOOL_IDS,
  ender,
  boundary: 'school access does not authorize proposed spells',
}, null, 2));
