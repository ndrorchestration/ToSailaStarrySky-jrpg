const assert = require('assert');

const admission = require('../modules/companion-action-admission.js');
const fieldRoles = require('../modules/field-role-defs.js');
const effects = require('../modules/effect-vocabulary.js');

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function implementedEffect(kind, target, operation, key) {
  return {
    kind,
    target,
    operation,
    key: key || null,
    runtimeStatus: effects.RUNTIME_STATUS.IMPLEMENTED,
    note: null,
  };
}

function completeSyntheticContract(role, action) {
  return {
    actionId: action.id,
    templateId: role.id,
    provenance: fieldRoles.PROVENANCE,
    stat: action.stat,
    roll: {
      system: '2d6',
      stat: action.stat,
      successMin: 10,
      partialMin: 7,
    },
    cost: {
      resource: null,
      amount: 0,
    },
    outcomes: {
      common: [],
      success: [
        implementedEffect(
          effects.EFFECT_KIND.MOVEMENT,
          effects.TARGET.SELF,
          effects.OPERATION.MOVE,
          'reposition'
        ),
      ],
      partial: [],
      failure: [],
    },
    execution: {
      adapterId: 'synthetic-contract-test-only',
      version: '0.0.0-test',
    },
    persistence: {
      mode: 'combat-local',
      fields: ['position'],
    },
  };
}

const baseline = admission.assessRegistry(fieldRoles, {}, {
  effectVocabulary: effects,
});

assert.strictEqual(baseline.version, '0.1.0');
assert.strictEqual(baseline.actionCount, 6);
assert.strictEqual(baseline.completeCount, 0);
assert.strictEqual(baseline.executionAuthorizedCount, 0);
assert.strictEqual(baseline.allFailClosed, true);

for (const role of baseline.roles) {
  for (const action of role.actions) {
    assert.strictEqual(action.status, admission.STATUS.BLOCKED);
    assert.strictEqual(
      action.reason,
      admission.REASON.OUTCOME_CONTRACT_NOT_ESTABLISHED
    );
    assert.strictEqual(action.executionAuthorized, false);
  }
}

const skySailor = fieldRoles.getById('skySailor');
const windShearDance = skySailor.abilities.find(action => action.id === 'windShearDance');
const complete = completeSyntheticContract(skySailor, windShearDance);
const before = clone(complete);

assert.strictEqual(
  admission.validateCompleteContract(windShearDance, skySailor, complete, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }),
  true
);
assert.deepStrictEqual(complete, before, 'validation must not mutate candidate contracts');

const completeAssessment = admission.assessAction(
  windShearDance,
  skySailor,
  complete,
  {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }
);
assert.strictEqual(
  completeAssessment.status,
  admission.STATUS.COMPLETE_NOT_AUTHORIZED
);
assert.strictEqual(completeAssessment.contractComplete, true);
assert.strictEqual(completeAssessment.executionAuthorized, false);
assert.strictEqual(
  completeAssessment.reason,
  admission.REASON.EXECUTION_AUTHORIZATION_NOT_ESTABLISHED
);

const missingPhase = clone(complete);
delete missingPhase.outcomes.failure;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingPhase, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }).reason,
  admission.REASON.CONTRACT_OUTCOMES_INVALID
);

const declaredOnly = clone(complete);
declaredOnly.outcomes.success[0].runtimeStatus =
  effects.RUNTIME_STATUS.DECLARED_NOT_APPLIED;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, declaredOnly, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }).reason,
  admission.REASON.CONTRACT_EFFECT_NOT_IMPLEMENTED
);

const wrongTemplate = clone(complete);
wrongTemplate.templateId = 'engineWright';
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, wrongTemplate, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }).reason,
  admission.REASON.CONTRACT_TEMPLATE_MISMATCH
);

const wrongProvenance = clone(complete);
wrongProvenance.provenance = 'invented-canon';
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, wrongProvenance, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }).reason,
  admission.REASON.CONTRACT_PROVENANCE_MISMATCH
);

const missingBinding = clone(complete);
delete missingBinding.execution.adapterId;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingBinding, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
  }).reason,
  admission.REASON.CONTRACT_EXECUTION_BINDING_INVALID
);

console.log('Aetherwake companion action admission contract: PASS');
