const assert = require('assert');

const contracts = require('../modules/companion-action-contracts.js');
const fieldRoles = require('../modules/field-role-defs.js');
const admission = require('../modules/companion-action-admission.js');
const effects = require('../modules/effect-vocabulary.js');

assert.strictEqual(contracts.VERSION, '0.2.0');
assert.deepStrictEqual(Array.from(contracts.DRAFT_ORDER), ['windShearDance', 'aetherCompass']);
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
assert.strictEqual(readiness.reason, 'outcome_contract_not_established');
assert(readiness.blockers.includes(contracts.BLOCKER.COST_NOT_SPECIFIED));
assert(readiness.blockers.includes(contracts.BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED));
assert(readiness.blockers.includes(contracts.BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED));
assert(readiness.blockers.includes(contracts.BLOCKER.MOVEMENT_EFFECT_NOT_EXECUTABLE));
assert(readiness.blockers.includes(
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
  admission.REASON.OUTCOME_CONTRACT_NOT_ESTABLISHED
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
assert.strictEqual(compassReadiness.reason, 'outcome_contract_not_established');
assert(compassReadiness.blockers.includes(contracts.BLOCKER.REVEAL_TARGET_NOT_SPECIFIED));
assert(compassReadiness.blockers.includes(contracts.BLOCKER.RESOURCE_GAIN_SELECTION_NOT_SPECIFIED));
assert(compassReadiness.blockers.includes(contracts.BLOCKER.RESOURCE_GAIN_AMOUNT_NOT_SPECIFIED));
assert(compassReadiness.blockers.includes(contracts.BLOCKER.REVEAL_EFFECT_NOT_EXECUTABLE));

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
  admission.REASON.OUTCOME_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(compassAssessment.contractComplete, false);
assert.strictEqual(compassAssessment.executionAuthorized, false);

assert.strictEqual(
  contracts.getReadiness('notAnAction').reason,
  'unknown_companion_action_contract'
);

console.log('Aetherwake companion action contract drafts: PASS');
