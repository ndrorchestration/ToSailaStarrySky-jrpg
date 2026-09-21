const assert = require('assert');

const contracts = require('../modules/companion-action-contracts.js');
const fieldRoles = require('../modules/field-role-defs.js');
const admission = require('../modules/companion-action-admission.js');
const effects = require('../modules/effect-vocabulary.js');

function assertTargetFormulaBlockers(readiness) {
  for (const blocker of [
    contracts.BLOCKER.FORMULA_CONTRACT_NOT_SPECIFIED,
    contracts.BLOCKER.TARGETING_NOT_SPECIFIED,
    contracts.BLOCKER.EFFECT_CONTRACT_NOT_ESTABLISHED,
    contracts.BLOCKER.COST_NOT_SPECIFIED,
    contracts.BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
    contracts.BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
  ]) {
    assert(readiness.blockers.includes(blocker),
      'target readiness missing blocker: ' + blocker);
  }
  assert(Array.isArray(readiness.legacyEvidenceBlockers),
    'legacy evidence blockers must remain separately visible');
}

assert.strictEqual(contracts.VERSION, '0.6.0');
assert.deepStrictEqual(Array.from(contracts.DRAFT_ORDER), ['windShearDance', 'aetherCompass', 'overdriveStrike', 'patchworkShield', 'spiritThread']);
assert.strictEqual(contracts.validateAgainstFieldRoles(fieldRoles), true);

const draft = contracts.getDraft('windShearDance');
assert(draft, 'Wind-Shear Dance draft must exist');
assert.strictEqual(draft.templateId, 'skySailor');
assert.strictEqual(draft.provenance, fieldRoles.PROVENANCE);
assert.strictEqual(draft.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(draft.stat, 'grace');
assert.strictEqual(
  draft.source.text,
  '2D6+Grace. Evade / reposition. 10+: next Grace roll +1.'
);

assert.deepStrictEqual(draft.roll, {
  system: '2d6',
  stat: 'grace',
  successMin: 10,
  partialMin: 7,
  source: 'established-global-combat-rule',
});

assert.deepStrictEqual(draft.cost, {
  status: contracts.UNKNOWN,
  resource: null,
  amount: null,
});

const reposition = draft.knownSemantics.find(item => item.id === 'reposition');
assert(reposition, 'reposition semantic must be preserved');
assert.strictEqual(reposition.band, contracts.UNKNOWN);
assert.strictEqual(reposition.effectKind, 'movement');
assert.strictEqual(reposition.target, 'self');

const nextGrace = draft.knownSemantics.find(item => item.id === 'nextGraceRoll');
assert(nextGrace, '10+ next-Grace-roll semantic must be preserved');
assert.strictEqual(nextGrace.band, 'success');
assert.strictEqual(nextGrace.effectKind, 'modifier');
assert.strictEqual(nextGrace.amount, 1);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    draft.outcomes[phase],
    null,
    'incomplete outcome tables must not be fabricated: ' + phase
  );
}

assert.strictEqual(draft.authoredBindings.nativeJob, contracts.UNKNOWN);
assert.strictEqual(draft.authoredBindings.school, contracts.UNKNOWN);
assert.strictEqual(contracts.getAdmissionCandidate('windShearDance'), null);

const readiness = contracts.getReadiness('windShearDance');
assert.strictEqual(readiness.known, true);
assert.strictEqual(readiness.designComplete, false);
assert.strictEqual(readiness.executionAuthorized, false);
assert.strictEqual(readiness.reason, 'formula_contract_not_established');
assertTargetFormulaBlockers(readiness);
assert(readiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.COST_NOT_SPECIFIED));
assert(readiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED));
assert(readiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED));
assert(readiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.MOVEMENT_EFFECT_NOT_EXECUTABLE));
assert(readiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.GRACE_MODIFIER_EFFECT_NOT_EXECUTABLE
));

const skySailor = fieldRoles.getById('skySailor');
const declaration = skySailor.abilities.find(action => action.id === 'windShearDance');
const assessment = admission.assessAction(
  declaration,
  skySailor,
  contracts.getAdmissionCandidate('windShearDance'),
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);

assert.strictEqual(assessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  assessment.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(assessment.contractComplete, false);
assert.strictEqual(assessment.executionAuthorized, false);

const compass = contracts.getDraft('aetherCompass');
assert(compass, 'Aether Compass draft must exist');
assert.strictEqual(compass.templateId, 'skySailor');
assert.strictEqual(compass.provenance, fieldRoles.PROVENANCE);
assert.strictEqual(compass.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(compass.stat, 'wits');
assert.strictEqual(
  compass.source.text,
  '2D6+Wits. Reveal resources — gain scrap or aether.'
);
assert.deepStrictEqual(compass.cost, {
  status: contracts.UNKNOWN,
  resource: null,
  amount: null,
});

const revealResources = compass.knownSemantics.find(item => item.id === 'revealResources');
assert(revealResources, 'resource-reveal semantic must be preserved');
assert.strictEqual(revealResources.band, contracts.UNKNOWN);
assert.strictEqual(revealResources.effectKind, 'reveal');
assert.strictEqual(revealResources.target, contracts.UNKNOWN);

const gainResource = compass.knownSemantics.find(item => item.id === 'gainResource');
assert(gainResource, 'Scrap/Aether gain semantic must be preserved');
assert.strictEqual(gainResource.band, contracts.UNKNOWN);
assert.strictEqual(gainResource.effectKind, 'resource');
assert.deepStrictEqual(gainResource.resourceAlternatives, ['scrap', 'aether']);
assert.strictEqual(gainResource.amount, null);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    compass.outcomes[phase],
    null,
    'Aether Compass outcome tables must not be fabricated: ' + phase
  );
}

assert.strictEqual(compass.authoredBindings.nativeJob, contracts.UNKNOWN);
assert.strictEqual(compass.authoredBindings.school, contracts.UNKNOWN);
assert.strictEqual(contracts.getAdmissionCandidate('aetherCompass'), null);

const compassReadiness = contracts.getReadiness('aetherCompass');
assert.strictEqual(compassReadiness.known, true);
assert.strictEqual(compassReadiness.designComplete, false);
assert.strictEqual(compassReadiness.executionAuthorized, false);
assert.strictEqual(compassReadiness.reason, 'formula_contract_not_established');
assertTargetFormulaBlockers(compassReadiness);
assert(compassReadiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.REVEAL_TARGET_NOT_SPECIFIED));
assert(compassReadiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.RESOURCE_GAIN_SELECTION_NOT_SPECIFIED));
assert(compassReadiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.RESOURCE_GAIN_AMOUNT_NOT_SPECIFIED));
assert(compassReadiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.REVEAL_EFFECT_NOT_EXECUTABLE));

const compassDeclaration = skySailor.abilities.find(action => action.id === 'aetherCompass');
const compassAssessment = admission.assessAction(
  compassDeclaration,
  skySailor,
  contracts.getAdmissionCandidate('aetherCompass'),
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);
assert.strictEqual(compassAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  compassAssessment.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(compassAssessment.contractComplete, false);
assert.strictEqual(compassAssessment.executionAuthorized, false);


const overdrive = contracts.getDraft('overdriveStrike');
assert(overdrive, 'Overdrive Strike draft must exist');
assert.strictEqual(overdrive.templateId, 'engineWright');
assert.strictEqual(overdrive.provenance, fieldRoles.PROVENANCE);
assert.strictEqual(overdrive.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(overdrive.stat, 'might');
assert.strictEqual(
  overdrive.source.text,
  '2D6+Might. Heavy EMP: 1d6+3 damage. Generates 1 Heat.'
);
assert.deepStrictEqual(overdrive.roll, {
  system: '2d6',
  stat: 'might',
  successMin: 10,
  partialMin: 7,
  source: 'established-global-combat-rule',
});
assert.deepStrictEqual(overdrive.cost, {
  status: contracts.UNKNOWN,
  resource: null,
  amount: null,
});

const heavyEmpDamage = overdrive.knownSemantics.find(
  item => item.id === 'heavyEmpDamage'
);
assert(heavyEmpDamage, 'Heavy EMP damage semantic must be preserved');
assert.strictEqual(heavyEmpDamage.band, contracts.UNKNOWN);
assert.strictEqual(heavyEmpDamage.effectKind, 'damage');
assert.strictEqual(heavyEmpDamage.target, 'enemy');
assert.strictEqual(heavyEmpDamage.key, 'emp');
assert.strictEqual(heavyEmpDamage.amount, null);
assert.strictEqual(heavyEmpDamage.amountFormula, '1d6+3');

const generatedHeat = overdrive.knownSemantics.find(
  item => item.id === 'generateHeat'
);
assert(generatedHeat, 'Heat-generation semantic must be preserved');
assert.strictEqual(generatedHeat.band, contracts.UNKNOWN);
assert.strictEqual(generatedHeat.effectKind, 'resource');
assert.strictEqual(generatedHeat.target, 'self');
assert.strictEqual(generatedHeat.key, 'heat');
assert.strictEqual(generatedHeat.amount, 1);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    overdrive.outcomes[phase],
    null,
    'Overdrive Strike outcome tables must not be fabricated: ' + phase
  );
}

assert.strictEqual(overdrive.authoredBindings.nativeJob, contracts.UNKNOWN);
assert.strictEqual(overdrive.authoredBindings.school, contracts.UNKNOWN);
assert.strictEqual(contracts.getAdmissionCandidate('overdriveStrike'), null);

const overdriveReadiness = contracts.getReadiness('overdriveStrike');
assert.strictEqual(overdriveReadiness.known, true);
assert.strictEqual(overdriveReadiness.designComplete, false);
assert.strictEqual(overdriveReadiness.executionAuthorized, false);
assert.strictEqual(overdriveReadiness.reason, 'formula_contract_not_established');
assertTargetFormulaBlockers(overdriveReadiness);
assert(overdriveReadiness.legacyEvidenceBlockers.includes(contracts.BLOCKER.COST_NOT_SPECIFIED));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.DAMAGE_BAND_NOT_SPECIFIED
));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.HEAT_GAIN_BAND_NOT_SPECIFIED
));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.DAMAGE_FORMULA_EXECUTION_NOT_ESTABLISHED
));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED
));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED
));
assert(overdriveReadiness.legacyEvidenceBlockers.includes(
  contracts.BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED
));

const engineWright = fieldRoles.getById('engineWright');
const overdriveDeclaration = engineWright.abilities.find(
  action => action.id === 'overdriveStrike'
);
const overdriveAssessment = admission.assessAction(
  overdriveDeclaration,
  engineWright,
  contracts.getAdmissionCandidate('overdriveStrike'),
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);
assert.strictEqual(overdriveAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  overdriveAssessment.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(overdriveAssessment.contractComplete, false);
assert.strictEqual(overdriveAssessment.executionAuthorized, false);


const patchwork = contracts.getDraft('patchworkShield');
assert(patchwork, 'Patchwork Shield draft must exist');
assert.strictEqual(patchwork.templateId, 'engineWright');
assert.strictEqual(patchwork.provenance, fieldRoles.PROVENANCE);
assert.strictEqual(patchwork.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(patchwork.stat, 'presence');
assert.strictEqual(
  patchwork.source.text,
  '2D6+Presence. Absorb 1 damage for an ally. Return 1 scrap.'
);
assert.deepStrictEqual(patchwork.roll, {
  system: '2d6',
  stat: 'presence',
  successMin: 10,
  partialMin: 7,
  source: 'established-global-combat-rule',
});
assert.deepStrictEqual(patchwork.cost, {
  status: contracts.UNKNOWN,
  resource: null,
  amount: null,
});

const absorption = patchwork.knownSemantics.find(
  item => item.id === 'allyDamageAbsorption'
);
assert(absorption, 'ally damage-absorption semantic must be preserved');
assert.strictEqual(absorption.band, contracts.UNKNOWN);
assert.strictEqual(absorption.effectKind, 'damage');
assert.strictEqual(absorption.target, 'ally');
assert.strictEqual(absorption.operation, 'absorb');
assert.strictEqual(absorption.amount, 1);
assert.strictEqual(absorption.timing, contracts.UNKNOWN);
assert.strictEqual(absorption.absorbedDamageDestination, contracts.UNKNOWN);

const scrapReturn = patchwork.knownSemantics.find(
  item => item.id === 'returnScrap'
);
assert(scrapReturn, 'scrap-return semantic must be preserved');
assert.strictEqual(scrapReturn.band, contracts.UNKNOWN);
assert.strictEqual(scrapReturn.effectKind, 'resource');
assert.strictEqual(scrapReturn.target, contracts.UNKNOWN);
assert.strictEqual(scrapReturn.operation, 'return');
assert.strictEqual(scrapReturn.key, 'scrap');
assert.strictEqual(scrapReturn.amount, 1);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    patchwork.outcomes[phase],
    null,
    'Patchwork Shield outcome tables must not be fabricated: ' + phase
  );
}

assert.strictEqual(patchwork.authoredBindings.nativeJob, contracts.UNKNOWN);
assert.strictEqual(patchwork.authoredBindings.school, contracts.UNKNOWN);
assert.strictEqual(contracts.getAdmissionCandidate('patchworkShield'), null);

const patchworkReadiness = contracts.getReadiness('patchworkShield');
assert.strictEqual(patchworkReadiness.known, true);
assert.strictEqual(patchworkReadiness.designComplete, false);
assert.strictEqual(patchworkReadiness.executionAuthorized, false);
assert.strictEqual(patchworkReadiness.reason, 'formula_contract_not_established');
assertTargetFormulaBlockers(patchworkReadiness);
for (const blocker of [
  contracts.BLOCKER.COST_NOT_SPECIFIED,
  contracts.BLOCKER.ALLY_DAMAGE_ABSORPTION_BAND_NOT_SPECIFIED,
  contracts.BLOCKER.ALLY_DAMAGE_ABSORPTION_TIMING_NOT_SPECIFIED,
  contracts.BLOCKER.ABSORBED_DAMAGE_DESTINATION_NOT_SPECIFIED,
  contracts.BLOCKER.SCRAP_RETURN_BAND_NOT_SPECIFIED,
  contracts.BLOCKER.SCRAP_RETURN_RECIPIENT_NOT_SPECIFIED,
  contracts.BLOCKER.ABSORPTION_EFFECT_NOT_EXECUTABLE,
  contracts.BLOCKER.SCRAP_RETURN_EFFECT_NOT_EXECUTABLE,
]) {
  assert(patchworkReadiness.legacyEvidenceBlockers.includes(blocker));
}

const patchworkDeclaration = engineWright.abilities.find(
  action => action.id === 'patchworkShield'
);
const patchworkAssessment = admission.assessAction(
  patchworkDeclaration,
  engineWright,
  contracts.getAdmissionCandidate('patchworkShield'),
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);
assert.strictEqual(patchworkAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  patchworkAssessment.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(patchworkAssessment.contractComplete, false);
assert.strictEqual(patchworkAssessment.executionAuthorized, false);


const spiritThread = contracts.getDraft('spiritThread');
assert(spiritThread, 'Spirit Thread draft must exist');
assert.strictEqual(spiritThread.templateId, 'aetherWeaver');
assert.strictEqual(spiritThread.provenance, fieldRoles.PROVENANCE);
assert.strictEqual(spiritThread.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(spiritThread.stat, 'spirit');
assert.strictEqual(
  spiritThread.source.text,
  '2D6+Spirit. Heal 1-3 Vit to a target ally.'
);
assert.deepStrictEqual(spiritThread.roll, {
  system: '2d6',
  stat: 'spirit',
  successMin: 10,
  partialMin: 7,
  source: 'established-global-combat-rule',
});
assert.deepStrictEqual(spiritThread.cost, {
  status: contracts.UNKNOWN,
  resource: null,
  amount: null,
});

const allyHeal = spiritThread.knownSemantics.find(
  item => item.id === 'healTargetAlly'
);
assert(allyHeal, 'target-ally heal semantic must be preserved');
assert.strictEqual(allyHeal.band, contracts.UNKNOWN);
assert.strictEqual(allyHeal.effectKind, 'restore');
assert.strictEqual(allyHeal.target, 'ally');
assert.strictEqual(allyHeal.operation, 'restore');
assert.strictEqual(allyHeal.key, 'vitality');
assert.strictEqual(allyHeal.amount, null);
assert.deepStrictEqual(allyHeal.amountRange, [1, 3]);
assert.strictEqual(allyHeal.amountSelection, contracts.UNKNOWN);
assert.strictEqual(allyHeal.targetSelection, contracts.UNKNOWN);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    spiritThread.outcomes[phase],
    null,
    'Spirit Thread outcome tables must not be fabricated: ' + phase
  );
}

assert.strictEqual(spiritThread.authoredBindings.nativeJob, contracts.UNKNOWN);
assert.strictEqual(spiritThread.authoredBindings.school, contracts.UNKNOWN);
assert.strictEqual(contracts.getAdmissionCandidate('spiritThread'), null);

const spiritThreadReadiness = contracts.getReadiness('spiritThread');
assert.strictEqual(spiritThreadReadiness.known, true);
assert.strictEqual(spiritThreadReadiness.designComplete, false);
assert.strictEqual(spiritThreadReadiness.executionAuthorized, false);
assert.strictEqual(spiritThreadReadiness.reason, 'formula_contract_not_established');
assertTargetFormulaBlockers(spiritThreadReadiness);
for (const blocker of [
  contracts.BLOCKER.COST_NOT_SPECIFIED,
  contracts.BLOCKER.HEAL_BAND_NOT_SPECIFIED,
  contracts.BLOCKER.HEAL_AMOUNT_SELECTION_NOT_SPECIFIED,
  contracts.BLOCKER.ALLY_TARGET_SELECTION_NOT_SPECIFIED,
  contracts.BLOCKER.ALLY_RESTORE_EFFECT_NOT_EXECUTABLE,
]) {
  assert(spiritThreadReadiness.legacyEvidenceBlockers.includes(blocker));
}

const aetherWeaver = fieldRoles.getById('aetherWeaver');
const spiritThreadDeclaration = aetherWeaver.abilities.find(
  action => action.id === 'spiritThread'
);
const spiritThreadAssessment = admission.assessAction(
  spiritThreadDeclaration,
  aetherWeaver,
  contracts.getAdmissionCandidate('spiritThread'),
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);
assert.strictEqual(spiritThreadAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  spiritThreadAssessment.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(spiritThreadAssessment.contractComplete, false);
assert.strictEqual(spiritThreadAssessment.executionAuthorized, false);

assert.strictEqual(
  contracts.getReadiness('notAnAction').reason,
  'unknown_companion_action_contract'
);

console.log('Aetherwake companion action contract drafts: PASS');
