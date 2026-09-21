const assert = require('assert');

const mastery = require('../modules/mastery-defs.js');
const magicAccess = require('../modules/magic-access.js');
const effects = require('../modules/effect-vocabulary.js');
const admission = require('../modules/foundation-spell-admission.js');
const contracts = require('../modules/foundation-spell-contracts.js');
const pulseEval = require('../modules/aether-pulse-synthetic-evaluation.js');

assert.strictEqual(admission.VERSION, '0.1.0');
assert.strictEqual(contracts.VERSION, '0.1.0');
assert.deepStrictEqual(
  Array.from(contracts.DRAFT_ORDER),
  ['aetherSense', 'aetherPulse']
);
assert.strictEqual(contracts.validateAgainstMastery(mastery), true);

const senseRecord = contracts.getContract('aetherSense');
assert(senseRecord, 'Aether Sense contract evidence must exist');
assert.strictEqual(
  senseRecord.status,
  contracts.STATUS.ESTABLISHED_RUNTIME
);
assert.strictEqual(senseRecord.cost.amount, 0);
assert.strictEqual(senseRecord.cost.resource, null);
assert.strictEqual(senseRecord.mutationPolicy, 'read-only');
assert.deepStrictEqual(senseRecord.startingCharacterIds, ['ender']);
assert.deepStrictEqual(senseRecord.blockers, []);

const senseCandidate = contracts.getAdmissionCandidate('aetherSense');
assert(senseCandidate, 'Aether Sense admission contract must be exposed');
const senseAssessment = admission.assessSpell(
  'ender',
  'aetherSense',
  senseCandidate
);
assert.strictEqual(
  senseAssessment.status,
  admission.STATUS.RUNTIME_READY
);
assert.strictEqual(senseAssessment.contractComplete, true);
assert.strictEqual(senseAssessment.executionAuthorized, true);
assert.strictEqual(senseAssessment.reason, 'ok');

const lyraSense = admission.assessSpell(
  'lyra',
  'aetherSense',
  senseCandidate
);
assert.strictEqual(lyraSense.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  lyraSense.reason,
  admission.REASON.SCHOOL_ACCESS_UNAVAILABLE
);
assert.strictEqual(lyraSense.executionAuthorized, false);

const pulse = contracts.getContract('aetherPulse');
assert(pulse, 'Aether Pulse draft must exist');
assert.strictEqual(pulse.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(pulse.schoolId, 'aether');
assert.strictEqual(pulse.resourceBinding, 'aether');
assert.strictEqual(pulse.mode, 'combat-2d6');
assert.strictEqual(pulse.cost.resource, 'aether');
assert.strictEqual(pulse.cost.amount, null);
assert.strictEqual(pulse.cost.status, contracts.UNKNOWN);
assert.strictEqual(pulse.roll.system, '2d6');
assert.strictEqual(pulse.roll.stat, contracts.UNKNOWN);
assert.strictEqual(pulse.roll.successMin, 10);
assert.strictEqual(pulse.roll.partialMin, 7);
assert.deepStrictEqual(pulse.requiredEffectKinds, ['damage']);
assert.deepStrictEqual(pulse.startingCharacterIds, []);
assert.strictEqual(contracts.getAdmissionCandidate('aetherPulse'), null);

for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    pulse.outcomes[phase],
    null,
    'Aether Pulse outcome must remain unresolved: ' + phase
  );
}

const pulseReadiness = contracts.getReadiness('aetherPulse');
assert.strictEqual(pulseReadiness.known, true);
assert.strictEqual(pulseReadiness.designComplete, false);
assert.strictEqual(pulseReadiness.runtimeEstablished, false);
assert.strictEqual(
  pulseReadiness.reason,
  'spell_contract_not_established'
);
for (const blocker of [
  contracts.BLOCKER.DESIGN_NOT_ESTABLISHED,
  contracts.BLOCKER.STARTING_OWNERSHIP_NOT_ESTABLISHED,
  contracts.BLOCKER.COST_NOT_SPECIFIED,
  contracts.BLOCKER.ROLL_STAT_NOT_SPECIFIED,
  contracts.BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
  contracts.BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
]) {
  assert(
    pulseReadiness.blockers.includes(blocker),
    'missing Aether Pulse blocker: ' + blocker
  );
}

const missingPulseContract = admission.assessSpell(
  'ender',
  'aetherPulse',
  contracts.getAdmissionCandidate('aetherPulse')
);
assert.strictEqual(missingPulseContract.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  missingPulseContract.reason,
  admission.REASON.CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(missingPulseContract.executionAuthorized, false);

function implemented(kind, target, operation, key) {
  return {
    kind,
    target,
    operation,
    key,
    runtimeStatus: effects.RUNTIME_STATUS.IMPLEMENTED,
    note: 'synthetic admission fixture only',
  };
}

// Synthetic completeness fixture: these numbers/stat choices are deliberately
// test-only. Passing structural validation must not promote Aether Pulse while
// its code-owned design/runtime status remains a proposal.
const syntheticPulseContract = {
  spellId: 'aetherPulse',
  schoolId: 'aether',
  mode: admission.MODE.COMBAT_2D6,
  cost: {
    resource: effects.RESOURCE.AETHER,
    amount: 1,
  },
  roll: {
    system: '2d6',
    stat: 'wits',
    successMin: 10,
    partialMin: 7,
  },
  outcomes: {
    common: [],
    success: [
      implemented(
        effects.EFFECT_KIND.DAMAGE,
        effects.TARGET.ENEMY,
        effects.OPERATION.APPLY,
        'syntheticAetherPulse'
      ),
    ],
    partial: [
      implemented(
        effects.EFFECT_KIND.DAMAGE,
        effects.TARGET.ENEMY,
        effects.OPERATION.APPLY,
        'syntheticAetherPulse'
      ),
    ],
    failure: [],
  },
  mutationPolicy: 'effect-resolver',
  execution: {
    adapterId: 'synthetic-test-only',
    version: '0.0.0-test',
  },
  persistence: {
    mode: 'combat-local',
    fields: [],
  },
};

assert.strictEqual(
  admission.validateCompleteContract(
    mastery.getFoundationSpellDefinition('aetherPulse'),
    syntheticPulseContract
  ),
  true
);

const syntheticAssessment = admission.assessSpell(
  'ender',
  'aetherPulse',
  syntheticPulseContract
);
assert.strictEqual(
  syntheticAssessment.status,
  admission.STATUS.COMPLETE_NOT_AUTHORIZED
);
assert.strictEqual(syntheticAssessment.contractComplete, true);
assert.strictEqual(syntheticAssessment.executionAuthorized, false);
assert.strictEqual(
  syntheticAssessment.reason,
  'design_proposal_not_runtime_authorized'
);

const invalidCost = JSON.parse(JSON.stringify(syntheticPulseContract));
invalidCost.cost.amount = null;
const invalidAssessment = admission.assessSpell(
  'ender',
  'aetherPulse',
  invalidCost
);
assert.strictEqual(invalidAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  invalidAssessment.reason,
  admission.REASON.CONTRACT_COST_INVALID
);

assert.strictEqual(
  contracts.getReadiness('notASpell').reason,
  'unknown_foundation_spell_contract'
);


assert.strictEqual(pulseEval.VERSION, '0.1.0');
assert.strictEqual(pulseEval.STATUS, 'synthetic-test-only');
assert.strictEqual(pulseEval.SPELL_ID, 'aetherPulse');
assert.strictEqual(pulseEval.SCHOOL_ID, 'aether');
assert.strictEqual(pulseEval.RESOURCE, 'aether');

function syntheticBalanceCandidate(candidateId, resourceCost, rollStat, enemyDamage, selfDamage) {
  return {
    status: pulseEval.STATUS,
    synthetic: true,
    spellId: 'aetherPulse',
    schoolId: 'aether',
    candidateId,
    resource: 'aether',
    resourceCost,
    rollStat,
    enemyDamage,
    selfDamage,
  };
}

const pulseCandidateA = syntheticBalanceCandidate(
  'TEST_ONLY_A',
  1,
  'wits',
  { success: 2, partial: 1, failure: 0 },
  { success: 0, partial: 0, failure: 1 }
);
const pulseCandidateB = syntheticBalanceCandidate(
  'TEST_ONLY_B',
  2,
  'wits',
  { success: 4, partial: 2, failure: 0 },
  { success: 0, partial: 0, failure: 0 }
);

const neutralCounts = pulseEval.getOutcomeCounts(0);
assert.deepStrictEqual(neutralCounts, {
  success: 6,
  partial: 15,
  failure: 15,
  total: 36,
});
const plusTwoCounts = pulseEval.getOutcomeCounts(2);
assert.deepStrictEqual(plusTwoCounts, {
  success: 15,
  partial: 15,
  failure: 6,
  total: 36,
});

const neutralA = pulseEval.evaluateCandidate(pulseCandidateA, 0);
assert.strictEqual(neutralA.synthetic, true);
assert.strictEqual(neutralA.designEstablished, false);
assert.strictEqual(neutralA.runtimeAuthorized, false);
assert.strictEqual(neutralA.expectedEnemyDamageNumerator, 27);
assert.strictEqual(neutralA.expectedEnemyDamage, 27 / 36);
assert.strictEqual(neutralA.expectedSelfDamageNumerator, 15);
assert.strictEqual(neutralA.expectedSelfDamage, 15 / 36);
assert.strictEqual(neutralA.expectedEnemyDamagePerAether, 27 / 36);

const plusTwoA = pulseEval.evaluateCandidate(pulseCandidateA, 2);
assert.strictEqual(plusTwoA.expectedEnemyDamageNumerator, 45);
assert.strictEqual(plusTwoA.expectedEnemyDamage, 45 / 36);
assert.strictEqual(plusTwoA.expectedSelfDamageNumerator, 6);

const neutralB = pulseEval.evaluateCandidate(pulseCandidateB, 0);
assert.strictEqual(neutralB.expectedEnemyDamageNumerator, 54);
assert.strictEqual(neutralB.expectedEnemyDamage, 54 / 36);
assert.strictEqual(neutralB.expectedEnemyDamagePerAether, 27 / 36);

const modifierSweep = pulseEval.evaluateAcrossModifiers(
  pulseCandidateA,
  [-1, 0, 1, 2, 3]
);
assert.strictEqual(modifierSweep.length, 5);
modifierSweep.forEach(result => {
  const counts = result.probabilities.counts;
  assert.strictEqual(
    counts.success + counts.partial + counts.failure,
    36,
    'every 2D6 modifier sweep must preserve the 36 exact dice outcomes'
  );
  assert.strictEqual(result.runtimeAuthorized, false);
  assert.strictEqual(result.designEstablished, false);
});

assert.throws(
  () => pulseEval.validateCandidate(Object.assign({}, pulseCandidateA, {
    synthetic: false,
  })),
  /SYNTHETIC_CANDIDATE_BOUNDARY_REQUIRED/
);
assert.throws(
  () => pulseEval.evaluateAcrossModifiers(pulseCandidateA, [0, 0]),
  /SYNTHETIC_MODIFIER_SET_DUPLICATE/
);

console.log('Aetherwake foundation spell admission gate: PASS');
console.log(JSON.stringify({
  sense: senseAssessment,
  pulse: pulseReadiness,
  syntheticPulse: syntheticAssessment,
  syntheticBalanceEvaluation: {
    neutralA,
    plusTwoA,
    neutralB,
  },
  boundary: 'structural completeness and synthetic balance evidence never override design/runtime authorization',
}, null, 2));
