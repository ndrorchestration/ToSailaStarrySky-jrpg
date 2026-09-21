const assert = require('assert');
const defs = require('../modules/mastery-defs.js');

assert.strictEqual(defs.VERSION, '0.3.0');
assert.deepStrictEqual(
  defs.DOMAIN_FAMILY_IDS,
  ['elemental', 'arcane', 'psychic', 'spirit'],
  'major domain-family IDs changed'
);
assert.deepStrictEqual(
  defs.ENDER_SPECIAL_AFFINITY_IDS,
  ['aether', 'resonance', 'correspondence', 'lumen'],
  'Ender authored special affinities changed'
);

const enderAffinities = defs.getAuthoredAffinities('ender');
assert.strictEqual(enderAffinities.status, 'established');
assert.deepStrictEqual(
  enderAffinities.ids,
  ['aether', 'resonance', 'correspondence', 'lumen']
);

for (const id of ['lyra', 'ionia', 'reson', 'aepex']) {
  const affinity = defs.getAuthoredAffinities(id);
  assert.strictEqual(affinity.status, 'unknown',
    id + ' affinities must remain explicitly unknown');
  assert.deepStrictEqual(affinity.ids, []);

  const job = defs.getNativeJobStatus(id);
  assert.strictEqual(job.status, 'unknown',
    id + ' native job must remain explicitly unknown');
  assert.strictEqual(job.id, null);
  assert.strictEqual(job.label, null);

  const magic = defs.getMagicProfile(id);
  assert.strictEqual(magic.status, 'unknown',
    id + ' magic profile must remain explicitly unknown');
  assert.deepStrictEqual(magic.schoolIds, []);
  assert.deepStrictEqual(magic.foundationCandidateIds, []);
  assert.deepStrictEqual(magic.startingSpellIds, []);
}

const enderJob = defs.getNativeJobStatus('ender');
assert.deepStrictEqual(enderJob, {
  status: 'established',
  id: 'rift-scholar',
  label: 'Rift Scholar',
});

assert.deepStrictEqual(
  defs.SCHOOL_ORDER,
  ['aether', 'resonance', 'correspondence', 'lumen'],
  'Ender school order must track established innate affinities'
);

const expectedBranches = {
  aether: ['flow', 'ward', 'flux'],
  resonance: ['concord', 'dissonance', 'chorus'],
  correspondence: ['traverse', 'anchor', 'fold'],
  lumen: ['radiance', 'dawn', 'prism'],
};

for (const schoolId of defs.SCHOOL_ORDER) {
  const school = defs.getSchoolDefinition(schoolId);
  assert(school, 'school definition missing: ' + schoolId);
  assert.strictEqual(school.affinityStatus, 'established');
  assert.strictEqual(school.treeStatus, 'design_proposal');
  assert.deepStrictEqual(
    school.branches.map(branch => branch.id),
    expectedBranches[schoolId],
    schoolId + ' branch structure drifted'
  );
  assert.strictEqual(
    defs.listFoundationSpellsForSchool(schoolId).length,
    2,
    schoolId + ' should expose exactly two proposed foundation techniques'
  );
}

assert.deepStrictEqual(
  defs.FOUNDATION_SPELL_ORDER,
  [
    'aetherSense',
    'aetherPulse',
    'resonantPing',
    'attune',
    'spatialSense',
    'riftStep',
    'lumenSpark',
    'solarMend',
  ],
  'foundation spell scaffold drifted'
);

const enderMagic = defs.getMagicProfile('ender');
assert.strictEqual(enderMagic.status, 'established');
assert.deepStrictEqual(enderMagic.schoolIds, defs.SCHOOL_ORDER);
assert.deepStrictEqual(
  enderMagic.foundationCandidateIds,
  defs.FOUNDATION_SPELL_ORDER
);
assert.deepStrictEqual(
  enderMagic.startingSpellIds,
  ['aetherSense'],
  'Aether Sense must be Ender\'s only established starting magic technique'
);

for (const spellId of defs.FOUNDATION_SPELL_ORDER) {
  const spell = defs.getFoundationSpellDefinition(spellId);
  assert(spell, 'foundation spell missing: ' + spellId);
  assert.strictEqual(spell.tier, 1);
  assert.strictEqual(spell.branchId, null);
  assert.strictEqual(spell.resourceCost, null,
    spellId + ' must not invent a numeric resource cost');

  const readiness = defs.getSpellRuntimeReadiness('ender', spellId);
  if (spellId === 'aetherSense') {
    assert.strictEqual(spell.designStatus, 'established');
    assert.strictEqual(spell.runtimeStatus, 'integrated');
    assert.deepStrictEqual(spell.startingCharacterIds, ['ender']);
    assert.strictEqual(readiness.canUse, true);
    assert.strictEqual(readiness.reason, 'ok');
  } else {
    assert.strictEqual(spell.designStatus, 'design_proposal');
    assert.strictEqual(spell.runtimeStatus, 'not_integrated');
    assert.deepStrictEqual(spell.startingCharacterIds, []);
    assert.strictEqual(readiness.canUse, false,
      spellId + ' must fail closed before design/runtime authorization');
    assert.strictEqual(
      readiness.reason,
      'design_proposal_not_runtime_authorized'
    );
  }
}

assert.strictEqual(
  defs.getFoundationSpellDefinition('aetherPulse').resourceBinding,
  'aether'
);
assert.strictEqual(
  defs.getFoundationSpellDefinition('spatialSense').resourceBinding,
  'none'
);
assert.strictEqual(
  defs.getFoundationSpellDefinition('riftStep').resourceBinding,
  'arete_pending'
);
assert.strictEqual(
  defs.getFoundationSpellDefinition('aetherwake'),
  null,
  'Aetherwake four-affinity capstone must remain plot-gated and undefined'
);

assert.strictEqual(
  defs.getSpellRuntimeReadiness('lyra', 'resonantPing').reason,
  'character_magic_profile_unknown',
  'unresolved companion magic must fail closed'
);
assert.strictEqual(
  defs.getSpellRuntimeReadiness('ender', 'notASpell').reason,
  'unknown_spell'
);

assert.throws(
  () => defs.validateIdList('TEST', ['valid-id', 'valid-id']),
  /TEST_ID_DUPLICATE:valid-id/
);
assert.throws(
  () => defs.validateIdList('TEST', ['Not Valid']),
  /TEST_ID_INVALID:Not Valid/
);
assert.throws(
  () => defs.validateIdList('TEST', []),
  /TEST_MUST_BE_NONEMPTY_ARRAY/
);

assert.strictEqual(defs.validateSchoolDefinitions(), true);
assert.strictEqual(defs.validateFoundationSpells(), true);
assert.strictEqual(defs.validate(), true);

console.log('Aetherwake mastery + magic foundation contract: PASS');
console.log(JSON.stringify({
  version: defs.VERSION,
  schools: defs.SCHOOL_ORDER,
  foundationSpells: defs.FOUNDATION_SPELL_ORDER,
  establishedStartingSpell: 'aetherSense',
  runtimeBoundary: 'all other design proposals remain fail-closed',
}, null, 2));
