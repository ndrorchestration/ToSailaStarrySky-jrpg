const assert = require('assert');

const admission = require('../modules/companion-action-admission.js');
const fieldRoles = require('../modules/field-role-defs.js');
const effects = require('../modules/effect-vocabulary.js');
const combatPolicy = require('../modules/combat-system-policy.js');

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
    resolution: {
      model: combatPolicy.TARGET.model,
      formulaId: action.id,
      version: '0.1.0-test',
      kind: 'movement',
      parameters: {
        repositionDistance: 1,
      },
      rngUses: [],
    },
    targeting: {
      mode: 'self',
      maxTargets: 1,
      requiresExplicitTarget: false,
    },
    cost: {
      resource: null,
      amount: 0,
    },
    effects: [
      implementedEffect(
        effects.EFFECT_KIND.MOVEMENT,
        effects.TARGET.SELF,
        effects.OPERATION.MOVE,
        'reposition'
      ),
    ],
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
  combatPolicy,
});

assert.strictEqual(baseline.version, '0.2.0');
assert.strictEqual(baseline.targetModel, 'jrpg-stat-formula');
assert.strictEqual(baseline.actionCount, 6);
assert.strictEqual(baseline.completeCount, 0);
assert.strictEqual(baseline.executionAuthorizedCount, 0);
assert.strictEqual(baseline.allFailClosed, true);

for (const role of baseline.roles) {
  for (const action of role.actions) {
    assert.strictEqual(action.status, admission.STATUS.BLOCKED);
    assert.strictEqual(
      action.reason,
      admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
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
    combatPolicy,
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
    combatPolicy,
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

const legacyCandidate = clone(complete);
legacyCandidate.roll = {
  system: '2d6',
  stat: 'grace',
  successMin: 10,
  partialMin: 7,
};
legacyCandidate.outcomes = {
  common: [],
  success: [],
  partial: [],
  failure: [],
};
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, legacyCandidate, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_LEGACY_RESOLUTION_FORBIDDEN
);

const wrongModel = clone(complete);
wrongModel.resolution.model = '2d6-pbta-outcome-bands';
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, wrongModel, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_RESOLUTION_INVALID
);

const invalidRng = clone(complete);
invalidRng.resolution.rngUses = ['success-partial-failure'];
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, invalidRng, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_RESOLUTION_INVALID
);

const missingParameters = clone(complete);
missingParameters.resolution.parameters = {};
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingParameters, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_RESOLUTION_INVALID
);

const missingTargeting = clone(complete);
delete missingTargeting.targeting;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingTargeting, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_TARGETING_INVALID
);

const missingEffects = clone(complete);
missingEffects.effects = [];
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingEffects, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_EFFECTS_INVALID
);

const declaredOnly = clone(complete);
declaredOnly.effects[0].runtimeStatus =
  effects.RUNTIME_STATUS.DECLARED_NOT_APPLIED;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, declaredOnly, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_EFFECT_NOT_IMPLEMENTED
);

const wrongTemplate = clone(complete);
wrongTemplate.templateId = 'engineWright';
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, wrongTemplate, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_TEMPLATE_MISMATCH
);

const wrongProvenance = clone(complete);
wrongProvenance.provenance = 'invented-canon';
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, wrongProvenance, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_PROVENANCE_MISMATCH
);

const missingBinding = clone(complete);
delete missingBinding.execution.adapterId;
assert.strictEqual(
  admission.assessAction(windShearDance, skySailor, missingBinding, {
    provenance: fieldRoles.PROVENANCE,
    effectVocabulary: effects,
    combatPolicy,
  }).reason,
  admission.REASON.CONTRACT_EXECUTION_BINDING_INVALID
);

console.log('Aetherwake formula-native companion action admission contract: PASS');
