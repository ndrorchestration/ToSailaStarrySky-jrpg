const assert = require('assert');

const contracts = require('../modules/companion-action-contracts.js');
const fieldRoles = require('../modules/field-role-defs.js');
const admission = require('../modules/companion-action-admission.js');
const effects = require('../modules/effect-vocabulary.js');

assert.strictEqual(contracts.VERSION, '0.1.0');
assert.deepStrictEqual(Array.from(contracts.DRAFT_ORDER), ['windShearDance']);
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

assert.strictEqual(
  contracts.getReadiness('notAnAction').reason,
  'unknown_companion_action_contract'
);

console.log('Aetherwake Wind-Shear Dance contract draft: PASS');
